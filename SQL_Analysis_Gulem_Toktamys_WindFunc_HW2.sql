--Task 1 Top 5 Customers per Sales Channel
--Calculate the total sales per customer for each channel
WITH channel_customer_sales AS (
    SELECT
        s.channel_id,
        s.cust_id,
        SUM(s.amount_sold) AS total_sales
    FROM sh.sales s
    GROUP BY s.channel_id, s.cust_id
),
--Rank customers and calculate total channel sales
ranked_customers AS (
    SELECT
        channel_id,
        cust_id,
        total_sales,
        SUM(total_sales) OVER (PARTITION BY channel_id) AS channel_total_sales,
        RANK() OVER (
            PARTITION BY channel_id
            ORDER BY total_sales DESC
        ) AS sales_rank
    FROM channel_customer_sales
)
--Filter out the top 5 customers and format the results.
SELECT
    channel_id,
    cust_id,
    ROUND(total_sales, 2) AS total_sales,
    TO_CHAR((total_sales / channel_total_sales) * 100, 'FM9999990.0000') || '%' AS sales_percentage
FROM ranked_customers
WHERE sales_rank <= 5
ORDER BY channel_id, sales_rank;

--Task 2 Photo Category Sales in Asia in 2000
CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT
    prod_name,
    ROUND(COALESCE(Q1,0),2) AS Q1,
    ROUND(COALESCE(Q2,0),2) AS Q2,
    ROUND(COALESCE(Q3,0),2) AS Q3,
    ROUND(COALESCE(Q4,0),2) AS Q4,
    ROUND(SUM(COALESCE(Q1,0) + COALESCE(Q2,0) + COALESCE(Q3,0) + COALESCE(Q4,0)) OVER (), 2) AS YEAR_SUM
FROM crosstab(
    $$
    SELECT 
        p.prod_name AS row_name,
        'Q' || t.calendar_quarter_number AS category,
        SUM(s.amount_sold) AS quarter_sales
    FROM sh.sales s
    INNER JOIN sh.products p ON s.prod_id = p.prod_id
    INNER JOIN sh.customers c ON s.cust_id = c.cust_id
    INNER JOIN sh.countries co ON c.country_id = co.country_id
    INNER JOIN sh.times t ON s.time_id = t.time_id
    WHERE p.prod_category = 'Photo'
		AND co.country_region = 'Asia'
		AND t.calendar_year = 2000
    GROUP BY p.prod_name, t.calendar_quarter_number
    ORDER BY p.prod_name, t.calendar_quarter_number
    $$,
    $$ VALUES ('Q1'), ('Q2'), ('Q3'), ('Q4') $$
) AS ct (
    prod_name TEXT,
    Q1 NUMERIC,
    Q2 NUMERIC,
    Q3 NUMERIC,
    Q4 NUMERIC
)
ORDER BY YEAR_SUM DESC;


--Task 3 Top 300 Customers in 1998, 1999, 2001 by Channel
--Calculate total sales per customer per channel per year
WITH yearly_sales AS (
    SELECT
        s.channel_id,
        s.cust_id,
        t.calendar_year,
        SUM(s.amount_sold) AS total_sales
    FROM sh.sales s
    INNER JOIN sh.times t ON s.time_id = t.time_id
    WHERE t.calendar_year IN (1998, 1999, 2001)
    GROUP BY
        s.channel_id,
        s.cust_id,
        t.calendar_year
),
--Rank customers by total sales within each channel and year
ranked_customers AS (
    SELECT
        channel_id,
        cust_id,
        calendar_year,
        total_sales,
        RANK() OVER (PARTITION BY channel_id, calendar_year ORDER BY total_sales DESC) AS sales_rank
    FROM yearly_sales
),
--Keep only top 300 customers per channel per year
top_300 AS (
    SELECT
        channel_id,
        cust_id,
        calendar_year
    FROM ranked_customers
    WHERE sales_rank <= 300
),
-- Customers who are in top 300 in all three years
qualified_customers AS (
    SELECT
        channel_id,
        cust_id
    FROM top_300
    GROUP BY
        channel_id,
        cust_id
    HAVING COUNT(DISTINCT calendar_year) = 3
)
--total sales per channel per customer
SELECT
    ys.channel_id,
    ys.cust_id,
    ROUND(SUM(ys.total_sales), 2) AS total_sales
FROM yearly_sales ys
INNER JOIN qualified_customers qc
	ON ys.channel_id = qc.channel_id
	AND ys.cust_id = qc.cust_id
WHERE ys.calendar_year IN (1998, 1999, 2001)
GROUP BY
    ys.channel_id,
    ys.cust_id
ORDER BY
    ys.channel_id,
    total_sales DESC;

--Task 4 Sales by Month and Product Category in Europe and Americas
--Aggregate sales per month, product category, and region
SELECT
    t.calendar_month_name AS month_name,
    p.prod_category AS product_category,
    co.country_region AS region,
    ROUND(SUM(s.amount_sold), 2) AS total_sales,
    ROUND(SUM(SUM(s.amount_sold)) OVER (PARTITION BY co.country_region),2) AS region_total_sales
FROM sh.sales s
JOIN sh.times t ON s.time_id = t.time_id
JOIN sh.customers c ON s.cust_id = c.cust_id
JOIN sh.countries co ON c.country_id = co.country_id
JOIN sh.products p ON s.prod_id = p.prod_id
--Filter for the specific months and regions
WHERE t.calendar_year = 2000
	AND t.calendar_month_number IN (1, 2, 3) 
	AND co.country_region IN ('Europe', 'Americas')
GROUP BY
	t.calendar_month_number,
    t.calendar_month_name,
    p.prod_category,
    co.country_region
ORDER BY
    region,
    t.calendar_month_number,
    product_category;
