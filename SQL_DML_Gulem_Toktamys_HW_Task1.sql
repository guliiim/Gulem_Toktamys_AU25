--Task 1
--1
INSERT INTO public.film (
    title, description, release_year, language_id, rental_duration, rental_rate, length, rating, last_update
)
SELECT 'Pride and Prejudice', 'Romantic period drama', 2005, 1, 1, 4.99, 129, 'PG', current_date
WHERE NOT EXISTS (SELECT 1 FROM public.film WHERE title='Pride and Prejudice')
RETURNING film_id;

INSERT INTO public.film (
    title, description, release_year, language_id, rental_duration, rental_rate, length, rating, last_update
)
SELECT 'La La Land', 'Romantic musical movie', 2016, 1, 2, 9.99, 128, 'PG-13', current_date
WHERE NOT EXISTS (SELECT 1 FROM public.film WHERE title='La La Land')
RETURNING film_id;

INSERT INTO public.film (
    title, description, release_year, language_id, rental_duration, rental_rate, length, rating, last_update
)
SELECT 'The Notebook', 'Romantic drama movie', 2004, 1, 3, 19.99, 123, 'PG-13', current_date
WHERE NOT EXISTS (SELECT 1 FROM public.film WHERE title='The Notebook')
RETURNING film_id;

COMMIT;
--Use WHERE NOT EXISTS to ensure rerunnability without creating duplicate movies. and last_update is set to current_date to follow the requirement.

--2
INSERT INTO public.actor (first_name, last_name, last_update)
SELECT 'Keira', 'Knightley', current_date
WHERE NOT EXISTS (SELECT 1 FROM public.actor WHERE first_name='Keira' AND last_name='Knightley')
RETURNING actor_id;

INSERT INTO public.actor (first_name, last_name, last_update)
SELECT 'Matthew', 'Macfadyen', current_date
WHERE NOT EXISTS (SELECT 1 FROM public.actor WHERE first_name='Matthew' AND last_name='Macfadyen')
RETURNING actor_id;

INSERT INTO public.actor (first_name, last_name, last_update)
SELECT 'Ryan', 'Gosling', current_date
WHERE NOT EXISTS (SELECT 1 FROM public.actor WHERE first_name='Ryan' AND last_name='Gosling')
RETURNING actor_id;

INSERT INTO public.actor (first_name, last_name, last_update)
SELECT 'Emma', 'Stone', current_date
WHERE NOT EXISTS (SELECT 1 FROM public.actor WHERE first_name='Emma' AND last_name='Stone')
RETURNING actor_id;

INSERT INTO public.actor (first_name, last_name, last_update)
SELECT 'Ryan', 'Reynolds', current_date
WHERE NOT EXISTS (SELECT 1 FROM public.actor WHERE first_name='Ryan' AND last_name='Reynolds')
RETURNING actor_id;

INSERT INTO public.actor (first_name, last_name, last_update)
SELECT 'Rachel', 'McAdams', current_date
WHERE NOT EXISTS (SELECT 1 FROM public.actor WHERE first_name='Rachel' AND last_name='McAdams')
RETURNING actor_id;

COMMIT;
--Use WHERE NOT EXISTS to prevent duplicate actors. and each actor has last_update=current_date.

--3
INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, current_date
FROM public.actor a
JOIN public.film f ON f.title='Pride and Prejudice'
WHERE (a.first_name='Keira' AND a.last_name='Knightley')
   OR (a.first_name='Matthew' AND a.last_name='Macfadyen')
ON CONFLICT DO NOTHING
RETURNING *;

INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, current_date
FROM public.actor a
JOIN public.film f ON f.title='La La Land'
WHERE (a.first_name='Ryan' AND a.last_name='Gosling')
   OR (a.first_name='Emma' AND a.last_name='Stone')
ON CONFLICT DO NOTHING
RETURNING *;

INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, current_date
FROM public.actor a
JOIN public.film f ON f.title='The Notebook'
WHERE (a.first_name='Ryan' AND a.last_name='Reynolds')
   OR (a.first_name='Rachel' AND a.last_name='McAdams')
ON CONFLICT DO NOTHING
RETURNING *;

COMMIT;
--Use dynamic joins to get actor_id and film_id, ON CONFLICT DO NOTHING to avoid duplicates. and this approach avoids hardcoding IDs and is rerunnable.

--4
INSERT INTO public.inventory (film_id, store_id, last_update)
SELECT f.film_id, s.store_id, current_date
FROM public.film f
CROSS JOIN public.store s
WHERE f.title IN ('Pride and Prejudice', 'La La Land', 'The Notebook')
  AND NOT EXISTS (
      SELECT 1 FROM public.inventory i
      WHERE i.film_id=f.film_id AND i.store_id=s.store_id
  )
RETURNING *;

COMMIT;
--Use CROSS JOIN to add to all stores, NOT EXISTS to prevent duplicates.

--5
WITH target_customer AS (
    SELECT c.customer_id
    FROM public.customer c
    JOIN public.payment p ON c.customer_id=p.customer_id
    JOIN public.rental r ON c.customer_id=r.customer_id
    GROUP BY c.customer_id
    HAVING COUNT(DISTINCT p.payment_id) >= 43
       AND COUNT(DISTINCT r.rental_id) >= 43
    LIMIT 1
)
UPDATE public.customer
SET
    first_name = 'Gulem',
    last_name = 'Toktamys',
    email = 'glimtoktamys82@gmail.com',
    address_id = (SELECT address_id FROM public.address LIMIT 1),
    last_update = current_date
WHERE customer_id = (SELECT customer_id FROM target_customer)
RETURNING *;

COMMIT;
--Select a customer with more than 43 rentals and payments to meet task requirements. and only updates customer table, not address. Dynamic selection avoids hardcoding customer_id.

--6
WITH my_cust AS (
    SELECT customer_id FROM public.customer WHERE first_name='Gulem' AND last_name='Toktamys'
)
DELETE FROM public.payment
WHERE customer_id IN (SELECT customer_id FROM my_cust)
RETURNING *;

WITH my_cust AS (
    SELECT customer_id FROM public.customer WHERE first_name='Gulem' AND last_name='Toktamys'
)
DELETE FROM public.rental
WHERE customer_id IN (SELECT customer_id FROM my_cust)
RETURNING *;

COMMIT;
--Clean old records to prevent conflicts when adding new rentals or payments.


--7
WITH my_cust AS ( 
    SELECT customer_id FROM public.customer WHERE first_name='Gulem' AND last_name='Toktamys'
),
movie_inventory AS (
    SELECT i.inventory_id, i.film_id
    FROM public.inventory i
    JOIN public.film f ON f.film_id=i.film_id
    WHERE f.title IN ('Pride and Prejudice', 'La La Land', 'The Notebook')
),
rented AS (
    INSERT INTO public.rental (rental_date, inventory_id, customer_id, staff_id)
    SELECT '2017-01-01', mi.inventory_id, mc.customer_id, 1
    FROM movie_inventory mi
    CROSS JOIN my_cust mc
    RETURNING rental_id, customer_id, inventory_id
)
INSERT INTO public.payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT r.customer_id, 1, r.rental_id, f.rental_rate, '2017-01-01'
FROM rented r
JOIN public.inventory i ON i.inventory_id=r.inventory_id
JOIN public.film f ON f.film_id=i.film_id
RETURNING *;

COMMIT;
--Use CTEs to dynamically insert rentals and payments, link rental to inventory to film for rates. and dynamic approach ensures rerunnability and avoids hardcoding IDs.

