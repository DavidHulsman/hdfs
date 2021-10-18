#!/usr/bin/env python
# encoding: utf-8

"""Dataframe extension example."""

import pandas as pd

from hdfs import Config
from hdfs.ext.dataframe import read_dataframe, write_dataframe

# Get the default alias' client.
client = Config().get_client()

# A sample dataframe.
df = pd.DataFrame.from_records([
  {'A': 1, 'B': 2},
  {'A': 11, 'B': 23}
])

# Write dataframe to HDFS using Avro serialization.
write_dataframe(client, 'data.avro', df, overwrite=True)

# Read the Avro file back from HDFS.
_df = read_dataframe(client, 'data.avro')

# The frames match!
pd.util.testing.assert_frame_equal(df, _df)
