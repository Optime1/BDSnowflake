DROP SCHEMA IF EXISTS dwh CASCADE;
DROP SCHEMA IF EXISTS staging CASCADE;

CREATE SCHEMA staging;
CREATE SCHEMA dwh;

CREATE TABLE staging.mock_data (
    staging_id BIGSERIAL PRIMARY KEY,
    id INTEGER,
    customer_first_name TEXT,
    customer_last_name TEXT,
    customer_age INTEGER,
    customer_email TEXT,
    customer_country TEXT,
    customer_postal_code TEXT,
    customer_pet_type TEXT,
    customer_pet_name TEXT,
    customer_pet_breed TEXT,
    seller_first_name TEXT,
    seller_last_name TEXT,
    seller_email TEXT,
    seller_country TEXT,
    seller_postal_code TEXT,
    product_name TEXT,
    product_category TEXT,
    product_price NUMERIC(12, 2),
    product_quantity INTEGER,
    sale_date TEXT,
    sale_customer_id INTEGER,
    sale_seller_id INTEGER,
    sale_product_id INTEGER,
    sale_quantity INTEGER,
    sale_total_price NUMERIC(12, 2),
    store_name TEXT,
    store_location TEXT,
    store_city TEXT,
    store_state TEXT,
    store_country TEXT,
    store_phone TEXT,
    store_email TEXT,
    pet_category TEXT,
    product_weight NUMERIC(12, 2),
    product_color TEXT,
    product_size TEXT,
    product_brand TEXT,
    product_material TEXT,
    product_description TEXT,
    product_rating NUMERIC(3, 1),
    product_reviews INTEGER,
    product_release_date TEXT,
    product_expiry_date TEXT,
    supplier_name TEXT,
    supplier_contact TEXT,
    supplier_email TEXT,
    supplier_phone TEXT,
    supplier_address TEXT,
    supplier_city TEXT,
    supplier_country TEXT
);

CREATE TABLE dwh.dim_country (
    country_id SERIAL PRIMARY KEY,
    country_name TEXT NOT NULL UNIQUE
);

CREATE TABLE dwh.dim_pet_type (
    pet_type_id SERIAL PRIMARY KEY,
    pet_type_name TEXT NOT NULL UNIQUE
);

CREATE TABLE dwh.dim_pet_category (
    pet_category_id SERIAL PRIMARY KEY,
    pet_category_name TEXT NOT NULL UNIQUE
);

CREATE TABLE dwh.dim_product_category (
    product_category_id SERIAL PRIMARY KEY,
    product_category_name TEXT NOT NULL UNIQUE
);

CREATE TABLE dwh.dim_product_brand (
    product_brand_id SERIAL PRIMARY KEY,
    product_brand_name TEXT NOT NULL UNIQUE
);

CREATE TABLE dwh.dim_product_material (
    product_material_id SERIAL PRIMARY KEY,
    product_material_name TEXT NOT NULL UNIQUE
);

CREATE TABLE dwh.dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    year SMALLINT NOT NULL,
    quarter SMALLINT NOT NULL,
    month SMALLINT NOT NULL,
    day SMALLINT NOT NULL,
    day_of_week SMALLINT NOT NULL
);

CREATE TABLE dwh.dim_customer (
    customer_id SERIAL PRIMARY KEY,
    source_customer_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    age INTEGER,
    email TEXT,
    country_id INTEGER REFERENCES dwh.dim_country(country_id),
    postal_code TEXT,
    pet_type_id INTEGER REFERENCES dwh.dim_pet_type(pet_type_id),
    pet_name TEXT,
    pet_breed TEXT
);

CREATE TABLE dwh.dim_seller (
    seller_id SERIAL PRIMARY KEY,
    source_seller_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    country_id INTEGER REFERENCES dwh.dim_country(country_id),
    postal_code TEXT
);

CREATE TABLE dwh.dim_supplier (
    supplier_id SERIAL PRIMARY KEY,
    supplier_name TEXT,
    supplier_contact TEXT,
    supplier_email TEXT,
    supplier_phone TEXT,
    supplier_address TEXT,
    supplier_city TEXT,
    country_id INTEGER REFERENCES dwh.dim_country(country_id)
);

CREATE TABLE dwh.dim_store (
    store_id SERIAL PRIMARY KEY,
    store_name TEXT,
    store_location TEXT,
    store_city TEXT,
    store_state TEXT,
    country_id INTEGER REFERENCES dwh.dim_country(country_id),
    store_phone TEXT,
    store_email TEXT
);

CREATE TABLE dwh.dim_product (
    product_id SERIAL PRIMARY KEY,
    source_product_id INTEGER,
    product_name TEXT,
    product_category_id INTEGER REFERENCES dwh.dim_product_category(product_category_id),
    pet_category_id INTEGER REFERENCES dwh.dim_pet_category(pet_category_id),
    product_brand_id INTEGER REFERENCES dwh.dim_product_brand(product_brand_id),
    product_material_id INTEGER REFERENCES dwh.dim_product_material(product_material_id),
    supplier_id INTEGER REFERENCES dwh.dim_supplier(supplier_id),
    product_weight NUMERIC(12, 2),
    product_color TEXT,
    product_size TEXT,
    product_description TEXT,
    product_rating NUMERIC(3, 1),
    product_reviews INTEGER,
    product_release_date DATE,
    product_expiry_date DATE
);

CREATE TABLE dwh.fact_sales (
    sale_fact_id BIGSERIAL PRIMARY KEY,
    staging_id BIGINT NOT NULL UNIQUE REFERENCES staging.mock_data(staging_id),
    source_sale_id INTEGER,
    sale_date_key INTEGER REFERENCES dwh.dim_date(date_key),
    customer_id INTEGER REFERENCES dwh.dim_customer(customer_id),
    seller_id INTEGER REFERENCES dwh.dim_seller(seller_id),
    product_id INTEGER REFERENCES dwh.dim_product(product_id),
    store_id INTEGER REFERENCES dwh.dim_store(store_id),
    product_unit_price NUMERIC(12, 2),
    product_available_quantity INTEGER,
    sale_quantity INTEGER,
    sale_total_price NUMERIC(12, 2)
);

CREATE INDEX idx_fact_sales_date ON dwh.fact_sales(sale_date_key);
CREATE INDEX idx_fact_sales_customer ON dwh.fact_sales(customer_id);
CREATE INDEX idx_fact_sales_product ON dwh.fact_sales(product_id);
CREATE INDEX idx_fact_sales_store ON dwh.fact_sales(store_id);
