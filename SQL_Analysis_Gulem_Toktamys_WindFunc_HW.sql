--Task 1 Top 5 Customers per Sales Channel
--Aggregate total sales per customer per channel
WITH customer_sales AS (
    SELECT
        s.channel_id,
        s.cust_id,
        SUM(s.amount_sold) AS total_sales
    FROM sh.sales s
    GROUP BY s.channel_id, s.cust_id
),
--Calculate total sales per channel
channel_totals AS (
    SELECT
        channel_id,
        SUM(total_sales) AS channel_total_sales
    FROM customer_sales
    GROUP BY channel_id
),
--Rank customers per channel, i use LEFT JOIN and COUNT to derive rank
--count customers with higher sales
ranked AS (
    SELECT
        cs.channel_id,
        cs.cust_id,
        cs.total_sales,
        ct.channel_total_sales,
        COUNT(cs2.total_sales) + 1 AS sales_rank
    FROM customer_sales cs
    LEFT JOIN customer_sales cs2 ON cs.channel_id = cs2.channel_id
		AND cs2.total_sales > cs.total_sales
    JOIN channel_totals ct ON ct.channel_id = cs.channel_id
    GROUP BY cs.channel_id, cs.cust_id, cs.total_sales, ct.channel_total_sales
)
--Select top 5 customers per channel
SELECT
    r.channel_id,
    r.cust_id,
    ROUND(r.total_sales, 2) AS total_sales,
    ROUND((r.total_sales / r.channel_total_sales) * 100, 4)::text || '%' AS sales_percentage,
    r.sales_rank
FROM ranked r
WHERE r.sales_rank <= 5
ORDER BY r.channel_id, r.total_sales DESC;


--Task 2 Photo Category Sales in Asia in 2000
--Enable tablefunc extension for crosstab
CREATE EXTENSION IF NOT EXISTS tablefunc;

DROP TABLE IF EXISTS temp_photo_sales;
--Use temporary tables to summarize the total sales revenue for each product
CREATE TEMP TABLE temp_photo_sales AS
SELECT
    p.prod_name,
    SUM(s.amount_sold) AS total_sales
FROM sh.sales s
JOIN sh.products p ON s.prod_id = p.prod_id
JOIN sh.customers c ON s.cust_id = c.cust_id
JOIN sh.countries co ON c.country_id = co.country_id
JOIN sh.times t ON s.time_id = t.time_id
WHERE p.prod_category = 'Photo'
	AND co.country_region = 'Asia'
	AND t.calendar_year = 2000
GROUP BY p.prod_name;
--Use the crosstab function to pivot data. The Crosstab() function converts rows into columns, thus creating a pivot table.
WITH crosstab_data AS (
    SELECT *
    FROM crosstab(
        $$
        SELECT prod_name, 1 AS category, total_sales
        FROM temp_photo_sales
        ORDER BY prod_name
        $$,
        $$ SELECT 1 $$
    ) AS ct(prod_name TEXT, total_sales NUMERIC)
)
--Format results and calculate overall YEAR_SUM
SELECT
    ct.prod_name,
    ROUND(ct.total_sales, 2) AS total_sales,
    ROUND(SUM(ct.total_sales) OVER (), 2) AS year_sum
FROM crosstab_data ct
ORDER BY year_sum DESC;



--Task 3 Top 300 Customers in 1998, 1999, 2001 by Channel
-- Aggregate total sales per customer per channel per year
WITH yearly_sales AS (
	SELECT 
		s.channel_id,
		s.cust_id,
		t.calendar_year,
		SUM(s.amount_sold) AS total_sales
	FROM sh.sales s
	JOIN sh.times t ON s.time_id=t.time_id
	WHERE t.calendar_year IN (1998,1999,2001)
	GROUP BY s.channel_id, s.cust_id, t.calendar_year
),
--Rank customers per channel per year
ranked AS (
	SELECT
		ys.channel_id,
		ys.cust_id,
		ys.calendar_year,
		ys.total_sales,
		COUNT(ys2.total_sales)+1 AS sales_rank
	FROM yearly_sales ys
	LEFT JOIN yearly_sales ys2 ON ys.channel_id=ys2.channel_id
		AND ys.calendar_year=ys2.calendar_year
		AND ys2.total_sales > ys.total_sales
	GROUP BY ys.channel_id, ys.cust_id, ys.calendar_year, ys.total_sales
),
--Filter only top 300 customers per channel per year
top_customers AS (
	SELECT
		channel_id,
		cust_id,
		calendar_year,
		total_sales
	FROM ranked
	WHERE sales_rank<=300
)
--Format total sales and order
SELECT 
	tc.channel_id,
	tc.cust_id,
	tc.calendar_year,
	ROUND(tc.total_sales, 2) AS total_sales
FROM top_customers tc
ORDER BY tc.channel_id, tc.calendar_year, tc.total_sales DESC;


--Task 4 Sales by Month and Product Category in Europe and Americas
--Aggregate sales per month per product category
SELECT
	t.calendar_month_name AS month_name,
	p.prod_category AS product_category,
	ROUND(SUM(s.amount_sold),2) AS total_sales
FROM sh.sales s 
JOIN sh.times t ON s.time_id=t.time_id
JOIN sh.customers c ON s.cust_id=c.cust_id
JOIN sh.countries co ON c.country_id=co.country_id
JOIN sh.products p ON s.prod_id=p.prod_id
WHERE t.calendar_year=2000
	AND t.calendar_month_number IN (1,2,3)
	AND co.country_region IN ('Europe', 'Americas')
GROUP BY t.calendar_month_name, p.prod_category
ORDER BY t.calendar_month_name , p.prod_category;

