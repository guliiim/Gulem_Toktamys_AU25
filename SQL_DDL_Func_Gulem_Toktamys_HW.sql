--Task 1. Create a view
CREATE OR REPLACE VIEW sales_revenue_by_category_qtr AS
WITH date_bounds AS (
    SELECT
        date_trunc('quarter', CURRENT_DATE)::date AS qtr_start,
        (date_trunc('quarter', CURRENT_DATE) + INTERVAL '3 month')::date AS qtr_end,
        EXTRACT(YEAR FROM CURRENT_DATE)::int AS current_year,
        EXTRACT(QUARTER FROM CURRENT_DATE)::int AS current_quarter
)
SELECT
    LOWER(c.name) AS category,
    SUM(p.amount) AS total_revenue,
    (SELECT current_year FROM date_bounds) AS year,
    (SELECT current_quarter FROM date_bounds) AS quarter
FROM payment p
JOIN rental r ON r.rental_id = p.rental_id
JOIN inventory i ON i.inventory_id = r.inventory_id
JOIN film f ON f.film_id = i.film_id
JOIN film_category fc ON fc.film_id = f.film_id
JOIN category c ON c.category_id = fc.category_id
CROSS JOIN date_bounds d
WHERE p.payment_date >= d.qtr_start
	AND p.payment_date < d.qtr_end
GROUP BY c.name
HAVING SUM(p.amount) > 0;

--Task 2. Create a query language functions
CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(
    quarter_year TEXT
)
RETURNS TABLE (
    category TEXT,
    total_revenue NUMERIC,
    year INT,
    quarter INT
)
LANGUAGE sql
AS $$
WITH input_check AS (
    SELECT
        split_part(quarter_year, '-', 1) AS yr,
        split_part(quarter_year, '-', 2) AS qtr
),
bounds AS (
    SELECT
        yr::int AS year_val,
        CAST(substring(qtr from 2) AS int) AS quarter_val
    FROM input_check
),
date_range AS (
    SELECT
        make_date(year_val, (quarter_val - 1) * 3 + 1, 1) AS qtr_start,
        make_date(year_val, (quarter_val - 1) * 3 + 1, 1) + INTERVAL '3 month' AS qtr_end,
        year_val,
        quarter_val
    FROM bounds
)
SELECT
    LOWER(c.name) AS category,
    SUM(p.amount) AS total_revenue,
    dr.year_val AS year,
    dr.quarter_val AS quarter
FROM payment p
JOIN rental r ON r.rental_id = p.rental_id
JOIN inventory i ON i.inventory_id = r.inventory_id
JOIN film f ON f.film_id = i.film_id
JOIN film_category fc ON fc.film_id = f.film_id
JOIN category c ON c.category_id = fc.category_id
CROSS JOIN date_range dr
WHERE p.payment_date >= dr.qtr_start
 	AND p.payment_date < dr.qtr_end
GROUP BY c.name, dr.year_val, dr.quarter_val
HAVING SUM(p.amount) > 0;
$$;

--Task 3. Create procedure language functions
CREATE OR REPLACE FUNCTION most_popular_films_by_countries(
    country_list TEXT[]
)
RETURNS TABLE (
    country TEXT,
    film TEXT,
    rating TEXT,
    language TEXT,
    length INTEGER,
    release_year INTEGER
)
LANGUAGE plpgsql AS
$$
BEGIN
    IF country_list IS NULL OR array_length(country_list, 1) IS NULL THEN
        RAISE EXCEPTION 'Country list cannot be NULL or empty';
    END IF;

    RETURN QUERY
    WITH country_customers AS (
        SELECT 
            co.country_id,
            co.country AS country_name,
            cu.customer_id
        FROM country co
        LEFT JOIN city ci ON ci.country_id = co.country_id
        LEFT JOIN address a ON a.city_id = ci.city_id
        LEFT JOIN customer cu ON cu.address_id = a.address_id
        WHERE LOWER(co.country) = ANY (SELECT LOWER(c) FROM unnest(country_list) AS c)
    ),
    film_rental_counts AS (
        SELECT
            cc.country_name,
            f.film_id,
            COUNT(*) AS rental_count
        FROM country_customers cc
        JOIN rental r ON r.customer_id = cc.customer_id
        JOIN inventory i ON i.inventory_id = r.inventory_id
        JOIN film f ON f.film_id = i.film_id
        GROUP BY cc.country_name, f.film_id
    ),
    most_popular AS (
        SELECT DISTINCT ON (frc.country_name)
            frc.country_name,
            frc.film_id,
            frc.rental_count
        FROM film_rental_counts frc
        ORDER BY frc.country_name, frc.rental_count DESC
    )
    SELECT
        mp.country_name AS country,
        f.title AS film,
        f.rating::text AS rating,          
        l.name::text AS language,        
        f.length::integer AS length,  
        f.release_year::integer AS release_year  
    FROM most_popular mp
    JOIN film f ON f.film_id = mp.film_id
    JOIN language l ON l.language_id = f.language_id
    ORDER BY mp.country_name;

END;
$$;

--Task 4. Create procedure language functions
CREATE OR REPLACE FUNCTION films_in_stock_by_title(
    search_title TEXT
)
RETURNS TABLE (
    row_num INTEGER,
    film_title TEXT,
    language TEXT,
    customer_name TEXT,
    rental_date TIMESTAMP  
)
LANGUAGE plpgsql AS
$$
BEGIN
    IF search_title IS NULL OR LENGTH(TRIM(search_title)) = 0 THEN
        RAISE EXCEPTION 'Search title cannot be NULL or empty';
    END IF;

    RETURN QUERY
    SELECT
        ROW_NUMBER() OVER (ORDER BY f.title)::INTEGER AS row_num,
        f.title AS film_title,
        l.name::text AS language,
        c.first_name || ' ' || c.last_name AS customer_name,
        r.rental_date::timestamp AS rental_date 
    FROM film f
    JOIN inventory i ON i.film_id = f.film_id
    LEFT JOIN rental r ON r.inventory_id = i.inventory_id
    LEFT JOIN customer c ON c.customer_id = r.customer_id
    JOIN language l ON l.language_id = f.language_id
    WHERE LOWER(f.title) LIKE LOWER(search_title)
    ORDER BY f.title;

    IF NOT FOUND THEN
        RAISE NOTICE 'No movies found matching the title: %', search_title;
    END IF;
END;
$$;

--Task 5. Create procedure language functions
CREATE OR REPLACE FUNCTION new_movie(
    p_title TEXT,
    p_release_year INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    p_language_name TEXT DEFAULT 'English' 
)
RETURNS VOID
LANGUAGE plpgsql AS
$$
DECLARE
    v_language_id INT;
    v_film_id INT;
BEGIN
    IF p_title IS NULL OR LENGTH(TRIM(p_title)) = 0 THEN
        RAISE EXCEPTION 'Movie title cannot be NULL or empty';
    END IF;

    SELECT language_id
    INTO v_language_id
    FROM language
    WHERE LOWER(name) = LOWER(p_language_name);

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Language "%" does not exist in the language table', p_language_name;
    END IF;

    SELECT COALESCE(MAX(film_id), 0) + 1
    INTO v_film_id
    FROM film;

    INSERT INTO film(
        film_id,
        title,
        release_year,
        language_id,
        rental_duration,
        rental_rate,
        replacement_cost,
        last_update
    )
    VALUES (
        v_film_id,
        p_title,
        p_release_year,
        v_language_id,
        3,
        4.99,
        19.99,
        NOW()
    );

    RAISE NOTICE 'Movie "%" inserted successfully with film_id %', p_title, v_film_id;

END;
$$;


SELECT * FROM film
WHERE title = 'Star Trek: The Next Generation';