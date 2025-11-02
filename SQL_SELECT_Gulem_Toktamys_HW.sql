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
WHERE c.name = 'Animation'
	AND f.release_year BETWEEN 2017 AND 2019
	AND f.rental_rate > 1
ORDER BY f.title ASC;

JOIN Solution Explanation:
This query performs the same logic directly in a single SELECT statement 
with INNER JOINs and WHERE filters. 

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
    WHERE c.name = 'Animation'
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


-- TASK 2: Calculate revenue earned by each rental store after March 2017
-- JOIN solution
SELECT 
    (CASE WHEN a.address IS NULL THEN '' ELSE a.address END) || ' ' ||
    (CASE WHEN a.address2 IS NULL THEN '' ELSE a.address2 END) AS full_address,
    SUM(p.amount) AS revenue
FROM public.payment p
INNER JOIN public.rental r ON p.rental_id = r.rental_id
INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
INNER JOIN public.store s ON i.store_id = s.store_id
INNER JOIN public.address a ON s.address_id = a.address_id
WHERE p.payment_date >= '2017-04-01'
GROUP BY a.address, a.address2
ORDER BY revenue DESC;

--Advantages:
--faster, query planner can optimize join and group steps together  
--Disadvantages:
--harder to read, less modular for reuse in other queries

-- CTE solution
WITH store_revenue AS ( 
    SELECT 
        s.store_id,
        (CASE WHEN a.address IS NULL THEN '' ELSE a.address END) || ' ' ||
        (CASE WHEN a.address2 IS NULL THEN '' ELSE a.address2 END) AS full_address,
        SUM(p.amount) AS revenue
    FROM public.payment p
    INNER JOIN public.rental r ON p.rental_id = r.rental_id
    INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN public.store s ON i.store_id = s.store_id
    INNER JOIN public.address a ON s.address_id = a.address_id
    WHERE p.payment_date >= '2017-04-01'
    GROUP BY s.store_id, a.address, a.address2
)
SELECT full_address, revenue
FROM store_revenue
ORDER BY revenue DESC;

--Advantages:
--Reusable temporary result set  
--Disadvantages:
--CTE can be slower on very large tables, and higher memory usage  


-- TASK 3: Show top-5 actors by number of movies they participated in since 2015
-- JOIN solution
SELECT 
    a.first_name,
    a.last_name,
    COUNT(f.film_id) AS number_of_movies
FROM public.actor a
INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
INNER JOIN public.film f ON fa.film_id = f.film_id
WHERE f.release_year > 2015
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
    WHERE f.release_year > 2015
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


-- TASK 4: Count number of Drama, Travel, and Documentary movies per release year
-- JOIN solution
SELECT
    f.release_year,
    CASE 
        WHEN SUM(CASE WHEN c.name = 'Drama' THEN 1 ELSE 0 END) IS NULL THEN 0
        ELSE SUM(CASE WHEN c.name = 'Drama' THEN 1 ELSE 0 END)
    END AS number_of_drama_movies,
    CASE 
        WHEN SUM(CASE WHEN c.name = 'Travel' THEN 1 ELSE 0 END) IS NULL THEN 0
        ELSE SUM(CASE WHEN c.name = 'Travel' THEN 1 ELSE 0 END)
    END AS number_of_travel_movies,
    CASE 
        WHEN SUM(CASE WHEN c.name = 'Documentary' THEN 1 ELSE 0 END) IS NULL THEN 0
        ELSE SUM(CASE WHEN c.name = 'Documentary' THEN 1 ELSE 0 END)
    END AS number_of_documentary_movies
FROM public.film f
INNER JOIN public.film_category fc ON f.film_id = fc.film_id
INNER JOIN public.category c ON fc.category_id = c.category_id
WHERE c.name IN ('Drama', 'Travel', 'Documentary')
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
        c.name AS genre,
        COUNT(f.film_id) AS genre_count
    FROM public.film f
    INNER JOIN public.film_category fc ON f.film_id = fc.film_id
    INNER JOIN public.category c ON fc.category_id = c.category_id
    WHERE c.name IN ('Drama', 'Travel', 'Documentary')
    GROUP BY f.release_year, c.name
)
SELECT
    release_year,
    CASE 
        WHEN MAX(CASE WHEN genre = 'Drama' THEN genre_count END) IS NULL THEN 0
        ELSE MAX(CASE WHEN genre = 'Drama' THEN genre_count END)
    END AS number_of_drama_movies,
    CASE 
        WHEN MAX(CASE WHEN genre = 'Travel' THEN genre_count END) IS NULL THEN 0
        ELSE MAX(CASE WHEN genre = 'Travel' THEN genre_count END)
    END AS number_of_travel_movies,
    CASE 
        WHEN MAX(CASE WHEN genre = 'Documentary' THEN genre_count END) IS NULL THEN 0
        ELSE MAX(CASE WHEN genre = 'Documentary' THEN genre_count END)
    END AS number_of_documentary_movies
FROM genre_counts
GROUP BY release_year
ORDER BY release_year DESC;

--Advantages:
--Readable, logic separated into manageable parts, and easy to maintain and expand
--Disadvantages:
--performance overhead compared to direct JOINs 


--Part 2: Solve the following problems using SQL
-- TASK 1: Show top-3 employees who generated the most revenue in 2017
-- JOIN solution
SELECT 
    s.first_name,
    s.last_name,
    i.store_id,
    SUM(p.amount) AS revenue
FROM public.staff s
INNER JOIN public.payment p ON s.staff_id = p.staff_id
INNER JOIN public.rental r ON p.rental_id = r.rental_id
INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
WHERE p.payment_date >= '2017-01-01' 
	AND p.payment_date < '2018-01-01'
GROUP BY s.staff_id, s.first_name, s.last_name, i.store_id
ORDER BY revenue DESC
LIMIT 3;

--Advantages:
--Simpler and faster for small datasets. Uses fewer resources.
--Disadvantages:
--Less readable when more conditions or joins are added.

-- CTE solution
WITH staff_revenue AS (
    SELECT
        s.staff_id,
        s.first_name,
        s.last_name,
        i.store_id,
        SUM(p.amount) AS revenue,
        MAX(p.payment_date) AS last_payment_date
    FROM public.staff s
    INNER JOIN public.payment p ON s.staff_id = p.staff_id
    INNER JOIN public.rental r ON p.rental_id = r.rental_id
    INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
    WHERE p.payment_date >= '2017-01-01' 
    	AND p.payment_date < '2018-01-01'
    GROUP BY s.staff_id, s.first_name, s.last_name, i.store_id
),
last_store_per_staff AS (
    SELECT DISTINCT ON (staff_id)
        staff_id,
        first_name,
        last_name,
        store_id,
        revenue
    FROM staff_revenue
    ORDER BY staff_id, last_payment_date DESC
)
SELECT first_name, last_name, store_id, revenue
FROM last_store_per_staff
ORDER BY revenue DESC
LIMIT 3;

--Advantages:
--Easier to debug or reuse the filtered subset. Good for complex queries with multiple filters or joins.
--Disadvantages:
--Consumes more memory, not necessary for small or simple queries.


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


--Part 3. Which actors/actresses didn't act for a longer period of time than the others? 
-- TASK 3: Identify actors/actresses who had long inactivity periods
-- V1 JOIN
SELECT 
    a.first_name,
    a.last_name,
    TO_CHAR(CURRENT_DATE, 'YYYY')::numeric - MAX(f.release_year) AS years_inactive
FROM public.actor a
INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
INNER JOIN public.film f ON fa.film_id = f.film_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY years_inactive DESC;


--V2 JOIN
-- V2 JOIN: gaps between sequential films per actor
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
    TO_CHAR(CURRENT_DATE, 'YYYY')::numeric - last_film_year AS years_inactive
FROM actor_last_film
ORDER BY years_inactive DESC;

--V2 CTE
WITH actor_films AS (
    SELECT 
        a.actor_id,
        a.first_name,
        a.last_name,
        f.film_id,
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
    FROM actor_films AS af1
    INNER JOIN actor_films AS af2 
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