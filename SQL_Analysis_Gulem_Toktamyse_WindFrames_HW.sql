-- SQL_Analysis_Gulem_Toktamyse_WindFrames_HW.sql

-- Task 1: Annual sales analysis by channel and region

WITH base_sales AS (
    SELECT
        co.country_region,
        t.calendar_year,
        ch.channel_desc,
        SUM(s.amount_sold) AS amount_sold
    FROM sh.sales s
    JOIN sh.times t
        ON s.time_id = t.time_id
    JOIN sh.channels ch
        ON s.channel_id = ch.channel_id
    JOIN sh.customers cu
        ON s.cust_id = cu.cust_id
    JOIN sh.countries co
        ON cu.country_id = co.country_id
    WHERE t.calendar_year BETWEEN 1999 AND 2001
      AND co.country_region IN ('Americas', 'Asia', 'Europe')
    GROUP BY
        co.country_region,
        t.calendar_year,
        ch.channel_desc
),
channel_percentages AS (
    SELECT
        country_region,
        calendar_year,
        channel_desc,
        amount_sold,
        ROUND(
            amount_sold
            / SUM(amount_sold) OVER (
                PARTITION BY country_region, calendar_year
            ) * 100,
            2
        ) AS pct_by_channels
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
    ROUND(
        pct_by_channels
        - LAG(pct_by_channels) OVER (
            PARTITION BY country_region, channel_desc
            ORDER BY calendar_year
        ),
        2
    ) AS "% DIFF"
FROM channel_percentages
ORDER BY
    country_region,
    calendar_year,
    channel_desc;


-- Task 2: Weekly Sales Report with Cumulative Sum and Centered 3-Day Average

WITH week_sales AS (
    SELECT
        t.date_actual,
        t.calendar_year,
        t.week_of_year,
        t.day_of_week,
        SUM(s.amount_sold) AS amount_sold
    FROM sh.sales s
    JOIN sh.times t
        ON s.time_id = t.time_id
    WHERE t.calendar_year = 1999
      AND t.week_of_year IN (49, 50, 51)
    GROUP BY
        t.date_actual,
        t.calendar_year,
        t.week_of_year,
        t.day_of_week
),
cumulative AS (
    SELECT
        *,
        SUM(amount_sold) OVER (
            ORDER BY date_actual
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cum_sum
    FROM week_sales
),
centered_avg AS (
    SELECT
        *,
        ROUND((
            COALESCE(LAG(amount_sold, 1) OVER (ORDER BY date_actual), 0) +
            amount_sold +
            COALESCE(LEAD(amount_sold, 1) OVER (ORDER BY date_actual), 0)
        ) / 3.0, 2) AS centered_3_day_avg
    FROM cumulative
)
SELECT
    date_actual,
    calendar_year,
    week_of_year,
    day_of_week,
    amount_sold,
    cum_sum AS CUM_SUM,
    centered_3_day_avg AS CENTERED_3_DAY_AVG
FROM centered_avg
ORDER BY date_actual;


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
SELECT
    cust_id,
    time_id,
    amount_sold,
    SUM(amount_sold) OVER (
        PARTITION BY cust_id
        ORDER BY time_id
        GROUPS BETWEEN 2 PRECEDING AND CURRENT GROUP
    ) AS sum_3_groups
FROM sh.sales;
