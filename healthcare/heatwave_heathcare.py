# Copyright (c) 2024 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License (UPL), Version 1.0.

from mysql_helper import run_mysql_queries
import streamlit as st


if __name__ == "__main__":

    gif_path= "/home/opc/hw_hc/hw.png"
    _left, mid, _right = st.columns(3)
    with mid:
        st.image(gif_path,  width=250)

    engine = st.radio("", ["HeatWave GenAI with vector store (containing medicine articles)", "HeatWave GenAI without vector store (base LLM)"])
    question = st.text_area("Enter your question:", "", key="big-textbox", height=100, help="Ask questions about healthcare: Allergies.")
    if st.button("Answer"):
        if engine=="HeatWave GenAI with vector store (containing medicine articles)":
            query=f"CALL hw_healthcare('{question}');"
            answer= run_mysql_queries(query)
            st.write(f'<h5 style="color:green;">Answer of the question using Heatwave with vector store and RAG:</h5>', unsafe_allow_html=True)
            st.write(answer[0])
            st.write("\n\n")
            with st.container():
                st.write(f'<h5 style="color:black; margin-bottom: 0; padding-bottom: 0;">References:</h5>', unsafe_allow_html=True)
                st.text_area('',answer[1], height=120)

        elif engine == "HeatWave GenAI without vector store (base LLM)":
            query=f"CALL ml_generate('{question}');"
            answer= run_mysql_queries(query)
            st.write(f'<h5 style="color:brown;">Answer of the question using Heatwave without vector store:</h5>', unsafe_allow_html=True)
            st.write(answer[0])




