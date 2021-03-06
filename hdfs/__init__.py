#!/usr/bin/env python
# encoding: utf-8

"""HdfsCLI: API and command line interface for HDFS."""

import logging as lg

from .client import Client, InsecureClient, TokenClient
from .config import Config, NullHandler
from .util import HdfsError

__version__ = '2.5.8'
__license__ = 'MIT'


lg.getLogger(__name__).addHandler(NullHandler())
