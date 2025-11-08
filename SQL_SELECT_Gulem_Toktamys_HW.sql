--Part 1: Write SQL queries to retrieve the following data. 
-- TASK 1: Retrieve all Animation movies released between 2017 and 2019 (inclusive)
-- JOIN solution
SELECT 
    f.title,
    f.release_year,
    f.rental_rate
FROM public.film f
INNER JOIN public.film_category fc ON f.film_id = fc.film_id
INNER JOIN public.category c ON fc.category_id = c.category_id
WHERE UPPER(c.name) = 'ANIMATION'
	AND f.release_year BETWEEN 2017 AND 2019
	AND f.rental_rate > 1
ORDER BY f.title ASC;
--Advantages:
--Faster, less memory overhead
--Disadvantages:
--Lower readability, all conditions are in one block  

-- CTE solution
WITH animation_films AS (
    SELECT 
        f.film_id,
        f.title,
        f.release_year,
        f.rental_rate,
        c.name AS category_name
    FROM public.film f
    INNER JOIN public.film_category fc ON f.film_id = fc.film_id
    INNER JOIN public.category c ON fc.category_id = c.category_id
    WHERE UPPER(c.name) = 'ANIMATION'
)
SELECT 
    title,
    release_year,
    rental_rate
FROM animation_films
WHERE release_year BETWEEN 2017 AND 2019
	AND rental_rate > 1
ORDER BY title ASC;
--Advantages:
--Improved readability, easy to separate logic into stages. and easier maintenance and debugging  
--Disadvantages:
--higher resource usage and not ideal for simple queries

--Subquery
SELECT 
    title,
    release_year,
    rental_rate
FROM public.film
WHERE film_id IN (
    SELECT fc.film_id
    FROM public.film_category fc
    INNER JOIN public.category c ON fc.category_id = c.category_id
    WHERE UPPER(c.name) = 'ANIMATION'
)
AND release_year BETWEEN 2017 AND 2019
AND rental_rate > 1
ORDER BY title ASC;
--Advantages:
--No need for joins in the main SELECT
--Disadvantages:
--Harder to optimize than JOINs


-- TASK 2: Calculate revenue earned by each rental store after March 2017
-- JOIN solution
SELECT 
    COALESCE(a.address, '') || ' ' || COALESCE(a.address2, '') AS full_address,
    SUM(p.amount) AS revenue
FROM public.payment p
INNER JOIN public.rental r ON p.rental_id = r.rental_id
INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
INNER JOIN public.store s ON i.store_id = s.store_id
INNER JOIN public.address a ON s.address_id = a.address_id
WHERE p.payment_date >= '2017-04-01'
GROUP BY a.address_id
ORDER BY revenue DESC;
--Advantages:
--faster, query planner can optimize join and group steps together  
--Disadvantages:
--harder to read, less modular for reuse in other queries

-- CTE solution
WITH store_revenue AS ( 
    SELECT 
        s.store_id,
        COALESCE(a.address, '') || ' ' || COALESCE(a.address2, '') AS full_address,
        SUM(p.amount) AS revenue
    FROM public.payment p
    INNER JOIN public.rental r ON p.rental_id = r.rental_id
    INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN public.store s ON i.store_id = s.store_id
    INNER JOIN public.address a ON s.address_id = a.address_id
    WHERE p.payment_date >= '2017-04-01'
    GROUP BY s.store_id, a.address_id
)
SELECT full_address, revenue
FROM store_revenue
ORDER BY revenue DESC;
--Advantages:
--Reusable temporary result set  
--Disadvantages:
--CTE can be slower on very large tables, and higher memory usage  

--Subquery
SELECT 
    (SELECT COALESCE(a.address, '') || ' ' || COALESCE(a.address2, '') 
     FROM public.address a 
     INNER JOIN public.store s ON a.address_id = s.address_id 
     WHERE s.store_id = i.store_id) AS full_address,
    SUM(p.amount) AS revenue
FROM public.payment p
INNER JOIN public.rental r ON p.rental_id = r.rental_id
INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
WHERE p.payment_date >= '2017-04-01'
GROUP BY i.store_id
ORDER BY revenue DESC;
--Advantages:
--Self contained logic, readable.
--Disadvantages:
--Subquery executes for each inventory row more slowly.

-- TASK 3: Show top-5 actors by number of movies they participated in since 2015
-- JOIN solution
SELECT 
    a.first_name,
    a.last_name,
    COUNT(f.film_id) AS number_of_movies
FROM public.actor a
INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
INNER JOIN public.film f ON fa.film_id = f.film_id
WHERE f.release_year >= 2015
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY number_of_movies DESC
LIMIT 5;
--Advantages:
--Less temporary memory used , Simpler for small, straightforward aggregations  
--Disadvantages:
--Less readable for complex logic , harder to reuse 

-- CTE solution
WITH actor_movies AS (
    SELECT 
        a.actor_id,
        a.first_name,
        a.last_name,
        COUNT(f.film_id) AS number_of_movies
    FROM public.actor a
    INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
    INNER JOIN public.film f ON fa.film_id = f.film_id
    WHERE f.release_year >= 2015
    GROUP BY a.actor_id, a.first_name, a.last_name
)
SELECT first_name, last_name, number_of_movies
FROM actor_movies
ORDER BY number_of_movies DESC
LIMIT 5;
--Advantages:
--Clear separation of logic, easy to debug and extend
--Disadvantages:
--Overkill for simple aggregations

--Subquery
SELECT 
    first_name,
    last_name,
    (SELECT COUNT(f.film_id)
     FROM public.film_actor fa
     INNER JOIN public.film f ON fa.film_id = f.film_id
     WHERE fa.actor_id = a.actor_id AND f.release_year >= 2015) AS number_of_movies
FROM public.actor a
ORDER BY number_of_movies DESC
LIMIT 5;
--Advantages:
--No need for GROUP BY in outer query
--Disadvantages:
--Subquery runs per actor, can be slow for large actor tables


-- TASK 4: Count number of Drama, Travel, and Documentary movies per release year
-- JOIN solution
SELECT 
    f.release_year,
    COUNT(*) FILTER (WHERE UPPER(c.name) = 'DRAMA') AS number_of_drama_movies,
    COUNT(*) FILTER (WHERE UPPER(c.name) = 'TRAVEL') AS number_of_travel_movies,
    COUNT(*) FILTER (WHERE UPPER(c.name) = 'DOCUMENTARY') AS number_of_documentary_movies
FROM public.film f
INNER JOIN public.film_category fc ON f.film_id = fc.film_id
INNER JOIN public.category c ON fc.category_id = c.category_id
WHERE UPPER(c.name) IN ('DRAMA', 'TRAVEL', 'DOCUMENTARY')
GROUP BY f.release_year
ORDER BY f.release_year DESC;
--Advantages:
--good for straightforward grouping and counting  
--Disadvantages:
--Debugging complex category filters can be more difficult

-- CTE solution
WITH genre_counts AS (
    SELECT 
        f.release_year,
        UPPER(c.name) AS genre,
        COUNT(*) AS genre_count
    FROM public.film f
    JOIN public.film_category fc ON f.film_id = fc.film_id
    JOIN public.category c ON fc.category_id = c.category_id
    WHERE UPPER(c.name) IN ('DRAMA', 'TRAVEL', 'DOCUMENTARY')
    GROUP BY f.release_year, UPPER(c.name)
)
SELECT
    release_year,
    COALESCE(MAX(CASE WHEN genre = 'DRAMA' THEN genre_count END), 0)   AS number_of_drama_movies,
    COALESCE(MAX(CASE WHEN genre = 'TRAVEL' THEN genre_count END), 0)  AS number_of_travel_movies,
    COALESCE(MAX(CASE WHEN genre = 'DOCUMENTARY' THEN genre_count END), 0) AS number_of_documentary_movies
FROM genre_counts
GROUP BY release_year
ORDER BY release_year DESC;
--Advantages:
--Readable, logic separated into manageable parts, and easy to maintain and expand
--Disadvantages:
--performance overhead compared to direct JOINs 

--Subquery
SELECT 
    ry.release_year,
    (SELECT COUNT(*) 
     FROM public.film f
     JOIN public.film_category fc ON f.film_id = fc.film_id
     JOIN public.category c ON fc.category_id = c.category_id
     WHERE f.release_year = ry.release_year
       AND UPPER(c.name) = 'DRAMA') AS number_of_drama_movies,
    (SELECT COUNT(*) 
     FROM public.film f
     JOIN public.film_category fc ON f.film_id = fc.film_id
     JOIN public.category c ON fc.category_id = c.category_id
     WHERE f.release_year = ry.release_year
       AND UPPER(c.name) = 'TRAVEL') AS number_of_travel_movies,
    (SELECT COUNT(*) 
     FROM public.film f
     JOIN public.film_category fc ON f.film_id = fc.film_id
     JOIN public.category c ON fc.category_id = c.category_id
     WHERE f.release_year = ry.release_year
       AND UPPER(c.name) = 'DOCUMENTARY') AS number_of_documentary_movies
FROM (
    SELECT DISTINCT release_year
    FROM public.film
) ry
ORDER BY ry.release_year DESC;
--Advantages:
--Easy to modify individual genre subqueries.
--Disadvantages:
--Multiple subqueries executed per year are slower.


--Part 2: Solve the following problems using SQL
-- TASK 1: Show top-3 employees who generated the most revenue in 2017
-- JOIN solution
SELECT 
    s.first_name,
    s.last_name,
    ls.store_id,
    tr.revenue
FROM public.staff s
JOIN (
    SELECT 
        staff_id,
        SUM(amount) AS revenue
    FROM public.payment
    WHERE payment_date >= '2017-01-01'
		AND payment_date < '2018-01-01'
    GROUP BY staff_id
) AS tr ON s.staff_id = tr.staff_id
JOIN (
    SELECT DISTINCT ON (p.staff_id)
        p.staff_id,
        i.store_id
    FROM public.payment p
    JOIN public.rental r ON p.rental_id = r.rental_id
    JOIN public.inventory i ON r.inventory_id = i.inventory_id
    WHERE p.payment_date >= '2017-01-01'
		AND p.payment_date < '2018-01-01'
    ORDER BY p.staff_id, p.payment_date DESC
) AS ls ON s.staff_id = ls.staff_id
ORDER BY tr.revenue DESC
LIMIT 3;
--Advantages:
--Simpler and faster for small datasets. Uses fewer resources.
--Disadvantages:
--Less readable when more conditions or joins are added.

-- CTE solution
WITH total_revenue AS (
    SELECT 
        p.staff_id,
        SUM(p.amount) AS total_revenue
    FROM public.payment p
    WHERE p.payment_date >= '2017-01-01'
		AND p.payment_date < '2018-01-01'
    GROUP BY p.staff_id
),
last_store AS (
    SELECT DISTINCT ON (p.staff_id)
        p.staff_id,
        i.store_id
    FROM public.payment p
    JOIN public.rental r ON p.rental_id = r.rental_id
    JOIN public.inventory i ON r.inventory_id = i.inventory_id
    WHERE p.payment_date >= '2017-01-01'
		AND p.payment_date < '2018-01-01'
    ORDER BY p.staff_id, p.payment_date DESC
)
SELECT 
    s.first_name,
    s.last_name,
    ls.store_id,
    tr.total_revenue AS revenue
FROM public.staff s
JOIN total_revenue tr ON s.staff_id = tr.staff_id
JOIN last_store ls ON s.staff_id = ls.staff_id
ORDER BY tr.total_revenue DESC
LIMIT 3;
--Advantages:
--Easier to debug or reuse the filtered subset. Good for complex queries with multiple filters or joins.
--Disadvantages:
--Consumes more memory, not necessary for small or simple queries.

--Subquery
SELECT 
    s.first_name,
    s.last_name,
    (
        SELECT i.store_id
        FROM public.payment p
        JOIN public.rental r ON p.rental_id = r.rental_id
        JOIN public.inventory i ON r.inventory_id = i.inventory_id
        WHERE p.staff_id = s.staff_id
          AND p.payment_date >= '2017-01-01'
          AND p.payment_date < '2018-01-01'
        ORDER BY p.payment_date DESC
        LIMIT 1
    ) AS store_id,
    (
        SELECT SUM(p.amount)
        FROM public.payment p
        WHERE p.staff_id = s.staff_id
          AND p.payment_date >= '2017-01-01'
          AND p.payment_date < '2018-01-01'
    ) AS revenue
FROM public.staff s
WHERE s.staff_id IN (
    SELECT staff_id
    FROM public.payment
    WHERE payment_date >= '2017-01-01'
        AND payment_date < '2018-01-01'
)
ORDER BY revenue DESC
LIMIT 3;
--Advantages:
--Easy to read in plain SQL, no grouping or CTEs
--Disadvantages:
--Least efficient, runs two subqueries per employee


-- TASK 2: Show top-5 movies by number of rentals
-- JOIN solution
SELECT 
    f.title,
    COUNT(r.rental_id) AS rental_count,
    CASE f.rating
        WHEN 'G' THEN '0-6'
        WHEN 'PG' THEN '7-12'
        WHEN 'PG-13' THEN '13-16'
        WHEN 'R' THEN '17-20'
        WHEN 'NC-17' THEN '21+'
        ELSE 'Unknown'
    END AS expected_audience_age
FROM public.film f
INNER JOIN public.inventory i ON f.film_id = i.film_id
INNER JOIN public.rental r ON i.inventory_id = r.inventory_id
GROUP BY f.film_id, f.title, f.rating
ORDER BY rental_count DESC
LIMIT 5;
--Advantages:
--More efficient for small or straightforward aggregations.Uses fewer system resources.
--Disadvantages:
--Readability decreases if logic becomes complex, for example, add more filtering

-- CTE solution
WITH movie_rentals AS (
    SELECT 
        f.film_id,
        f.title,
        f.rating,
        COUNT(r.rental_id) AS rental_count
    FROM public.film f
    INNER JOIN public.inventory i ON f.film_id = i.film_id
    INNER JOIN public.rental r ON i.inventory_id = r.inventory_id
    GROUP BY f.film_id, f.title, f.rating
)
SELECT 
    title,
    rental_count,
    CASE rating
        WHEN 'G' THEN '0-6'
        WHEN 'PG' THEN '7-12'
        WHEN 'PG-13' THEN '13-16'
        WHEN 'R' THEN '17-20'
        WHEN 'NC-17' THEN '21+'
        ELSE 'Unknown'
    END AS expected_audience_age
FROM movie_rentals
ORDER BY rental_count DESC
LIMIT 5;
--Advantages:
--Improves readability, separates counting rentals (movie_rentals) from final filtering.
--Disadvantages:
--Higher memory usage. Unnecessary for simple aggregations.

--Subquery
SELECT 
    f.title,
    (
        SELECT COUNT(*) 
        FROM public.inventory i 
        INNER JOIN public.rental r ON i.inventory_id = r.inventory_id
        WHERE i.film_id = f.film_id
    ) AS rental_count,
    CASE f.rating
        WHEN 'G' THEN '0-6'
        WHEN 'PG' THEN '7-12'
        WHEN 'PG-13' THEN '13-16'
        WHEN 'R' THEN '17-20'
        WHEN 'NC-17' THEN '21+'
        ELSE 'Unknown'
    END AS expected_audience_age
FROM public.film f
ORDER BY rental_count DESC
LIMIT 5;
--Advantages:
--Simple to read, the logic is directly inside SELECT.
--Disadvantages:
--Subquery runs once per film, slower for large datasets.


--Part 3. Which actors/actresses didn't act for a longer period of time than the others? 
-- TASK 3: Identify actors/actresses who had long inactivity periods
-- V1 JOIN
SELECT 
    a.first_name,
    a.last_name,
    EXTRACT(YEAR FROM CURRENT_DATE) - MAX(f.release_year) AS years_inactive
FROM public.actor a
INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
INNER JOIN public.film f ON fa.film_id = f.film_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY years_inactive DESC;

--V2 JOIN
SELECT 
    a.actor_id,
    a.first_name,
    a.last_name,
    MAX(f2.release_year - f1.release_year) AS max_gap
FROM public.actor a
INNER JOIN public.film_actor fa1 ON a.actor_id = fa1.actor_id
INNER JOIN public.film f1 ON fa1.film_id = f1.film_id
INNER JOIN public.film_actor fa2 ON a.actor_id = fa2.actor_id
INNER JOIN public.film f2 ON fa2.film_id = f2.film_id
WHERE f2.release_year > f1.release_year
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY max_gap DESC;
--Advantages:
--Executes in a single query — faster and uses fewer resources. Suitable for small datasets.
--Disadvantages:
--Harder to reuse parts of logic separately. Harder to read due to multiple self-joins.

--V1 CTE
WITH actor_last_film AS (
    SELECT 
        a.actor_id,
        a.first_name,
        a.last_name,
        MAX(f.release_year) AS last_film_year
    FROM public.actor a
    INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
    INNER JOIN public.film f ON fa.film_id = f.film_id
    GROUP BY a.actor_id, a.first_name, a.last_name
)
SELECT 
    first_name,
    last_name,
    EXTRACT(YEAR FROM CURRENT_DATE) - last_film_year AS years_inactive
FROM actor_last_film
ORDER BY years_inactive DESC;

--V2 CTE
WITH actor_films AS (
    SELECT 
        a.actor_id,
        a.first_name,
        a.last_name,
        f.release_year
    FROM public.actor a
    INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
    INNER JOIN public.film f ON fa.film_id = f.film_id
),
actor_gaps AS (
    SELECT 
        af1.actor_id,
        af1.first_name,
        af1.last_name,
        MAX(af2.release_year - af1.release_year) AS max_gap
    FROM actor_films af1
    INNER JOIN actor_films af2 
        ON af1.actor_id = af2.actor_id 
        AND af2.release_year > af1.release_year
    GROUP BY af1.actor_id, af1.first_name, af1.last_name
)
SELECT *
FROM actor_gaps
ORDER BY max_gap DESC;
--Advantages:
--Good structure for reports or when logic may expand later. Easier to understand and modify multi-step logic.
--Disadvantages:
--Higher memory usage for intermediate tables. Overhead for simple one-step aggregations.


-- V1 subquery
SELECT 
    a.first_name,
    a.last_name,
    EXTRACT(YEAR FROM CURRENT_DATE) - (
        SELECT MAX(f.release_year)
        FROM public.film_actor fa
        INNER JOIN public.film f ON fa.film_id = f.film_id
        WHERE fa.actor_id = a.actor_id
    ) AS years_inactive
FROM public.actor a
ORDER BY years_inactive DESC;
-- V2 subquery
SELECT 
    a.first_name,
    a.last_name,
    (
        SELECT MAX(f2.release_year - f1.release_year)
        FROM public.film_actor fa1
        INNER JOIN public.film f1 ON fa1.film_id = f1.film_id
        INNER JOIN public.film_actor fa2 ON fa2.actor_id = fa1.actor_id
        INNER JOIN public.film f2 ON fa2.film_id = f2.film_id
        WHERE fa1.actor_id = a.actor_id
          AND f2.release_year > f1.release_year
    ) AS max_gap
FROM public.actor a
ORDER BY max_gap DESC;
--Advantages:
--No need for JOINs or CTEs in the outer query.
--Disadvantages:
--Subquery runs per actor are slower for large actor tables.