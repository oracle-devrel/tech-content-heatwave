Use mysql;
DROP DATABASE estore;
CREATE DATABASE estore;
USE estore;

-- Create table for storing languages
CREATE TABLE languages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    language_code VARCHAR(10) NOT NULL UNIQUE,
    language_name VARCHAR(50) NOT NULL
);

-- Create table for storing products
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    category VARCHAR(255) NOT NULL,
    image VARCHAR(255) NOT NULL
);

CREATE TABLE productdetails (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    language_code VARCHAR(255),
    size VARCHAR(50),
    material VARCHAR(100),
    washing_instructions TEXT,
    PRIMARY KEY (product_id, language_code),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (language_code) REFERENCES languages(language_code)
);

-- Create table for storing product descriptions in multiple languages
CREATE TABLE productdescriptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    language_code VARCHAR(255),
    description VARCHAR(255),
    UNIQUE KEY(product_id, language_code),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (language_code) REFERENCES languages(language_code)
);

-- Create table for storing customers
CREATE TABLE customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT
);

-- Create table for storing orders
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    total DECIMAL(10, 2),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Create table for storing order items
CREATE TABLE orderitems (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    price DECIMAL(10, 2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Create table for storing reviews in multiple languages
CREATE TABLE reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    language_code VARCHAR(10),
    product_id INT,
    customer_id INT,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (language_code) REFERENCES languages(language_code)
);