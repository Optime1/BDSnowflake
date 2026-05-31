SELECT 
    'staging.mock_data' AS table_name, COUNT(*) AS row_count FROM staging.mock_data
UNION ALL SELECT 'dwh.fact_sales', COUNT(*) FROM dwh.fact_sales
UNION ALL SELECT 'dwh.dim_customer', COUNT(*) FROM dwh.dim_customer
UNION ALL SELECT 'dwh.dim_seller', COUNT(*) FROM dwh.dim_seller
UNION ALL SELECT 'dwh.dim_product', COUNT(*) FROM dwh.dim_product
UNION ALL SELECT 'dwh.dim_store', COUNT(*) FROM dwh.dim_store
UNION ALL SELECT 'dwh.dim_supplier', COUNT(*) FROM dwh.dim_supplier;

SELECT 'Orphan Customers' AS check_name, COUNT(*) AS violations
FROM dwh.fact_sales f 
WHERE f.customer_id NOT IN (SELECT customer_id FROM dwh.dim_customer WHERE customer_id IS NOT NULL)
UNION ALL
SELECT 'Orphan Products', COUNT(*)
FROM dwh.fact_sales f 
WHERE f.product_id NOT IN (SELECT product_id FROM dwh.dim_product WHERE product_id IS NOT NULL)
UNION ALL
SELECT 'Orphan Sellers', COUNT(*)
FROM dwh.fact_sales f 
WHERE f.seller_id NOT IN (SELECT seller_id FROM dwh.dim_seller WHERE seller_id IS NOT NULL);

SELECT 
    COALESCE(pc.product_category_name, 'Unknown') AS category,
    COUNT(f.sale_fact_id) AS transactions,
    ROUND(SUM(f.sale_total_price), 2) AS revenue
FROM dwh.fact_sales f
LEFT JOIN dwh.dim_product p ON p.product_id = f.product_id
LEFT JOIN dwh.dim_product_category pc ON pc.product_category_id = p.product_category_id
GROUP BY pc.product_category_id, pc.product_category_name
ORDER BY revenue DESC;

SELECT 
    d.year || '-' || LPAD(d.month::TEXT, 2, '0') AS period,
    COUNT(f.sale_fact_id) AS sales_count,
    ROUND(SUM(f.sale_total_price), 2) AS monthly_revenue,
    ROUND(AVG(f.sale_total_price), 2) AS avg_check
FROM dwh.fact_sales f
JOIN dwh.dim_date d ON d.date_key = f.sale_date_key
GROUP BY d.year, d.month
ORDER BY d.year DESC, d.month DESC
LIMIT 6;

WITH store_perf AS (
    SELECT 
        st.store_name, 
        co.country_name,
        COUNT(f.sale_fact_id) AS cnt,
        ROUND(SUM(f.sale_total_price), 2) AS rev,
        RANK() OVER(PARTITION BY co.country_id ORDER BY SUM(f.sale_total_price) DESC) as rnk
    FROM dwh.fact_sales f
    JOIN dwh.dim_store st ON st.store_id = f.store_id
    LEFT JOIN dwh.dim_country co ON co.country_id = st.country_id
    GROUP BY st.store_id, st.store_name, co.country_id, co.country_name
)
SELECT country_name, store_name, cnt, rev
FROM store_perf
WHERE rnk <= 3
ORDER BY country_name, rnk;