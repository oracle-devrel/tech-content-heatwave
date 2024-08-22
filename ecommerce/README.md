# How to run:

## sample-data

### change to the sample-data directory
    $ cd sample-data

### setup the schema
    $ mysqlsh --sql -u admin -p'<pw>' < ddl.sql

### seed the sample data
    $ mysqlsh --sql -u admin -p'<pw>' < data.sql

### define the stored procedures
    $ mysqlsh --sql -u admin -p'<pw>' < define_stored_procedures.sql

### insert the reviews
    $ msqlsh --sql -u admin
    <pw>
    mysqlsh> call insert_reviews();
    mysqlsh> \quit

## strapi

### install
    $ cd strapi
    $ npm install

### setup
    $ cp .env.example .env

Also, add the following values to your .env file

    # Database
    DATABASE_CLIENT=mysql2
    DATABASE_HOST=localhost
    DATABASE_PORT=3306
    DATABASE_NAME=<database name>
    DATABASE_USERNAME=<database username>
    DATABASE_SSL=true
    DATABASE_SSL_REJECT_UNAUTHORIZED=false

### run
    $ DATABASE_PASSWORD=<pw> npm develop

### access

http://localhost:1337

## next.js

### install
    $ cd nextjs
    $ npm install

## run
    $ npm run dev

### access

http://localhost:3000

