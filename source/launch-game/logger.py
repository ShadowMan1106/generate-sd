# -*- coding: utf-8 -*-

# Contains every tools & declaration needed for logging

# import section
import logging
import os
import sys

 # Utilities section
""" Define standard configuration for logging info """
log_filename = os.path.splitext(os.path.basename(sys.argv[0]))[0] + ".log"
logging.basicConfig(handlers=[logging.FileHandler(log_filename, 'w', 'utf-8')], format='%(asctime)s : %(levelname)s : %(message)s', datefmt='%H:%M:%S', level=logging.INFO)
