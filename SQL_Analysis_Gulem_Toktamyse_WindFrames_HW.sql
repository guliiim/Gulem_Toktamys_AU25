-- Task 1: Annual sales analysis by channel and region
WITH base_sales AS (
    SELECT
        UPPER(co.country_region) AS country_region,
        t.calendar_year,
        UPPER(ch.channel_desc) AS channel_desc,
        SUM(s.amount_sold) AS amount_sold
    FROM sh.sales s
    INNER JOIN sh.times t
        ON s.time_id = t.time_id
    INNER JOIN sh.channels ch
        ON s.channel_id = ch.channel_id
    INNER JOIN sh.customers cu
        ON s.cust_id = cu.cust_id
    INNER JOIN sh.countries co
        ON cu.country_id = co.country_id
    WHERE t.calendar_year BETWEEN 1999 AND 2001
		AND UPPER(co.country_region) IN ('AMERICAS', 'ASIA', 'EUROPE')
    GROUP BY
        UPPER(co.country_region),
        t.calendar_year,
        UPPER(ch.channel_desc)
),
channel_percentages AS (
    SELECT
        country_region,
        calendar_year,
        channel_desc,
        amount_sold,
        ROUND(amount_sold/ SUM(amount_sold) OVER (
			PARTITION BY country_region, calendar_year) * 100,2) AS pct_by_channels
    FROM base_sales
)
SELECT
    country_region,
    calendar_year,
    channel_desc,
    amount_sold,
    pct_by_channels AS "% BY CHANNELS",
    LAG(pct_by_channels) OVER (
        PARTITION BY country_region, channel_desc
        ORDER BY calendar_year
    ) AS "% PREVIOUS PERIOD",
    ROUND(pct_by_channels - LAG(pct_by_channels) OVER (
		PARTITION BY country_region, channel_desc
        ORDER BY calendar_year),2
	) AS "% DIFF"
FROM channel_percentages
ORDER BY
    country_region,
    calendar_year,
    channel_desc;

-- Task 2: Weekly Sales Report with Cumulative Sum and Centered 3-Day Average
WITH week_sales AS (
    SELECT
        t.calendar_year,
        t.calendar_week_number,
        t.day_name,
        t.time_id,
        SUM(s.amount_sold) AS sales
    FROM sh.sales s
    JOIN sh.times t
        ON s.time_id = t.time_id
    WHERE t.calendar_year = 1999
		AND t.calendar_week_number IN (49, 50, 51)
    GROUP BY
        t.calendar_year,
        t.calendar_week_number,
        t.day_name,
        t.time_id
),
cumulative AS (
    SELECT
        *,
        SUM(sales) OVER (
            ORDER BY calendar_week_number, time_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cum_sum
    FROM week_sales
),
centered_avg AS (
    SELECT
        *,
        ROUND(
            AVG(sales) OVER (
                ORDER BY calendar_week_number, time_id
                ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING),2
			) AS centered_3_day_avg
    FROM cumulative
)
SELECT
    calendar_week_number,
    day_name,
    time_id,
    sales,
    cum_sum AS CUM_SUM,
    centered_3_day_avg AS CENTERED_3_DAY_AVG
FROM centered_avg
ORDER BY calendar_week_number, time_id;

-- Task 3
-- 1. Cumulative sales over the last 3 transactions for each customer
SELECT
    cust_id,
    time_id,
    amount_sold,
    SUM(amount_sold) OVER (
        PARTITION BY cust_id
        ORDER BY time_id
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_3_transactions
FROM sh.sales;

-- 2. Running total of sales within ±100 units of the current sale amount
SELECT
    cust_id,
    time_id,
    amount_sold,
    SUM(amount_sold) OVER (
        PARTITION BY cust_id
        ORDER BY amount_sold
        RANGE BETWEEN 100 PRECEDING AND CURRENT ROW
    ) AS sum_nearby_sales
FROM sh.sales;

-- 3. Sum of sales within 2 peer rows based on time order
WITH numbered AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY cust_id ORDER BY time_id) AS rn
    FROM sh.sales
)
SELECT
    cust_id,
    time_id,
    amount_sold,
    SUM(amount_sold) OVER (
        PARTITION BY cust_id
        ORDER BY rn
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS sum_last_3_rows_as_group
FROM numbered;