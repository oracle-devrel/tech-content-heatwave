# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License (UPL), Version 1.0.

import logging
import sys

class CustomFormatter(logging.Formatter):
    grey = "\x1b[38;20m"
    yellow = "\x1b[33;20m"
    red = "\x1b[31;20m"
    bold_red = "\x1b[31;1m"
    reset = "\x1b[0m"
    format = "%(asctime)s - %(levelname)s - %(message)s"

    FORMATS = {
        logging.DEBUG: grey + format + reset,
        logging.INFO: grey + format + reset,
        logging.WARNING: yellow + format + reset,
        logging.ERROR: red + format + reset,
        logging.CRITICAL: bold_red + format + reset
    }

    def format(self, record):
        log_fmt = self.FORMATS.get(record.levelno)
        formatter = logging.Formatter(log_fmt)
        return formatter.format(record)

def setup_logging():
    logging.getLogger().setLevel(logging.INFO)
    logger = logging.getLogger(__name__)
    if not logger.hasHandlers():
        file = logging.FileHandler('genai_autopilot.log')
        file.setFormatter(logging.Formatter('%(asctime)s %(levelname)-8s %(message)s', datefmt='%Y-%m-%d %H:%M:%S'))
        file.setLevel(logging.INFO)
        logger.addHandler(file)
        console = logging.StreamHandler(sys.stdout)
        console.setFormatter(CustomFormatter('%(asctime)s %(levelname)-8s %(message)s', datefmt='%Y-%m-%d %H:%M:%S'))
        console.setLevel(logging.WARNING)
        logger.addHandler(console)
    return logger