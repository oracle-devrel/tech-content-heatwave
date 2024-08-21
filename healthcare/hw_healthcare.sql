-- Copyright (c) 2024 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License (UPL), Version 1.0.


DELIMITER //

CREATE PROCEDURE get_unique_document_names()
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE n INT;
    DECLARE doc_name VARCHAR(5000);
    DECLARE unique_doc_names TEXT DEFAULT '';
    DECLARE counter INT DEFAULT 1;

    SET n = JSON_LENGTH(@output, '$.citations');
    SET unique_doc_names = "";

    WHILE i < n DO
        SET doc_name = JSON_UNQUOTE(JSON_EXTRACT(@output, CONCAT('$.citations[', i, '].document_name')));
        IF POSITION(doc_name IN unique_doc_names) = 0 THEN
            SET unique_doc_names = CONCAT(unique_doc_names, counter, '. ', doc_name, '\n\n');
            SET counter = counter + 1;
        END IF;
        SET i = i + 1;
    END WHILE;
    SELECT TRIM(BOTH '\n' FROM unique_doc_names) AS llm_output;
END //

DELIMITER ;


DELIMITER //

CREATE PROCEDURE hw_healthcare(IN prompt VARCHAR(2048))
BEGIN

CALL sys.ML_MODEL_LOAD('mistral-7b-instruct-v1', NULL);

CALL sys.ML_RAG(prompt, @output,
'{"vector_store": ["`genai_health_db`.`health_vs3`"],
"n_citations": 5, "distance_metric": "COSINE",
"model_options": {"temperature": 0, "repeat_penalty": 1,
"top_p": 0.2, "max_tokens": 400 , "model_id": "mistral-7b-instruct-v1"}}');

SELECT JSON_UNQUOTE(JSON_EXTRACT(@output, '$.text'));
CALL get_unique_document_names();
END //

DELIMITER ;


DELIMITER //

CREATE PROCEDURE ml_generate(IN prompt VARCHAR(2048))
BEGIN

CALL sys.ML_MODEL_LOAD('mistral-7b-instruct-v1', NULL);
SELECT sys.ML_GENERATE(prompt, '{"task": "generation", "temperature": 0, "repeat_penalty": 1, "top_p": 0.2, "max_tokens": 400, "model_id": "mistral-7b-instruct-v1"}')
INTO @llm_output;
SELECT JSON_UNQUOTE(JSON_EXTRACT(@llm_output, '$.text'));
END //

DELIMITER ;
