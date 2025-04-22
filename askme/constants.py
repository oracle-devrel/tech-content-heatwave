# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License (UPL), Version 1.0.

# Default documentation ingested in AskME during database setup
DEFAULT_ASKME_SCHEMA_NAME = "askme"
HEATWAVE_MANUALS_BUCKET_DIR = "documentation"
HEATWAVE_MANUALS_VECTOR_TABLE_NAME = "heatwave_manuals"

DEFAULT_EMPTY_BUCKET_DIR = "workaround_empty"
DEFAULT_EMPTY_VECTOR_TABLE_NAME = "workaround_empty_pdf"

DEFAULT_USER_UPLOAD_BUCKET_DIR = "askme_user_data"
DEFAULT_USER_DATA_PREFIX = "user_documents-"

FIND_DOC_MAX_CHUNK_TOPK = 200
ANSWER_SUMMARY_MAX_CHUNK_TOPK = 5
ANSWER_SUMMARY_MIN_SIMILARITY_SCORE = 0.0
ANSWER_MAX_CHUNK_TOPK = 3
RETRIEVAL_NUM_CHUNKS_BEFORE = 0
RETRIEVAL_NUM_CHUNK_AFTER = 1
SUMMARY_MAX_PROMPT_SIZE = 12000 # characters
ML_RAG_SEGMENT_OVERLAP = 2
DEFAULT_LLM_MODEL = "meta.llama-3.3-70b-instruct"
ANSWER_SUMMARY_PROMPT = """
    You are a data summarizer. I will provide you with a question and relevant context data. Your task is to summarize the parts of the context that are most relevant to answering the question.

    Context:
    {context}

    Question:
    {question}

    Please provide a concise summary based on the question.
"""


# OCI helper constants

CLIENT_TIMEOUT = (10,240)
FREEFORM_TAG_KEY = "demo"
FREEFORM_TAG_VALUE = "askme"
ADDITIONAL_FIELDS_LIST = ["tags"]