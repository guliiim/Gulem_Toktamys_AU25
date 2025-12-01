--Task 2. Implement role-based authentication model for dvd_rental database
--Create a new user with no permissions except CONNECT
CREATE ROLE rentaluser LOGIN PASSWORD 'rentalpassword';

GRANT CONNECT ON DATABASE dvdrental TO rentaluser;

--Grant SELECT on the customer table
GRANT SELECT ON public.customer TO rentaluser;

SELECT customer_id, first_name, last_name, email
FROM public.customer
ORDER BY customer_id;
--I test this in windows cmd

--Create a group and add the user
CREATE ROLE rental;

GRANT rental TO rentaluser;

--Grant INSERT and UPDATE on rental table to group
GRANT INSERT, UPDATE ON public.rental TO rental;

GRANT USAGE, SELECT, UPDATE ON SEQUENCE public.rental_rental_id_seq TO rentaluser;

SET ROLE rentaluser;
INSERT INTO public.rental (rental_date, inventory_id, customer_id, staff_id) 
VALUES (NOW(), 1, 1, 1);
ALTER ROLE rentaluser INHERIT;
RESET ROLE;

--Revoke INSERT permission from the group
REVOKE INSERT ON public.rental FROM rental;

SET ROLE rentaluser;

INSERT INTO public.rental (rental_date, inventory_id, customer_id, staff_id) 
VALUES (NOW(), 1, 1, 1);  

RESET ROLE;

--Create personalized role for a customer
DO $$
DECLARE
    cust RECORD;
    role_name TEXT;
BEGIN
    FOR cust IN
        SELECT c.customer_id, c.first_name, c.last_name
        FROM public.customer c
        JOIN public.payment p ON c.customer_id = p.customer_id
        JOIN public.rental r ON c.customer_id = r.customer_id
        GROUP BY c.customer_id
    LOOP
        role_name := 'client_' || LOWER(cust.first_name) || '_' || LOWER(cust.last_name);
        EXECUTE 'CREATE ROLE ' || quote_ident(role_name) || ' LOGIN;';
    END LOOP;
END $$;

--Task 3. Implement row-level security
ALTER TABLE public.rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment ENABLE ROW LEVEL SECURITY;

CREATE POLICY rental_rls_select
ON public.rental
FOR SELECT
TO PUBLIC
USING (customer_id = split_part(current_user, '_', 4)::int);

CREATE POLICY rental_rls_update
ON public.rental
FOR UPDATE
TO PUBLIC
USING (customer_id = split_part(current_user, '_', 4)::int);

CREATE POLICY payment_rls_select
ON public.payment
FOR SELECT
TO PUBLIC
USING (customer_id = split_part(current_user, '_', 4)::int);


--Test
SELECT rolname
FROM pg_roles
WHERE rolname LIKE 'client_%'
ORDER BY rolname;

SET ROLE client_aaron_selby_1;

SELECT rental_id, customer_id, rental_date, return_date
FROM public.rental
WHERE customer_id = 1
ORDER BY rental_id;

UPDATE public.rental
SET return_date = NOW()
WHERE rental_id = 32303;

RESET ROLE;



