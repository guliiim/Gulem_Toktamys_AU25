--Task 1 Top 5 Customers per Sales Channel
--Aggregate sales per customer per channel
WITH channel_sales AS (
    SELECT
        s.channel_id,
        s.cust_id,
        SUM(s.amount_sold) AS total_sales
    FROM sh.sales s
    GROUP BY s.channel_id, s.cust_id
),
--Rank customers within each channel
ranked_sales AS (
    SELECT
        cs.channel_id,
        cs.cust_id,
        cs.total_sales,
        SUM(cs.total_sales) OVER (PARTITION BY cs.channel_id) AS channel_total_sales,
        RANK() OVER (PARTITION BY cs.channel_id ORDER BY cs.total_sales DESC) AS sales_rank
    FROM channel_sales cs
)
SELECT
    ch.channel_desc,
    cu.cust_last_name,
    cu.cust_first_name,
    ROUND(rs.total_sales, 2) AS total_amount,
    TO_CHAR((rs.total_sales / rs.channel_total_sales) * 100,'FM9999990.0000') || '%' AS sales_percentage
FROM ranked_sales rs
INNER JOIN sh.channels ch
	ON rs.channel_id = ch.channel_id
INNER JOIN sh.customers cu
    ON rs.cust_id = cu.cust_id
WHERE rs.sales_rank <= 5
ORDER BY
    LOWER(ch.channel_desc),
    rs.total_sales DESC;


--Task 2 Photo Category Sales in Asia in 2000
CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT
    prod_name,
    ROUND(COALESCE(Q1,0),2) AS Q1,
    ROUND(COALESCE(Q2,0),2) AS Q2,
    ROUND(COALESCE(Q3,0),2) AS Q3,
    ROUND(COALESCE(Q4,0),2) AS Q4,
    ROUND(COALESCE(Q1,0) + COALESCE(Q2,0) + COALESCE(Q3,0) + COALESCE(Q4,0), 2) AS YEAR_SUM --fixed
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
        s.cust_id,
        t.calendar_year,
        SUM(s.amount_sold) AS total_sales
    FROM sh.sales s
    INNER JOIN sh.times t ON s.time_id = t.time_id
    WHERE t.calendar_year IN (1998, 1999, 2001)
    GROUP BY
        s.cust_id,
        t.calendar_year
),
--Rank customers by total sales within each channel and year
ranked_customers AS (
    SELECT
        cust_id,
        calendar_year,
        total_sales,
        RANK() OVER (PARTITION BY calendar_year ORDER BY total_sales DESC) AS sales_rank
    FROM yearly_sales
),
--Customers who are in top 300 in all three years
qualified_customers AS (
    SELECT
        cust_id
    FROM ranked_customers
	WHERE sales_rank <= 300
    GROUP BY cust_id
    HAVING COUNT(DISTINCT calendar_year) >=1
),
--Sales per channel for qualified customers
channel_sales AS (
    SELECT
        s.channel_id,
        s.cust_id,
        SUM(s.amount_sold) AS total_sales
    FROM sh.sales s
    INNER JOIN sh.times t ON s.time_id = t.time_id
    WHERE t.calendar_year IN (1998, 1999, 2001)
      AND s.cust_id IN (SELECT cust_id FROM qualified_customers)
    GROUP BY s.channel_id, s.cust_id
)
--total sales per channel per customer
SELECT
    ch.channel_desc,
	cs.cust_id,
	cu.cust_last_name,
	cu.cust_first_name,
	ROUND(cs.total_sales,2) AS amount_sold
FROM channel_sales cs
INNER JOIN sh.channels ch
	ON cs.channel_id = ch.channel_id
INNER JOIN sh.customers cu
	ON cs.cust_id = cu.cust_id
ORDER BY LOWER(ch.channel_desc), amount_sold DESC;

--Task 4 Sales by Month and Product Category in Europe and Americas
--Aggregate sales per month, product category, and region
SELECT
    t.calendar_month_name AS month_name,
    p.prod_category AS product_category,
    ROUND(SUM(CASE WHEN co.country_region='Americas' THEN s.amount_sold ELSE 0 END),2) AS americas_sales,
	ROUND(SUM(CASE WHEN co.country_region='Europe' THEN s.amount_sold ELSE 0 END),2) AS europe_sales
FROM sh.sales s
INNER JOIN sh.times t ON s.time_id = t.time_id
INNER JOIN sh.customers c ON s.cust_id = c.cust_id
INNER JOIN sh.countries co ON c.country_id = co.country_id
INNER JOIN sh.products p ON s.prod_id = p.prod_id
WHERE t.calendar_year = 2000
	AND t.calendar_month_number IN (1, 2, 3) 
	AND co.country_region IN ('Europe', 'Americas')
GROUP BY
	t.calendar_month_number,
    t.calendar_month_name,
    p.prod_category
ORDER BY
    t.calendar_month_number,
    LOWER(product_category);