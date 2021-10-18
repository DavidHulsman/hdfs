#!/usr/bin/env bash

# Hadoop utilities to setup a standalone HDFS cluster for integration tests.
#
# The following commands will download Hadoop locally and start a single node
# HDFS cluster:
#
# ```bash
# $ export HADOOP_HOME="$(./scripts/hadoop.sh download)"
# $ export HADOOP_CONF_DIR="$(./scripts/hadoop.sh config)"
# $ ./scripts/hadoop.sh start
# ```
#
# Later, to stop it:
#
# ```bash
# $ ./scripts/hadoop.sh stop
# ```
#

set -o nounset
set -o errexit

# Print  usage and exit.
#
# Refer to individual functions below for more information.
#
usage() {
  echo "usage: $0 (config|download|start|stop)" >&2
  exit 1
}

# Download Hadoop binary.
#
# TODO: Test against several versions? (But they are very big...)
#
hadoop-download() {
  local hadoop='hadoop-3.3.1'
  export TEMP_HADOOP_FILE="/tmp/${hadoop}.tar.gz"
  cd "$(mktemp -d 2>/dev/null || mktemp -d -t 'hadoop')"
  if [ ! -f "$TEMP_HADOOP_FILE" ]; then
    curl "https://archive.apache.org/dist/hadoop/common/${hadoop}/${hadoop}.tar.gz" --output "$TEMP_HADOOP_FILE"
  fi
  curl "https://archive.apache.org/dist/hadoop/common/${hadoop}/${hadoop}.tar.gz.sha512" --output "$TEMP_HADOOP_FILE.sha512"
  cd /tmp
  if sha512sum --check "$TEMP_HADOOP_FILE.sha512" | grep -q "OK"; then
    cd - > /dev/null # go back, but don't output
    tar -xzf "${TEMP_HADOOP_FILE}"
    echo "$(pwd)/${hadoop}"
  else
    echo "removing $TEMP_HADOOP_FILE and redownloading it"
    rm -f $TEMP_HADOOP_FILE
    hadoop-download
  fi
}

# Generate configuration and print corresponding path.
#
# The returned path is suitable to be used as environment variable
# `$HADOOP_CONF_DIR`. Note that this is necessary because proxy users are
# defined as property keys, so it's not possible to allow the current user
# otherwise.
#
hadoop-config() {
  local tpl_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../etc/hadoop"
  local conf_dir="$(mktemp -d 2>/dev/null || mktemp -d -t 'hadoop-conf')"
  for i in "$tpl_dir"/*; do
    sed -e "s/#USER#/$(whoami)/" "$i" >"${conf_dir}/$(basename "$i")"
  done
  echo "$conf_dir"
}

# Start HDFS cluster (single namenode and datanode) and HttpFS server.
#
# This requires `$HADOOP_HOME` and `$HADOOP_CONF_DIR` to be set.
#
hadoop-start() {
  rm -rf "/tmp/hadoop-$USER/dfs/name" # this is for local testing
  "${HADOOP_HOME}/bin/hdfs" namenode -format -nonInteractive || :
  "${HADOOP_HOME}/bin/hdfs" --config "$HADOOP_CONF_DIR" --daemon start namenode
  "${HADOOP_HOME}/bin/hdfs" --config "$HADOOP_CONF_DIR" --daemon start datanode
  HTTPFS_CONFIG="$HADOOP_CONF_DIR" "${HADOOP_HOME}/bin/hdfs" --daemon start httpfs
}

# Stop HDFS cluster and HttpFS server.
#
# This requires `$HADOOP_HOME` to be set.
#
hadoop-stop() {
  "${HADOOP_HOME}/bin/hdfs" --daemon stop httpfs
  "${HADOOP_HOME}/bin/hdfs" --daemon stop datanode
  "${HADOOP_HOME}/bin/hdfs" --daemon stop namenode
}

if [[ $# -ne 1 ]]; then
  usage
fi

case "$1" in
  download) hadoop-download ;;
  config) hadoop-config ;;
  start) hadoop-start ;;
  stop) hadoop-stop ;;
  *) usage ;;
esac
