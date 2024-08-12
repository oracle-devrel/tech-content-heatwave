# Copyright (c) 2024 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License (UPL), Version 1.0.

import mysql.connector
import os
import logging
import sys
import streamlit as st
USERNAME=""
PASSWORD=""
DEFAULT_HOST=""
PORT="3306"
DATABASE=""
def setup_logging():
    logging.getLogger().setLevel(logging.INFO)
    logger = logging.getLogger(__name__)
    if not logger.hasHandlers():
        file = logging.FileHandler('genai_autopilot.log')
        file.setFormatter(logging.Formatter('%(asctime)s %(levelname)-8s %(message)s', datefmt='%Y-%m-%d %H:%M:%S'))
        file.setLevel(logging.INFO)
        logger.addHandler(file)
        console = logging.StreamHandler(sys.stdout)
        console.setLevel(logging.WARNING)
        logger.addHandler(console)
    return logger

logger = setup_logging()

# Connection to the MySQL server
def mysql_connect(username=USERNAME, password=PASSWORD, host=DEFAULT_HOST, database=DATABASE, port=PORT, connection_timeout=1, repeat=5):
    for i in range(repeat):
        try:
            return mysql.connector.connect(
                user=username,
                password=password,
                host=host,
                port=port,
                autocommit=True,
                database=database,
                ssl_disabled=False,
                use_pure=True,
                connection_timeout=connection_timeout
            )
        except mysql.connector.Error as err:
            logger.warning(f"Can't connect to the backend MySQL instance ({i}): {err}")


@st.cache_data
def run_mysql_queries(query):
    output = []
    try:
        connection = mysql_connect()
        cursor = connection.cursor()
        for cursor_result in cursor.execute(query, multi=True):
            for row in cursor_result:
                if len(row) > 0:
                    output.append(row[0] if len(row) == 1 else row)
        cursor.close()
        connection.close()
        return output
    except Exception as e:
        logger.info(f"Problem with query: {query}")
        logger.warning(f"Problem with MySQL connection during execution: {str(e)}")


