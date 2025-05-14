# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License (UPL), Version 1.0.

from utils.genai_helper import create_vector_store, get_llm_list, get_default_llm_list, get_connection, question_based_KB_summarization
from constants import DEFAULT_ASKME_SCHEMA_NAME, HEATWAVE_MANUALS_VECTOR_TABLE_NAME, HEATWAVE_MANUALS_BUCKET_DIR, DEFAULT_EMPTY_VECTOR_TABLE_NAME, DEFAULT_EMPTY_BUCKET_DIR
from utils.util import setup_logging
logger = setup_logging()

rows = create_vector_store(DEFAULT_ASKME_SCHEMA_NAME, DEFAULT_EMPTY_VECTOR_TABLE_NAME, DEFAULT_EMPTY_BUCKET_DIR)
if rows is not None and len(rows) == 0:
    logger.info("Empty vector store table was successfully created")
else:
    logger.error(rows)

rows = create_vector_store(DEFAULT_ASKME_SCHEMA_NAME, HEATWAVE_MANUALS_VECTOR_TABLE_NAME, HEATWAVE_MANUALS_BUCKET_DIR)
if rows is not None and len(rows) == 0:
    logger.info("HeatWave manual vector store table was successfully created")
else:
    logger.error(rows)

# Load default LLM, to remove warmup time if in-HW LLM
askme_supported_llm_models = get_llm_list()
default_llm = get_default_llm_list()
askme_selected_llm_model = default_llm if default_llm in askme_supported_llm_models else askme_supported_llm_models[0]
conn = get_connection()
question_based_KB_summarization(conn, "What is MySQL?", [], askme_selected_llm_model, askme_supported_llm_models)