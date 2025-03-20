# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License (UPL), Version 1.0.

import mysql.connector
from utils.util import setup_logging
logger = setup_logging()
from utils.exceptions import AskMEException, BackendConnectionException , UnknownException

# Connection to the MySQL server
def mysql_connect(username, password, host, database, port, connection_timeout=1, repeat=5):
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
        except Exception as e:
            logger.exception(e)
            raise UnknownException(e)
    logger.warning("Can't connect to the backend MySQL instance")
    raise BackendConnectionException("Can't connect to the backend MySQL instance")

def run_mysql_queries(query, conn=None, params=None):
    logger.debug(f"Running query: {query} with parameters: {params}")
    output = []
    try:
        cursor = conn.cursor()
        for cursor_result in cursor.execute(query, multi=True, params=params):
            for row in cursor_result:
                if len(row) > 0:
                    output.append(row[0] if len(row) == 1 else row)
        return output
    except Exception as e:
        logger.exception(e)
