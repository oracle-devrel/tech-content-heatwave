# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License (UPL), Version 1.0.

import streamlit as st
import os
from datetime import datetime
from utils.genai_helper import (get_table_list, create_vector_store, get_connection,
                                chatbot_interaction, get_chat_history_for_current_session,
                                filename_to_mysql_table_name, get_llm_list, upload_files_oci,
                                search_similar_chunks, group_relevant_chunks_by_url,
                                askme_generate_answer, question_based_KB_summarization,
                                cleanup_vector_table_materials)
from constants import (DEFAULT_EMPTY_VECTOR_TABLE_NAME, HEATWAVE_MANUALS_VECTOR_TABLE_NAME,
                       DEFAULT_ASKME_SCHEMA_NAME, DEFAULT_USER_UPLOAD_BUCKET_DIR,
                       DEFAULT_USER_DATA_PREFIX, FIND_DOC_MAX_CHUNK_TOPK,
                       ANSWER_SUMMARY_MAX_CHUNK_TOPK, ANSWER_SUMMARY_MIN_SIMILARITY_SCORE,
                       ANSWER_MAX_CHUNK_TOPK, RETRIEVAL_NUM_CHUNK_AFTER,
                       RETRIEVAL_NUM_CHUNKS_BEFORE, ML_RAG_SEGMENT_OVERLAP, DEFAULT_LLM_MODEL)
from utils.exceptions import AskMEException, BackendConnectionException
from utils.util import setup_logging
logger = setup_logging()

BUCKET_DIR_PREFIX = os.path.join(DEFAULT_USER_UPLOAD_BUCKET_DIR, DEFAULT_USER_DATA_PREFIX)
SCHEMA_NAME = DEFAULT_ASKME_SCHEMA_NAME

# Show a banner if a backend function raised an exception
def st_handle_backend_exception_banner(return_value = None):
    def decorator(func):
        def wrapper_func(*args, **kwargs):
            try:
                return func(*args, **kwargs)
            except BackendConnectionException:
                st.warning("Generative AI service communication issue, please try again later.")
            except AskMEException:
                st.warning("Generative AI error, please contact the application support.")
            except (Exception):
                st.warning("AskME service error, please contact the application support.")
                logger.exception("AskME service error, please contact the application support.")
            return return_value
        return wrapper_func
    return decorator

def initialize_session_states():
    # Initialize general session states
    if "askme_selected_kb" not in st.session_state:
        st.session_state.askme_selected_kb = []
    if "askme_knowledge" not in st.session_state:
        st.session_state.askme_knowledge = {}
        st.session_state.askme_knowledge[SCHEMA_NAME] = get_table_list(SCHEMA_NAME)
    if "askme_supported_llm_models" not in st.session_state:
        st.session_state.askme_supported_llm_models = get_llm_list(SCHEMA_NAME)
    if "askme_selected_llm_model" not in st.session_state:
        st.session_state.askme_selected_llm_model = DEFAULT_LLM_MODEL if DEFAULT_LLM_MODEL in st.session_state.askme_supported_llm_models else st.session_state.askme_supported_llm_models[0]


    # Initialize chatbot session states
    if "askme_chatbot_show_upload_form" not in st.session_state:
        st.session_state.askme_chatbot_show_upload_form = False
    if "askme_chatbot_db_connection" not in st.session_state:
        st.session_state.askme_chatbot_db_connection = get_connection(SCHEMA_NAME)
    if "askme_chatbot_chat_history" not in st.session_state:
        st.session_state.askme_chatbot_chat_history = []
    if "askme_chatbot_uploader_key" not in st.session_state:
        st.session_state.askme_chatbot_uploader_key = "chatbot_kb_creation_uploader_key"

    # Initialize KB management tab states
    if "askme_main_uploader_key" not in st.session_state:
        st.session_state.askme_main_uploader_key = "main_kb_creation_uploader_key"

    # Initialize Find relevant doc session states
    if "askme_relevant_doc_db_connection" not in st.session_state:
        st.session_state.askme_relevant_doc_db_connection = get_connection(SCHEMA_NAME)
    if "askme_relevant_doc_min_similarity_score" not in st.session_state:
        st.session_state.askme_relevant_doc_min_similarity_score = 0.4
    if "askme_relevant_doc_topk" not in st.session_state:
        st.session_state.askme_relevant_doc_topk = 20

    # Initialize AskME session states
    if "askme_plain_answer_db_connection" not in st.session_state:
        st.session_state.askme_plain_answer_db_connection = get_connection(SCHEMA_NAME)

    # Initialize Answer Summary session states
    if "askme_answer_summary_db_connection" not in st.session_state:
        st.session_state.askme_answer_summary_db_connection = get_connection(SCHEMA_NAME)

@st_handle_backend_exception_banner()
def update_table_list():
    st.session_state.askme_knowledge[SCHEMA_NAME] = get_table_list(SCHEMA_NAME)

def create_sidebar():
    with st.sidebar:
        st.image("assets/hw.png", width=500)
        st.write()

def render_sidebar():
    with st.sidebar:
        st.title("**Knowledge Base Selection**")
        new_index_list = []
        for index in st.session_state.askme_selected_kb:
            if index in st.session_state.askme_knowledge[SCHEMA_NAME]:
                new_index_list.append(index)
        st.session_state.askme_selected_kb = new_index_list

        askme_selected_kb = st.multiselect(
            "Select Vector Tables",
            options=st.session_state.askme_knowledge[SCHEMA_NAME],
            default=st.session_state.askme_selected_kb,
            placeholder="Select a vector table",
        )

        # Update session state whenever selection changes
        if askme_selected_kb != st.session_state.askme_selected_kb:
            st.session_state.askme_selected_kb = askme_selected_kb
            st.rerun()

        st.write()
        st.write("---")
        st.title("**Settings**")
        with st.expander("Settings"):
            selected = st.selectbox(
                "LLM Models",
                st.session_state.askme_supported_llm_models,
                index=st.session_state.askme_supported_llm_models.index(st.session_state.askme_selected_llm_model)
            )
            st.session_state.askme_selected_llm_model = selected

@st_handle_backend_exception_banner()
def create_chatbot_dashboard():
    st.subheader("Heatwave Chatbot")
    # render the chat history
    with st.container():
        if len(st.session_state.askme_chatbot_chat_history)==0:
            st.write("I am AskME, ready to answer your questions based on your own data. How can I help you?")
        st.write("---")
        for item in st.session_state.askme_chatbot_chat_history:
            conversation = item[0]
            citations = item[1]
            st.markdown(f"""
            <div style='background-color:#f7f7f7; border-radius:5px; padding:8px; color:grey; font-size:14px'>
            🗣️ {conversation['user_message']}
            </div>
            """, unsafe_allow_html=True)
            st.markdown(f"""
            <div style='background-color:white; border-radius:5px; padding:8px; color:black; font-size:14px; text-align:left'>
            🤖 {conversation['chat_bot_message']}
            </div>
            """, unsafe_allow_html=True)
            if citations:
                distinct_urls = {item["id"] for item in citations}
                with st.expander("Citations", expanded=False):
                    for url in distinct_urls:
                        st.write("---")
                        st.write(f"**Link:** {url}")
            st.write("---")
    col1, col2 = st.columns([3, 50])
    with col1:
        if st.button("&#43;", key="chatbot_upload_button"):
            st.session_state.askme_chatbot_show_upload_form = True
    with col2:
        question = st.chat_input("Ask a question")

    if st.session_state.askme_chatbot_show_upload_form:
        render_vector_store_creation_chatbot()

    if question:
        response = ""
        with st.spinner('Answering the question...'):
            response, citations = chatbot_interaction(st.session_state.askme_chatbot_db_connection, question, SCHEMA_NAME, st.session_state.askme_selected_kb, st.session_state.askme_selected_llm_model, st.session_state.askme_supported_llm_models)
        st.session_state.askme_chatbot_chat_history.append ([get_chat_history_for_current_session(st.session_state.askme_chatbot_db_connection)[-1], citations])
        st.rerun()

def close_chatbot_kb_management_status():
    st.session_state.askme_chatbot_show_upload_form = False
    st.session_state.askme_chatbot_uploader_key = f"askme_chatbot_uploader_key_{datetime.now().timestamp()}"

@st_handle_backend_exception_banner()
def render_vector_store_creation_chatbot():
    with st.expander(f"Create a new vector table using your own files.", expanded=True):
        uploaded_files = st.file_uploader("Choose a file or folder", accept_multiple_files=True, key=st.session_state.askme_chatbot_uploader_key, type=['pdf', 'doc', 'docx', 'txt', 'html', 'ppt', 'pptx'])
        with st.form(f"chatbot_kb_form", clear_on_submit=False, border=False):
            default_index_name = ""
            if uploaded_files:
                if len(uploaded_files) == 1:
                    default_index_name, _ = os.path.splitext(uploaded_files[0].name)
                else:
                    default_index_name = "t_" + datetime.now().strftime("%Y%m%d_%H%M%S_%f")[:-3]
                default_index_name = filename_to_mysql_table_name(default_index_name)

            col1, col2, col3 = st.columns([3,1,1])
            with col1:
                vector_table_name = st.text_input("Vector Table Name", value=default_index_name, key=f"chatbot_table_name", placeholder="Enter the vector table name..." , max_chars=20)
            with col2:
                st.markdown("<br>", unsafe_allow_html=True)
                submit_button = st.form_submit_button("Upload")
            with col3:
                st.markdown("<br>", unsafe_allow_html=True)
                st.form_submit_button("Close", on_click=close_chatbot_kb_management_status)

            if submit_button:
                if not uploaded_files:
                    st.warning("Please choose some file(s) to upload.")
                elif len(vector_table_name) == 0:
                    st.warning("Invalid vector table name.")
                elif vector_table_name in st.session_state.askme_knowledge[SCHEMA_NAME]:
                    st.warning("This name is already used, please provide another vector table name.")
                else:
                    with st.spinner('Creating vector table...'):
                        bucket_dir_name = f"{BUCKET_DIR_PREFIX}{vector_table_name}"
                        upload_files_oci(uploaded_files, bucket_dir_name)
                        vector_creation_output = create_vector_store(SCHEMA_NAME, vector_table_name, bucket_dir_name)
                        update_table_list()
                        # the index creation query is run and no error is reported
                        if vector_table_name in st.session_state.askme_knowledge[SCHEMA_NAME]:
                            st.session_state.askme_selected_kb.append(f"{vector_table_name}")
                            st.success(f"Vector table created, you can now ask your question.")
                            logger.info(f"Vector table created, you can now ask your question.")
                        else:
                            separator = "\n\n"
                            warning_message = "Something Went Wrong." + (f" Error:{separator}{separator.join(vector_creation_output)}"
                                                                        if vector_creation_output else "")
                            st.warning(warning_message)
                            logger.warning(warning_message)
                            cleanup_vector_table_materials(SCHEMA_NAME, [vector_table_name], BUCKET_DIR_PREFIX)

def clear_main_kb_management_status():
    st.session_state.askme_main_uploader_key = f"askme_main_uploader_key_{datetime.now().timestamp()}"

@st_handle_backend_exception_banner()
def render_vector_store_management_main():
    tab1, tab2, tab3 = st.tabs(["Create Vector Table","Delete Vector Table", "Reset Knowledge Base"])
    with tab1:
        uploaded_files = st.file_uploader("Choose the file(s) to upload", accept_multiple_files=True, key=st.session_state.askme_main_uploader_key, type=['pdf', 'doc', 'docx', 'txt', 'html', 'ppt', 'pptx'])
        with st.form(f"main_kb_form", clear_on_submit=False, border=False):
            default_index_name = ""
            if uploaded_files:
                if len(uploaded_files) == 1:
                    default_index_name, _ = os.path.splitext(uploaded_files[0].name)
                else:
                    default_index_name = "t_" + datetime.now().strftime("%Y%m%d_%H%M%S_%f")[:-3]
                default_index_name = filename_to_mysql_table_name(default_index_name)

            vector_table_name = st.text_input("Vector Table Name", value=default_index_name, key=f"main_table_name", placeholder="Enter the vector table name...", max_chars=20)
            col1, col2 = st.columns([1,1])
            with col1:
                st.markdown("<br>", unsafe_allow_html=True)
                submit_button = st.form_submit_button("Upload")
            with col2:
                st.markdown("<br>", unsafe_allow_html=True)
                st.form_submit_button("Cancel", on_click=clear_main_kb_management_status)

        if submit_button:
            if not uploaded_files:
                st.warning("Please choose some file(s) to upload.")
            elif len(vector_table_name) == 0:
                st.warning("Invalid vector table name.")
            elif vector_table_name in st.session_state.askme_knowledge[SCHEMA_NAME]:
                st.warning("This name is already used, please provide another vector table name.")
            else:
                with st.spinner('Creating vector table...'):
                    bucket_dir_name = f"{BUCKET_DIR_PREFIX}{vector_table_name}"
                    upload_files_oci(uploaded_files, bucket_dir_name)
                    vector_creation_output = create_vector_store(SCHEMA_NAME, vector_table_name, bucket_dir_name)
                    update_table_list()
                    # the index creation query is run and no error is reported
                    if vector_table_name in st.session_state.askme_knowledge[SCHEMA_NAME]:
                        st.session_state.askme_selected_kb.append(f"{vector_table_name}")
                        st.success(f"Vector table {vector_table_name} was created successfully.")
                        logger.info(f"Vector table {SCHEMA_NAME}.{vector_table_name} was created successfully.")
                    else:
                        separator = "\n\n"
                        warning_message = "Something Went Wrong." + (f" Error:{separator}{separator.join(vector_creation_output)}"
                                                                    if vector_creation_output else "")
                        st.warning(warning_message)
                        logger.warning(warning_message)
                        cleanup_vector_table_materials(SCHEMA_NAME, [vector_table_name], BUCKET_DIR_PREFIX)

    with tab2:
        st.warning(f"Warning: this operation removes the vector table and its corresponding objects in the object store.")
        update_table_list()
        with st.form(f"main_kb_delete_form", clear_on_submit=False, border=False):
            # Prevent the user from removing the default vector tables from AskME
            delete_selectbox_options = None
            if st.session_state.askme_knowledge[SCHEMA_NAME]:
                delete_selectbox_options = [table_name for table_name in st.session_state.askme_knowledge[SCHEMA_NAME]
                                            if table_name not in [DEFAULT_EMPTY_VECTOR_TABLE_NAME,
                                                                HEATWAVE_MANUALS_VECTOR_TABLE_NAME]]
            table = st.selectbox(
                "**Available Vector Tables**",
                options=delete_selectbox_options,
                index=0 if delete_selectbox_options else None,
                placeholder="No vector table was found..."
            )
            submit_button = st.form_submit_button("Delete Vector Table")

        if submit_button:
            cleanup_vector_table_materials(SCHEMA_NAME, [table], BUCKET_DIR_PREFIX)
            update_table_list()
            if not table in st.session_state.askme_knowledge[SCHEMA_NAME]:
                st.success(f"Deleted successfully.")
                logger.info(f"Vector table {SCHEMA_NAME}.{table} was deleted successfully.")
            else:
                st.warning(f"Deletion failed.")
                logger.info(f"Problem with vector table {SCHEMA_NAME}.{table} deletion.")

    with tab3:
        st.warning(f"Warning: this operation removes all vector tables and their corresponding objects in the object store.")
        col1, _ = st.columns([2,4])
        deletion_flag = False
        with col1:
            if st.button("Reset Knowledge Base"):
                cleanup_vector_table_materials(SCHEMA_NAME, st.session_state.askme_knowledge[SCHEMA_NAME], BUCKET_DIR_PREFIX)
                update_table_list()
                deletion_flag = True
        if deletion_flag:
            st.success(f"The knowledge base has been reset.")

def render_citations(relevant_chunks):
    st.write("---")
    st.markdown("<div style='text-align:left'><span style='color:blue; font-size:28px; font-weight:bold'>References</span></div>", unsafe_allow_html=True)
    relevant_docs = group_relevant_chunks_by_url(relevant_chunks)
    if relevant_docs:
        for idx, doc in enumerate(relevant_docs):
            if len(doc['url']) > 0:
                url = doc['url']
                chunks = doc['chunks']
                title = chunks[0]['title']
                max_similarity_score = max(chunk['similarity_score'] for chunk in chunks)
                with st.expander(f"{title}"):
                    st.subheader(f"**Max Similarity Score:** {max_similarity_score:.2f}")
                    st.write(f"**Link:** {url} ")
                    for i, chunk in enumerate(chunks):
                        st.write(f"**Segment {i+1}** with Similarity Score of: {chunk['similarity_score']:.2f}" )
                        st.code( f"{chunk['content_chunk']}", height=100)
                        st.write("---")
    else:
        st.warning("No relevant document was found.")

@st_handle_backend_exception_banner()
def find_relevant_docs(prompt):
    relevant_doc_chunks_result = search_similar_chunks(st.session_state.askme_relevant_doc_db_connection, prompt, SCHEMA_NAME,  st.session_state.askme_selected_kb, FIND_DOC_MAX_CHUNK_TOPK, RETRIEVAL_NUM_CHUNKS_BEFORE, RETRIEVAL_NUM_CHUNK_AFTER, st.session_state.askme_relevant_doc_min_similarity_score)
    render_citations(relevant_doc_chunks_result[:st.session_state.askme_relevant_doc_topk])

@st_handle_backend_exception_banner()
def askme_answer(prompt):
    response, citations = askme_generate_answer(st.session_state.askme_plain_answer_db_connection, prompt, st.session_state.askme_selected_llm_model, st.session_state.askme_supported_llm_models, SCHEMA_NAME, st.session_state.askme_selected_kb , ANSWER_MAX_CHUNK_TOPK, ML_RAG_SEGMENT_OVERLAP)
    st.write(response)
    render_citations(citations)

@st_handle_backend_exception_banner()
def askme_answer_summary(prompt):
    relevant_doc_chunks_result = search_similar_chunks(st.session_state.askme_answer_summary_db_connection, prompt, SCHEMA_NAME,  st.session_state.askme_selected_kb, ANSWER_SUMMARY_MAX_CHUNK_TOPK, RETRIEVAL_NUM_CHUNKS_BEFORE, RETRIEVAL_NUM_CHUNK_AFTER, ANSWER_SUMMARY_MIN_SIMILARITY_SCORE)
    summary = question_based_KB_summarization(st.session_state.askme_answer_summary_db_connection, prompt, relevant_doc_chunks_result, st.session_state.askme_selected_llm_model, st.session_state.askme_supported_llm_models)
    st.write(summary)
    render_citations(relevant_doc_chunks_result)

def create_relevant_docs_dashboard():
    st.subheader("Find Relevant Documents")
    with st.form(f"relevant_docs_form", clear_on_submit=False, border=False):
        with st.expander("Search Parameters"):
            col1, col2 = st.columns([1,1.5])
            with col1:
                st.session_state.askme_relevant_doc_min_similarity_score = st.slider("Minimum Similarity Score (between 0 and 1)",
                        min_value=0.0,
                        max_value=1.0,
                        value=st.session_state.askme_relevant_doc_min_similarity_score,
                        step=0.01)
            with col2:
                st.session_state.askme_relevant_doc_topk = st.slider("Maximum Number of Doc Recommendations (between 0 and 100)",
                        min_value=1,
                        max_value=100,
                        value=st.session_state.askme_relevant_doc_topk,
                        step=1)
        prompt = st.text_area("Enter your question:", key="relevant_docs_question", height=150)
        submit_button = st.form_submit_button("Find Relevant Document")
    if submit_button:
        if prompt.strip():
            find_relevant_docs(prompt)
        else:
            st.warning("Please enter a prompt first.")

def create_askme_dashboard():
    st.subheader("Free-style Answer Generation")
    with st.form(f"free_style_answer_form", clear_on_submit=False, border=False):
        prompt = st.text_area("Enter your question:", key="askme_question", height=150)
        submit_button = st.form_submit_button("Answer Question")
    if submit_button:
        if prompt.strip():
            askme_answer(prompt)
        else:
            st.warning("Please enter a prompt before submitting!")

def create_custom_askme_dashboard():
    st.subheader("Custom AskME")

def create_answer_summary_dashboard():
    st.subheader("Summarize Docs to Answer Questions")
    with st.form(f"answer_summary_form", clear_on_submit=False, border=False):
        prompt = st.text_area("Enter your question:", key="askme_summarize_question", height=150)
        submit_button = st.form_submit_button("Summarized Answer Generation")
    if submit_button:
        if prompt.strip():
            askme_answer_summary(prompt)
        else:
            st.warning("Please enter a prompt before submitting!")

def create_summarize_dashboard():
    st.subheader("Summarize Documents")

if __name__ == "__main__":
    with open('styles/style.css') as f:
      styles = f.read()
    st.markdown(f"<style>{styles}</style>", unsafe_allow_html=True)

    st.markdown("<div style='text-align:left'><span style='color:black; font-size:32px; font-weight:bold'>HeatWave GenAI Apps</span></div>", unsafe_allow_html=True)
    st.write()

    create_sidebar()
    initialize_session_states()
    tab1, tab2, tab3, tab4, tab5 = st.tabs(["Find Relevant Docs", "Free-style Answer", "Answer Summary", "Chatbot", "$\qquad$Knowledge Base Management"])
    with tab1:
        create_relevant_docs_dashboard()
    with tab2:
        create_askme_dashboard()
    with tab3:
        create_answer_summary_dashboard()
    with tab4:
        create_chatbot_dashboard()
    with tab5:
        render_vector_store_management_main()
    render_sidebar()