TRUNCATE TABLE
    dwh.fact_sales,
    dwh.dim_product,
    dwh.dim_store,
    dwh.dim_supplier,
    dwh.dim_seller,
    dwh.dim_customer,
    dwh.dim_date,
    dwh.dim_product_material,
    dwh.dim_product_brand,
    dwh.dim_product_category,
    dwh.dim_pet_category,
    dwh.dim_pet_type,
    dwh.dim_country
RESTART IDENTITY CASCADE;

-- 1. Создание временной таблицы
DROP TABLE IF EXISTS src_clean;
CREATE TEMP TABLE src_clean AS
SELECT
    staging_id,
    id                         AS sale_id,
    sale_customer_id           AS cust_src_id,
    sale_seller_id             AS sell_src_id,
    sale_product_id            AS prod_src_id,

    NULLIF(TRIM(customer_first_name), '')  AS cust_fname,
    NULLIF(TRIM(customer_last_name), '')   AS cust_lname,
    customer_age,
    NULLIF(TRIM(customer_email), '')       AS cust_email,
    NULLIF(TRIM(customer_country), '')     AS cust_country,
    NULLIF(TRIM(customer_postal_code), '') AS cust_zip,
    NULLIF(TRIM(customer_pet_type), '')    AS pet_type,
    NULLIF(TRIM(customer_pet_name), '')    AS pet_name,
    NULLIF(TRIM(customer_pet_breed), '')   AS pet_breed,

    NULLIF(TRIM(seller_first_name), '')    AS sell_fname,
    NULLIF(TRIM(seller_last_name), '')     AS sell_lname,
    NULLIF(TRIM(seller_email), '')         AS sell_email,
    NULLIF(TRIM(seller_country), '')       AS sell_country,
    NULLIF(TRIM(seller_postal_code), '')   AS sell_zip,

    NULLIF(TRIM(product_name), '')         AS prod_name,
    NULLIF(TRIM(product_category), '')     AS prod_cat,
    product_price,
    product_quantity,

    -- ВАЖНО: Если формат даты не совпадает, sale_dt будет NULL
    CASE WHEN TRIM(sale_date) ~ '^\d{2}/\d{2}/\d{4}$'
         THEN TO_DATE(TRIM(sale_date), 'MM/DD/YYYY') END AS sale_dt,
    sale_quantity,
    sale_total_price,

    NULLIF(TRIM(store_name), '')           AS store_name,
    NULLIF(TRIM(store_location), '')       AS store_loc,
    NULLIF(TRIM(store_city), '')           AS store_city,
    NULLIF(TRIM(store_state), '')          AS store_state,
    NULLIF(TRIM(store_country), '')        AS store_country,
    NULLIF(TRIM(store_phone), '')          AS store_phone,
    NULLIF(TRIM(store_email), '')          AS store_email,

    NULLIF(TRIM(pet_category), '')         AS pet_cat,
    product_weight,
    NULLIF(TRIM(product_color), '')        AS prod_color,
    NULLIF(TRIM(product_size), '')         AS prod_size,
    NULLIF(TRIM(product_brand), '')        AS prod_brand,
    NULLIF(TRIM(product_material), '')     AS prod_material,
    NULLIF(TRIM(product_description), '')  AS prod_desc,
    product_rating,
    product_reviews,

    CASE WHEN TRIM(product_release_date) ~ '^\d{2}/\d{2}/\d{4}$'
         THEN TO_DATE(TRIM(product_release_date), 'MM/DD/YYYY') END AS prod_release_dt,
    CASE WHEN TRIM(product_expiry_date) ~ '^\d{2}/\d{2}/\d{4}$'
         THEN TO_DATE(TRIM(product_expiry_date), 'MM/DD/YYYY') END AS prod_expiry_dt,

    NULLIF(TRIM(supplier_name), '')        AS supp_name,
    NULLIF(TRIM(supplier_contact), '')     AS supp_contact,
    NULLIF(TRIM(supplier_email), '')       AS supp_email,
    NULLIF(TRIM(supplier_phone), '')       AS supp_phone,
    NULLIF(TRIM(supplier_address), '')     AS supp_addr,
    NULLIF(TRIM(supplier_city), '')        AS supp_city,
    NULLIF(TRIM(supplier_country), '')     AS supp_country
FROM staging.mock_data;

-- 2. Справочники 1-го уровня
INSERT INTO dwh.dim_country (country_name)
SELECT DISTINCT country_val FROM (
    SELECT cust_country AS country_val FROM src_clean
    UNION SELECT sell_country FROM src_clean
    UNION SELECT store_country FROM src_clean
    UNION SELECT supp_country FROM src_clean
) sub WHERE country_val IS NOT NULL;

INSERT INTO dwh.dim_pet_type (pet_type_name)
SELECT DISTINCT pet_type FROM src_clean WHERE pet_type IS NOT NULL;

INSERT INTO dwh.dim_pet_category (pet_category_name)
SELECT DISTINCT pet_cat FROM src_clean WHERE pet_cat IS NOT NULL;

INSERT INTO dwh.dim_product_category (product_category_name)
SELECT DISTINCT prod_cat FROM src_clean WHERE prod_cat IS NOT NULL;

INSERT INTO dwh.dim_product_brand (product_brand_name)
SELECT DISTINCT prod_brand FROM src_clean WHERE prod_brand IS NOT NULL;

INSERT INTO dwh.dim_product_material (product_material_name)
SELECT DISTINCT prod_material FROM src_clean WHERE prod_material IS NOT NULL;

-- 3. Измерение времени
INSERT INTO dwh.dim_date (date_key, full_date, year, quarter, month, day, day_of_week)
SELECT DISTINCT
    TO_CHAR(sale_dt, 'YYYYMMDD')::INTEGER AS date_key,
    sale_dt,
    EXTRACT(YEAR FROM sale_dt)::SMALLINT,
    EXTRACT(QUARTER FROM sale_dt)::SMALLINT,
    EXTRACT(MONTH FROM sale_dt)::SMALLINT,
    EXTRACT(DAY FROM sale_dt)::SMALLINT,
    EXTRACT(DOW FROM sale_dt)::SMALLINT
FROM src_clean
WHERE sale_dt IS NOT NULL;

-- 4. Измерения 2-го уровня
INSERT INTO dwh.dim_customer (
    source_customer_id, first_name, last_name, age, email, country_id,
    postal_code, pet_type_id, pet_name, pet_breed
)
SELECT DISTINCT
    c.cust_src_id, c.cust_fname, c.cust_lname, c.customer_age, c.cust_email,
    dc.country_id, c.cust_zip, dpt.pet_type_id, c.pet_name, c.pet_breed
FROM src_clean c
LEFT JOIN dwh.dim_country dc ON dc.country_name = c.cust_country
LEFT JOIN dwh.dim_pet_type dpt ON dpt.pet_type_name = c.pet_type
WHERE c.cust_src_id IS NOT NULL;

INSERT INTO dwh.dim_seller (
    source_seller_id, first_name, last_name, email, country_id, postal_code
)
SELECT DISTINCT
    c.sell_src_id, c.sell_fname, c.sell_lname, c.sell_email,
    dc.country_id, c.sell_zip
FROM src_clean c
LEFT JOIN dwh.dim_country dc ON dc.country_name = c.sell_country
WHERE c.sell_src_id IS NOT NULL;

INSERT INTO dwh.dim_store (
    store_name, store_location, store_city, store_state, country_id,
    store_phone, store_email
)
SELECT DISTINCT
    c.store_name, c.store_loc, c.store_city, c.store_state,
    dc.country_id, c.store_phone, c.store_email
FROM src_clean c
LEFT JOIN dwh.dim_country dc ON dc.country_name = c.store_country
WHERE c.store_name IS NOT NULL;

INSERT INTO dwh.dim_supplier (
    supplier_name, supplier_contact, supplier_email, supplier_phone,
    supplier_address, supplier_city, country_id
)
SELECT DISTINCT
    c.supp_name, c.supp_contact, c.supp_email, c.supp_phone, c.supp_addr, c.supp_city,
    dc.country_id
FROM src_clean c
LEFT JOIN dwh.dim_country dc ON dc.country_name = c.supp_country
WHERE c.supp_name IS NOT NULL;

INSERT INTO dwh.dim_product (
    source_product_id, product_name, product_category_id, pet_category_id,
    product_brand_id, product_material_id, supplier_id, product_weight,
    product_color, product_size, product_description, product_rating,
    product_reviews, product_release_date, product_expiry_date
)
SELECT DISTINCT
    c.prod_src_id, c.prod_name,
    pc.product_category_id, pcat.pet_category_id,
    pb.product_brand_id, pmat.product_material_id,
    dsup.supplier_id,
    c.product_weight, c.prod_color, c.prod_size, c.prod_desc,
    c.product_rating, c.product_reviews,
    c.prod_release_dt, c.prod_expiry_dt
FROM src_clean c
LEFT JOIN dwh.dim_product_category pc   ON pc.product_category_name = c.prod_cat
LEFT JOIN dwh.dim_pet_category pcat     ON pcat.pet_category_name = c.pet_cat
LEFT JOIN dwh.dim_product_brand pb      ON pb.product_brand_name = c.prod_brand
LEFT JOIN dwh.dim_product_material pmat ON pmat.product_material_name = c.prod_material
LEFT JOIN dwh.dim_country dc_sup        ON dc_sup.country_name = c.supp_country
LEFT JOIN dwh.dim_supplier dsup         ON dsup.supplier_name = c.supp_name
                                      AND dsup.supplier_email IS NOT DISTINCT FROM c.supp_email
                                      AND dsup.country_id IS NOT DISTINCT FROM dc_sup.country_id
WHERE c.prod_src_id IS NOT NULL;

-- 5. Загрузка таблицы фактов (ИСПРАВЛЕНО: LEFT JOIN вместо JOIN)
INSERT INTO dwh.fact_sales (
    staging_id, source_sale_id, sale_date_key, customer_id, seller_id,
    product_id, store_id, product_unit_price, product_available_quantity,
    sale_quantity, sale_total_price
)
SELECT DISTINCT ON (c.staging_id)
    c.staging_id,
    c.sale_id,
    dd.date_key,
    dc.customer_id,
    ds.seller_id,
    dp.product_id,
    dst.store_id,
    c.product_price,
    c.product_quantity,
    c.sale_quantity,
    c.sale_total_price
FROM src_clean c
-- Используем LEFT JOIN, чтобы строка не удалялась, если справочник пустой
LEFT JOIN dwh.dim_date dd        ON dd.full_date = c.sale_dt
LEFT JOIN dwh.dim_customer dc    ON dc.source_customer_id = c.cust_src_id
LEFT JOIN dwh.dim_seller ds      ON ds.source_seller_id = c.sell_src_id
LEFT JOIN dwh.dim_product dp     ON dp.source_product_id = c.prod_src_id
LEFT JOIN dwh.dim_store dst      ON dst.store_name = c.store_name
                                AND dst.store_city = c.store_city
ORDER BY c.staging_id, dst.store_id;