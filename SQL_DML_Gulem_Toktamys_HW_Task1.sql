BEGIN;
--Task 1
--1
INSERT INTO public.film (
    title, description, release_year, language_id, rental_duration, rental_rate, length, rating, last_update
)
SELECT 'Pride and Prejudice', 'Romantic period drama', 2005, 1, 7, 4.99, 129, 'PG', current_date
WHERE NOT EXISTS (SELECT 1 FROM public.film WHERE LOWER(title)='pride and prejudice')
RETURNING film_id;

INSERT INTO public.film (
    title, description, release_year, language_id, rental_duration, rental_rate, length, rating, last_update
)
SELECT 'La La Land', 'Romantic musical movie', 2016, 1, 14, 9.99, 128, 'PG-13', current_date
WHERE NOT EXISTS (SELECT 1 FROM public.film WHERE LOWER(title)='la la land')
RETURNING film_id;

INSERT INTO public.film (
    title, description, release_year, language_id, rental_duration, rental_rate, length, rating, last_update
)
SELECT 'The Notebook', 'Romantic drama movie', 2004, 1, 21, 19.99, 123, 'PG-13', current_date
WHERE NOT EXISTS (SELECT 1 FROM public.film WHERE LOWER(title)='the notebook')
RETURNING film_id;

--Use WHERE NOT EXISTS to ensure rerunnability without creating duplicate movies. and last_update is set to current_date to follow the requirement.

--2
INSERT INTO public.actor (first_name, last_name, last_update)
SELECT 'Keira', 'Knightley', current_date
WHERE NOT EXISTS (SELECT 1 FROM public.actor WHERE LOWER(first_name)='keira' AND LOWER(last_name)='knightley')
RETURNING actor_id;

INSERT INTO public.actor (first_name, last_name, last_update)
SELECT 'Matthew', 'Macfadyen', current_date
WHERE NOT EXISTS (SELECT 1 FROM public.actor WHERE LOWER(first_name)='matthew' AND LOWER(last_name)='macfadyen')
RETURNING actor_id;

INSERT INTO public.actor (first_name, last_name, last_update)
SELECT 'Ryan', 'Gosling', current_date
WHERE NOT EXISTS (SELECT 1 FROM public.actor WHERE LOWER(first_name)='ryan' AND LOWER(last_name)='gosling')
RETURNING actor_id;

INSERT INTO public.actor (first_name, last_name, last_update)
SELECT 'Emma', 'Stone', current_date
WHERE NOT EXISTS (SELECT 1 FROM public.actor WHERE LOWER(first_name)='emma' AND LOWER(last_name)='stone')
RETURNING actor_id;

INSERT INTO public.actor (first_name, last_name, last_update)
SELECT 'Ryan', 'Reynolds', current_date
WHERE NOT EXISTS (SELECT 1 FROM public.actor WHERE LOWER(first_name)='ryan' AND LOWER(last_name)='reynolds')
RETURNING actor_id;

INSERT INTO public.actor (first_name, last_name, last_update)
SELECT 'Rachel', 'McAdams', current_date
WHERE NOT EXISTS (SELECT 1 FROM public.actor WHERE LOWER(first_name)='rachel' AND LOWER(last_name)='mcadams')
RETURNING actor_id;


--Use WHERE NOT EXISTS to prevent duplicate actors. and each actor has last_update=current_date.

--3
INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, current_date
FROM public.actor a
JOIN public.film f ON LOWER(f.title)='pride and prejudice'
WHERE LOWER(a.first_name) IN ('keira','matthew')
	AND (
		(LOWER(a.first_name)='keira' AND LOWER(a.last_name)='knightley') OR
		(LOWER(a.first_name)='matthew' AND LOWER(a.last_name)='macfadyen')
	  )
ON CONFLICT (actor_id, film_id) DO NOTHING
RETURNING *;

INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, current_date
FROM public.actor a
JOIN public.film f ON LOWER(f.title)='la la land'
WHERE (LOWER(a.first_name)='ryan' AND LOWER(a.last_name)='gosling')
   OR (LOWER(a.first_name)='emma' AND LOWER(a.last_name)='stone')
ON CONFLICT (actor_id, film_id) DO NOTHING
RETURNING *;

INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, current_date
FROM public.actor a
JOIN public.film f ON LOWER(f.title)='the notebook'
WHERE (LOWER(a.first_name)='ryan' AND LOWER(a.last_name)='reynolds')
   OR (LOWER(a.first_name)='rachel' AND LOWER(a.last_name)='mcadams')
ON CONFLICT (actor_id, film_id) DO NOTHING
RETURNING *;

--Use dynamic joins to get actor_id and film_id, ON CONFLICT DO NOTHING to avoid duplicates. and this approach avoids hardcoding IDs and is rerunnable.

--4
INSERT INTO public.inventory (film_id, store_id, last_update)
SELECT f.film_id, s.store_id, current_date
FROM public.film f
CROSS JOIN public.store s
WHERE LOWER(f.title) IN ('pride and prejudice','la la land','the notebook')
AND NOT EXISTS (
    SELECT 1 FROM public.inventory i
    WHERE i.film_id = f.film_id AND i.store_id = s.store_id
)
RETURNING *;

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
    address_id=(SELECT MIN(address_id) FROM public.address), 
    last_update = current_date
WHERE customer_id = (SELECT customer_id FROM target_customer)
RETURNING *;


--Select a customer with more than 43 rentals and payments to meet task requirements. and only updates customer table, not address. Dynamic selection avoids hardcoding customer_id.

--6
WITH me AS (
    SELECT customer_id FROM public.customer
    WHERE LOWER(first_name)='gulem' AND LOWER(last_name)='toktamys'
)
DELETE FROM public.payment   
WHERE customer_id 
IN (SELECT customer_id FROM me);

DELETE FROM public.rental    
WHERE customer_id 
IN (SELECT customer_id FROM me);

--Clean old records to prevent conflicts when adding new rentals or payments.


--7
WITH my_cust AS ( 
    SELECT customer_id 
	FROM public.customer 
	WHERE LOWER(first_name)='gulem' 
		AND LOWER(last_name)='toktamys'
),
movie_inventory AS (
    SELECT i.inventory_id, i.film_id
    FROM public.inventory i
    JOIN public.film f ON f.film_id=i.film_id
    WHERE LOWER(f.title) IN ('pride and prejudice','la la land','the notebook')
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