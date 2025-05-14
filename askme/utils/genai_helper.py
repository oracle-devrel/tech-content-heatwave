# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License (UPL), Version 1.0.

from utils.mysql_helper import mysql_connect, run_mysql_queries
from utils.oci_helper import REGION_ID, BUCKET_NAME, IS_GENAI_REGION, get_db_credentials, get_namespace, upload_object_store_bytes, delete_object_store_folder
import json
from contextlib import closing
import re
import os
from utils.exceptions import AskMEException, BackendConnectionException , UnknownException
from constants import ANSWER_SUMMARY_PROMPT, SUMMARY_MAX_PROMPT_SIZE, DEFAULT_EMPTY_VECTOR_TABLE_NAME, DEFAULT_ASKME_SCHEMA_NAME, HEATWAVE_MANUALS_VECTOR_TABLE_NAME, DEFAULT_EMBEDDING_MODEL, DEFAULT_OCI_GENAI_MODEL, DEFAULT_IN_HW_MODEL
from utils.util import setup_logging
logger = setup_logging()

def get_connection(schema_name = DEFAULT_ASKME_SCHEMA_NAME):
    host, username, password = get_db_credentials()
    conn = mysql_connect(
        username=username,
        password=password,
        host=host,
        database=schema_name,
        port="3306",
        connection_timeout=11,
        repeat=3
    )
    return conn

def get_table_list(schema_name):
    conn = get_connection(schema_name)
    with closing(conn):
        query = """
            SELECT TABLE_NAME
            FROM performance_schema.rpd_tables rt, performance_schema.rpd_table_id rti
            WHERE rt.ID = rti.ID
              AND SCHEMA_NAME = %s
              AND TABLE_NAME != %s
              AND LOAD_STATUS = "AVAIL_RPDGSTABSTATE";
        """
        params = (schema_name, DEFAULT_EMPTY_VECTOR_TABLE_NAME)
        tables = run_mysql_queries(query, conn, params)
    return tables

def get_llm_list():
    conn = get_connection()
    with closing(conn):
        # Return all models if GenAI region, otherwise return the in-HW LLMs
        query = f"""
            SELECT model_id
            FROM sys.ML_SUPPORTED_LLMS
            WHERE JSON_CONTAINS(capabilities, '"GENERATION"')
              AND IF(%s, TRUE, provider <=> "HeatWave");
        """
        params = (IS_GENAI_REGION,)
        llms = run_mysql_queries(query, conn, params)
    return llms

def get_default_llm_list():
    if IS_GENAI_REGION:
        return DEFAULT_OCI_GENAI_MODEL
    else:
        return DEFAULT_IN_HW_MODEL

def upload_files_oci(files, bucket_dir_name):
    for file in files:
        upload_object_store_bytes(file.getvalue(), file.name, bucket_dir_name)

def filename_to_mysql_table_name(filename):
    table_name = re.sub(r'[^a-zA-Z0-9]+', '_', filename).strip('_')
    if len(table_name) > 0 and not table_name[0].isalpha():
        table_name = 't_' + table_name
    return table_name[:20]

def create_vector_store(schema_name, table_name, bucket_dir_name):
    conn = get_connection(schema_name=None)
    table_name = filename_to_mysql_table_name(table_name)
    with closing(conn):
        namespace = get_namespace()
        input_data = [
            {
                "db_name": schema_name,
                "tables": [
                    {
                        "table_name": table_name,
                        "engine_attribute": {
                            "dialect": {
                                "format": "auto_unstructured",
                                "is_strict_mode": False,
                                "embed_model_id": DEFAULT_EMBEDDING_MODEL
                            },
                            "file": [
                                {
                                    "pattern": f"{bucket_dir_name.rstrip('/')}/.*",
                                    "bucket": BUCKET_NAME,
                                    "region": REGION_ID,
                                    "namespace": namespace
                                }
                            ]
                        }
                    }
                ]
            }
        ]
        input_json = json.dumps(input_data)
        options_json = json.dumps({"mode": "normal", "output": "silent"})
        query = """
            SET @input_list = %s;
            SET @options = %s;
            CALL sys.heatwave_load(@input_list, @options);
        """
        params = (input_json, options_json)
        run_mysql_queries(query, conn, params)

        query = f"""
            SELECT DISTINCT IF(log->>'$.error' <> '', log->>'$.error', log->>'$.warn')
            FROM sys.heatwave_autopilot_report
            WHERE type IN ("warn", "error")
                AND (log->>'$.warn' IS NOT NULL OR log->>'$.error' IS NOT NULL);
        """
        response_logs = run_mysql_queries(query, conn)
    return response_logs

def askme_generate_answer(conn, question, selected_model_id, model_list, schema, selected_kb, topk, overlap):
    vector_store_tables = [f'`{schema}`.`{schema_table}`' for schema_table in selected_kb]
    vector_store_tables.append(f'`{schema}`.`{DEFAULT_EMPTY_VECTOR_TABLE_NAME}`')

    options_json = f'''
        {{
            "vector_store": [{",".join(['"' + x + '"' for x in vector_store_tables])}],
            "model_options": {{ "model_id": "{selected_model_id}" }},
            "n_citations": {topk},
            "retrieval_options": {{ "segment_overlap": {overlap} }}
        }}
    '''

    query = """
        CALL sys.ML_RAG(%s, @output, %s);
        SELECT JSON_UNQUOTE(JSON_EXTRACT(@output, '$.text')) AS answer;
    """
    params = (question, options_json)

    logger.info(f"Running the query: {query}")
    response = run_mysql_queries(query, conn, params)
    if not response:
        logger.warning(f"The selected LLM model {selected_model_id} is out dated, we try other LLM models.")
        for model in model_list:
            options_json = f'''
                {{
                    "vector_store": [{",".join(['"' + x + '"' for x in vector_store_tables])}],
                    "model_options": {{ "model_id": "{model}" }},
                    "n_citations": {topk},
                    "retrieval_options": {{ "segment_overlap": {overlap} }}
                }}
            '''
            params = (question, options_json)
            response = run_mysql_queries(query, conn, params)
            if response:
                logger.info(f"The model `{model}` was used to generate the answer.")
                break
    if response:
        response = response[0]

    query = """
    SET @chat_options = COALESCE(@output, '{{}}');
    SELECT JSON_EXTRACT(@output, '$.citations');
    """

    # prepare citations
    citations = run_mysql_queries(query, conn)
    if citations and citations[0]:
        citations = citations[0].replace("'", "\u0027")
        citations = citations.replace('\\"', '\\"')
        citations = json.loads(citations)
    else:
        citations = None

    formatted_results = []
    if citations:
        for cite in citations:
            formatted_result = {
                "index_name": None,
                "file_name": os.path.basename(cite['document_name']),
                "url": cite['document_name'],
                "chunk_id": None,
                "content_chunk": cite['segment'],
                "similarity_score": 1 - cite['distance']
            }
            formatted_results.append(formatted_result)

    return response, formatted_results

def question_based_KB_summarization(conn, prompt, relevant_doc_chunks_result, selected_model_id, model_list):
    grouped_chunks = group_relevant_chunks_by_url(relevant_doc_chunks_result)
    context = ""
    char_count = len(ANSWER_SUMMARY_PROMPT.format(question=prompt, context=context))
    for doc in grouped_chunks:
        chunks = doc['chunks']
        for chunk in chunks:
            if char_count + len(chunk['content_chunk']) <= SUMMARY_MAX_PROMPT_SIZE:
                context += chunk['content_chunk']
                char_count += len(chunk['content_chunk'])
            else:
                remaining = SUMMARY_MAX_PROMPT_SIZE - char_count
                context += chunk['content_chunk'][:remaining+1]

    prompt = ANSWER_SUMMARY_PROMPT.format(question=prompt, context=context)

    query = """
        SELECT sys.ML_GENERATE(%s, JSON_OBJECT('model_id', %s)) INTO @output;
        SELECT JSON_UNQUOTE(JSON_EXTRACT(@output, '$.text'));
    """
    params = (prompt, selected_model_id)
    response = run_mysql_queries(query, conn, params)
    if not response:
        logger.warning(f"The selected LLM model {selected_model_id} is out dated, we try other LLM models.")
        for model in model_list:
            params = (prompt, model)
            response = run_mysql_queries(query, conn, params)
            if response:
                logger.info(f"The model `{model}` was used to generate the answer.")
                break

    if response:
        response = response[0]
    return response

def delete_table_from_database(schema, table):
    conn = get_connection(schema)
    pattern = r"^[A-Za-z0-9_]{1,64}$"
    if not re.match(pattern, schema) or not re.match(pattern, table):
        logger.warning(f"Possible SQL Injection Attack {schema}.{table}")
        raise AskMEException("Invalid schema or table name")
    query = f"DROP TABLE IF EXISTS `{schema}`.`{table}`;"
    response = run_mysql_queries(query, conn)
    return response

def chatbot_interaction(conn, question, schema, selected_kb, selected_model_id, model_list):
    table_objects = [{"table_name": t, "schema_name": schema} for t in selected_kb]
    table_objects.append({"table_name": "random_table_name", "schema_name": "random_schema_name"})
    chat_options = {
        "tables": table_objects,
        "model_options": {"model_id": selected_model_id}
    }
    query = """
        SET @chat_options = %s;
        CALL sys.HEATWAVE_CHAT(%s);
    """
    params = (
        json.dumps(chat_options),
        question
    )
    response = run_mysql_queries(query, conn, params)

    if not response:
        logger.warning(f"The selected LLM model {selected_model_id} is out dated, we try other LLM models.")
        for model in model_list:
            chat_options = {
                "tables": table_objects,
                "model_options": {"model_id": model}
            }
            params = (
                json.dumps(chat_options),
                question
            )
            response = run_mysql_queries(query, conn, params)
            if response:
                logger.info(f"The model `{model}` was used to generate the answer.")
                break

    query = """
    SET @chat_options = COALESCE(@chat_options, '{{}}');
    SELECT JSON_EXTRACT(@chat_options, '$.documents');
    """

    citations = run_mysql_queries(query, conn)
    if citations and citations[0]:
        citations = citations[0].replace("'", "\u0027")
        citations = citations.replace('\\"', '\\"')
        citations = json.loads(citations)
    else:
        citations = None

    return response, citations

def get_chat_history_for_current_session(conn):
    query = """
    SET @chat_options = COALESCE(@chat_options, '{}');
    SELECT JSON_EXTRACT(@chat_options, '$.chat_history');
    """

    response = run_mysql_queries(query, conn)
    if response and response[0]:
        response = response[0].replace("'", "\u0027")
        response = response.replace('\\"', '\\"')
        response = json.loads(response)
        return response
    else:
        return []

def search_similar_chunks(conn, user_query, schema_name, table_names, topk, num_chunks_before, num_chunks_after, min_similarity_score=0.0, distance_metric='COSINE', embedding_model_id=DEFAULT_EMBEDDING_MODEL):
    """
    Searches for similar documents across multiple tables.

    Args:
    - conn: MySQL connection object.
    - user_query: User input query string.
    - schema_name: Name of the database schema.
    - table_names: List of table names to search in.
    - topk: Number of top results to return per table. And also as the final result.
    - num_chunks_before: Number of chunks before the matched chunk to include.
    - num_chunks_after: Number of chunks after the matched chunk to include.
    - min_similarity_score: Minimum similarity score required (default=0.0).
    - distance_metric: Distance metric used for similarity calculation (default='COSINE').
    - embedding_model_id: ID of the embedding model to use (default=DEFAULT_EMBEDDING_MODEL).

    Returns:
    A list of dictionaries containing information about the similar documents found.
    """

    # Load the ML model
    query = """CALL sys.ML_MODEL_LOAD(%s, NULL);"""
    params = (embedding_model_id,)
    run_mysql_queries(query, conn, params)

    # Get the input embedding
    query = f"""SELECT sys.ML_EMBED_ROW(%s, JSON_OBJECT('model_id', %s)) INTO @input_embedding;"""
    params = (user_query, embedding_model_id)
    run_mysql_queries(query, conn, params)

    # Set the group concat max length
    query = "SET group_concat_max_len = 4096;"
    run_mysql_queries(query, conn)

    all_results = []
    for table_name in table_names:
        pattern = r"^[A-Za-z0-9_]{1,64}$"
        if not re.match(pattern, schema_name) or not re.match(pattern, table_name):
            logger.warning(f"Possible SQL Injection Attack {schema_name}.{table_name}")
            raise AskMEException("Invalid schema or table name")

        query = f"""
            SELECT
                %s AS index_name,
                t.document_name,
                topk_chks.segment_number AS chunk_id,
                GROUP_CONCAT(t.segment ORDER BY t.segment_number SEPARATOR ' ') AS content_chunk,
                MAX(topk_chks.similarity_score) AS similarity_score
            FROM (
                        SELECT
                            document_id,
                            segment_number,
                            (1 - DISTANCE(segment_embedding, @input_embedding, %s)) AS similarity_score
                        FROM `{schema_name}`.`{table_name}`
                        ORDER BY similarity_score DESC, document_id, segment_number
                        LIMIT %s
                    ) topk_chks JOIN `{schema_name}`.`{table_name}` t
                    ON t.document_id = topk_chks.document_id
                    WHERE t.segment_number >= CAST(topk_chks.segment_number AS SIGNED) - %s
                    AND t.segment_number <= CAST(topk_chks.segment_number AS SIGNED) + %s
                GROUP BY t.document_id, document_name, topk_chks.segment_number, t.metadata
                HAVING similarity_score > %s
                ORDER BY similarity_score DESC, document_name, chunk_id
        """

        params = (
            table_name,
            distance_metric,
            topk,
            num_chunks_before,
            num_chunks_after,
            min_similarity_score
        )

        response = run_mysql_queries(query, conn, params)
        all_results.extend(response)

    # Apply global topk and min similarity limits
    all_results.sort(key=lambda x: x[-1], reverse=True)  # Sort by similarity score in descending order
    all_results = [result for result in all_results if result[-1] > min_similarity_score]  # Filter by min similarity score
    all_results = all_results[:topk]  # Take topk results

    # Format the output
    formatted_results = []
    for result in all_results:
        formatted_result = {
            "index_name": result[0],
            "file_name": os.path.basename(result[1]),
            "url": result[1],
            "chunk_id": result[2],
            "content_chunk": result[3],
            "similarity_score": result[4]
        }
        formatted_results.append(formatted_result)

    return formatted_results

def group_relevant_chunks_by_url(relevant_chunks):
    grouped_results = {}
    for chunk in relevant_chunks:
        url = chunk['url']
        if url not in grouped_results:
            grouped_results[url] = []
        chunk_info = {
            'title': chunk['file_name'],
            'chunk_id': chunk['chunk_id'],
            'content_chunk': chunk['content_chunk'],
            'similarity_score': chunk['similarity_score']
        }
        grouped_results[url].append(chunk_info)

    # Sort chunks within each URL by similarity score in descending order
    for url in grouped_results:
        grouped_results[url].sort(key=lambda x: x['similarity_score'], reverse=True)

    # Convert the dictionary to a list of dictionaries and sort by maximum similarity score
    sorted_grouped_results = [{'url': url, 'chunks': chunks} for url, chunks in grouped_results.items()]
    sorted_grouped_results.sort(key=lambda x: max(chunk['similarity_score'] for chunk in x['chunks']), reverse=True)

    return sorted_grouped_results

def cleanup_vector_table_materials(schema, table_list, bucket_folder_to_delete_prefix):
    conn = get_connection()
    for table in table_list:
        if table not in [DEFAULT_EMPTY_VECTOR_TABLE_NAME, HEATWAVE_MANUALS_VECTOR_TABLE_NAME]:
            response = delete_table_from_database(schema, table)
            logger.info(f"{schema}.{table} deletion: {response}")
            bucket_folder_to_delete = f"{bucket_folder_to_delete_prefix}{table}"
            delete_object_store_folder(bucket_folder_to_delete)
            logger.info(f"{bucket_folder_to_delete} deletion is done.")

