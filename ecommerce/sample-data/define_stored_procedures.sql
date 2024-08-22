-- Copyright (c) 2024, Oracle and/or its affiliates.

USE demo;

-- PROCEDURE SUMMARIZE_REVIEWS
--
-- Create a summary from product reviews and translate into the requested language
--
DROP PROCEDURE IF EXISTS SUMMARIZE_REVIEWS;
DELIMITER //
CREATE PROCEDURE SUMMARIZE_REVIEWS(
    IN product_id_requested INT,
    IN lang VARCHAR(64)
)
BEGIN
    DECLARE summary VARCHAR(1024);
    SET SESSION group_concat_max_len = 4000;

    -- Load the cohere model
    CALL sys.ML_MODEL_LOAD('cohere.command', NULL);

    -- Define the LLM prompt
    SET @prompt = GROUP_CONCAT(review_text);

    -- Define the cohere task
    SET @task = '{"task": "summarization", "temperature": 0, "extractiveness": "LOW", "format": "PARAGRAPH", "length": "AUTO", "model_id": "cohere.command"}';

    -- Call the LLM and trim the response
    SELECT JSON_UNQUOTE(JSON_EXTRACT(sys.ML_GENERATE(@prompt, @task), '$.text'))
        INTO summary
        FROM reviews
        WHERE product_id = product_id_requested
        GROUP BY product_id;

    -- If the requested language is 'en' return it directly
    IF (lang = 'en') THEN
        SELECT summary as summary;

    -- Otherwise translate into the requested language
    ELSE
        CALL TRANSLATE(summary, lang, @translated);
        SELECT @translated as summary;
    END IF;
END //
DELIMITER ;


-- PROCEDURE INSERT_REVIEWS
--
-- THIS PROCEDURE WILL GENERATE ALL REVIEWS BY CONSTRUCTING
-- A SEED TABLE OF ALL CUSTOMERS x ALL PRODUCTS.  THEN USING
-- THE GIVEN PROMPT AND RANDOMIZED RATING IT WILL GENERATE
-- A RATING AS IF IT WERE THE CUSTOMER AND FINALLY INSERT
-- THE BULK SET INTO THE REVIEWS TABLE

DROP PROCEDURE IF EXISTS INSERT_REVIEWS;
DELIMITER //
CREATE PROCEDURE INSERT_REVIEWS()
BEGIN
    SET SESSION group_concat_max_len = 100000;
    DELETE FROM reviews;
    DROP TABLE IF EXISTS review_template;

    -- Load the mistral model
    CALL sys.ML_MODEL_LOAD('mistral-7b-instruct-v1',NULL);

    -- Create the temporary table and load with rows containing the prompt for each review
    CREATE TEMPORARY TABLE review_template AS (
    SELECT
        "en" AS language_code,
        p.id as product_id,
        c.id as customer_id,
        FLOOR (1 + 5 * RAND(51)) AS rating,
        CONCAT(
            'You are ',
            c.first_name, ' ', c.last_name, '.',
            '\nWe have the following observations about them: ',
            c.personality,
            '\nYou are asked to review a product on their behalf with the following details: ',
                '\nProduct name: ', p.name, ' of size: ', pd.size,
                ', of material: ', pd.material, ', and has washing instructions like: ', pd.washing_instructions,
                '. Additionally the description of the product is as follows: ', pdg.description
            '\nWrite the review as if you rate it ',  FLOOR (1 + 5 * RAND(51)), ' out of 5 stars',
            '\nEnsure that the review length is no longer than 2 sentences.',
            '\nDo not include any product details in the review or mention the company in the review',
            '\nand do not reveal that you are writing the review on their behalf.'
        ) as prompt
    FROM
        (
            SELECT DISTINCT oi.product_id as product_id, c.id as customer_id
            FROM customers c
            INNER JOIN orders o ON c.id = o.customer_id
            INNER JOIN orderitems oi ON o.id = oi.order_id
            INNER JOIN products p ON oi.product_id = p.id
            INNER JOIN productdetails pd ON p.id = pd.product_id
            INNER JOIN productdescriptions pdg ON p.id = pdg.product_id
        ) AS customer_product_pair,
        customers c, products p, productdetails pd, productdescriptions pdg
    WHERE
        c.id = customer_product_pair.customer_id AND
        p.id = customer_product_pair.product_id AND
        pd.product_id = customer_product_pair.product_id AND
        pdg.product_id = customer_product_pair.product_id
    ORDER BY
        p.id, c.id
    );

    -- SECOND:
    --
    -- FROM THE MATERIALIZED VIEW FOR EVERY ROW GENERATE A REVIEW AND INSERT THE
    -- ALL DETAILS INCLUDING THE RATING AND GENERATED REVIEW TEXT INTO THE REVIEWS TABLE

    INSERT INTO reviews (language_code, product_id, customer_id, rating, review_text)
    SELECT
        language_code,
        product_id,
        customer_id,
        rating,
        JSON_UNQUOTE(JSON_EXTRACT(
            sys.ML_GENERATE(
                review,
                '{"task": "generation", "temperature": 0, "repeat_penalty": 1, "top_p": 0.2, "max_tokens": 1000}'
            ),
            '$.text'
        )) AS prompt
        FROM
            review_template;
END //
DELIMITER ;

-- PROCEDURE TRANSLATE_DESCRIPTIONS
--
-- Generate all product descriptions starting with the
-- english product descriptions and call translate on each
--
DROP PROCEDURE IF EXISTS TRANSLATE_DESCRIPTIONS;
DELIMITER //
CREATE PROCEDURE TRANSLATE_DESCRIPTIONS()
BEGIN
    DECLARE c VARCHAR(64);
    DECLARE d VARCHAR(104);

    -- Load the LLM model
    CALL sys.ML_MODEL_LOAD('mistral-7b-instruct-v1', NULL);

    -- Remove any prior translations
    DELETE from productdescriptions where language_code <> 'en';

    -- Select all descriptions into a materialized view
    DROP TABLE IF EXISTS description_translations;
    CREATE TEMPORARY TABLE description_translations AS
        SELECT DISTINCT p.id as product_id, l.language_code, pdg.description
        FROM languages l, products p
        LEFT JOIN productdescriptions pdg ON p.id = pdg.product_id;


    -- Remove all the product descriptions so we can re-insert
    DELETE from productdescriptions;
    ALTER TABLE productdescriptions AUTO_INCREMENT = 1;

    -- Translate all the rows with the LLM and insert back into original table
    INSERT INTO productdescriptions (product_id, language_code, description)
    SELECT
        product_id,
        language_code,
        TRANSLATE_PROCESS_JSON(sys.ML_GENERATE(
            TRANSLATE_PROMPT(description, language_code),
            @TRANSLATE_TASK
        )) AS description
    FROM description_translations;

END //
DELIMITER ;

-- PROCEDURE TRANSLATE
--
-- Translate the input text into the requested language
--
DROP PROCEDURE IF EXISTS TRANSLATE;
DELIMITER //
CREATE PROCEDURE TRANSLATE(
    IN in_text VARCHAR(1024),
    IN lang VARCHAR(64),
    OUT translated VARCHAR(1024)
)
BEGIN
    -- Load the mistral model
    CALL sys.ML_MODEL_LOAD('mistral-7b-instruct-v1', NULL);

    -- Invoke the LLM
    SELECT TRANSLATE_PROCESS_JSON(sys.ML_GENERATE(
        TRANSLATE_PROMPT(in_text, lang),
        @TRANSLATE_TASK
    )) INTO translated;
END //
DELIMITER ;

-- FUNCTION TRANSLATE_PROMPT
--
-- Defines the prompt used for translation
--
DROP FUNCTION IF EXISTS TRANSLATE_PROMPT;
CREATE FUNCTION TRANSLATE_PROMPT(in_text VARCHAR(1024), lang VARCHAR(64))
RETURNS VARCHAR(1024)
RETURN CONCAT(
    'Translate the Original Text to ', lang, '.',
    'The translation needs to be formal and meaningful,',
    ' it needs to have the right grammar and spelling.',
    '\n  - Original Text: "', in_text, '"',
    '\n  - ', lang, ' Translation:'
);

-- TRANSLATE TASK
--
SET @TRANSLATE_TASK = '{"task": "generation", "temperature": 0, "repeat_penalty": 1, "top_k": 0, "max_tokens": 800, "model_id": "mistral-7b-instruct-v1"}';

-- FUNCTION TRANSLATE_PROCESS_JSON
--
-- Post processes the LLM output
--
DROP FUNCTION IF EXISTS TRANSLATE_PROCESS_JSON;
CREATE FUNCTION TRANSLATE_PROCESS_JSON(in_text VARCHAR(1024))
RETURNS VARCHAR(1024)
RETURN REGEXP_REPLACE(
    REGEXP_REPLACE(
        JSON_UNQUOTE(JSON_EXTRACT(
            in_text,
            '$.text'
        )),
        '(^[^"]+")|(^\\s+)',
        ''
    ),
    '"$',
    ''
);


-- PROCEDURE TRANSLATE_DESCRIPTION
--
-- Translate a single description
--
DROP PROCEDURE IF EXISTS TRANSLATE_DESCRIPTION;
DELIMITER //
CREATE PROCEDURE TRANSLATE_DESCRIPTION(
    IN id_requested INT,
    IN lang VARCHAR(64)
)
BEGIN
    -- FOR A GIVEN DESCRIPTION RECORD TRANSLATE IT
    -- INTO THE REQUESTED LANG

    DECLARE c VARCHAR(64);
    DECLARE d VARCHAR(1024);

    SELECT description
    INTO d
    FROM productdescriptions
    WHERE id = id_requested;

    IF (lang = 'en') THEN
        SELECT d as description;
    ELSE
        CALL TRANSLATE(d, lang, @descr);
        SELECT @descr as description;
    END IF;
END //
DELIMITER ;


DROP PROCEDURE IF EXISTS BLOG;
DELIMITER //
CREATE PROCEDURE BLOG()
BEGIN

    CALL sys.ML_MODEL_LOAD('mistral-7b-instruct-v1', NULL);
    SELECT sys.ML_GENERATE(CONCAT(
        'Prepare a blog post about a technical demo.  The demo showcases the HeatWave GenAI capability that gives the HeatWave service the ability to use an LLM model seamlessly from the database.',
        ' In the demo, we created an e-commerce site.  The site consists of products, customers, and product reviews.  We used the HeatWave GenAI feature to',
        ' prepare natural language translations of the product descriptions and to automatically generate a product review summary of all reviews for a given product and translate the summary into the target language for the page.',
        ' \n\nIn the blog please highlight the seamless nature of the HeatWave GenAI capability because it is integrated into the database giving developers an easy way to integrate LLM models with their unstructured data.'
    ), '{"task": "generation", "temperature": 0, "repeat_penalty": 1, "top_k": 0, "max_tokens": 8000, "model_id": "mistral-7b-instruct-v1"}');
END //
DELIMITER ;