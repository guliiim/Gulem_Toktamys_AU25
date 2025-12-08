--Task 2. Implement role-based authentication model for dvd_rental database
-- 0.Drop all things
--Drop RLS policies
DROP POLICY IF EXISTS rental_rls_select ON public.rental;
DROP POLICY IF EXISTS rental_rls_update ON public.rental;
DROP POLICY IF EXISTS payment_rls_select ON public.payment;

--Disable RLS on tables
ALTER TABLE public.rental DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment DISABLE ROW LEVEL SECURITY;

--Drop all client roles
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT rolname FROM pg_roles WHERE rolname LIKE 'client_%' LOOP
        EXECUTE 'REVOKE ALL ON DATABASE dvdrental FROM ' || quote_ident(r.rolname);
        EXECUTE 'REVOKE ALL ON ALL TABLES IN SCHEMA public FROM ' || quote_ident(r.rolname);
        EXECUTE 'DROP ROLE ' || quote_ident(r.rolname);
    END LOOP;
END $$;

--Revoke rental group from rentaluser first
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='rentaluser') 
       AND EXISTS (SELECT 1 FROM pg_roles WHERE rolname='rental') THEN
        REVOKE rental FROM rentaluser;
    END IF;
END $$;

--Revoke all permissions from rental group
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='rental') THEN
        REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM rental;
        REVOKE ALL ON ALL TABLES IN SCHEMA public FROM rental;
        REVOKE ALL ON DATABASE dvdrental FROM rental;
    END IF;
END $$;

--Revoke all permissions from rentaluser
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='rentaluser') THEN
        REVOKE ALL ON ALL TABLES IN SCHEMA public FROM rentaluser;
        REVOKE ALL ON DATABASE dvdrental FROM rentaluser;
    END IF;
END $$;

--Drop the roles
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='rentaluser') THEN
        DROP ROLE rentaluser;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='rental') THEN
        DROP ROLE rental;
    END IF;
END $$;

--Drop the helper function if it exists
DROP FUNCTION IF EXISTS get_customer_id_from_role();


--1.Create a new user with no permissions except CONNECT
CREATE ROLE rentaluser LOGIN PASSWORD 'rentalpassword';
GRANT CONNECT ON DATABASE dvdrental TO rentaluser;

--2.Grant SELECT on the customer table
GRANT SELECT ON public.customer TO rentaluser;

SET ROLE rentaluser;
SELECT customer_id, first_name, last_name, email FROM public.customer ORDER BY customer_id LIMIT 5;
RESET ROLE;

--3.Create a group and add the user
CREATE ROLE rental;
GRANT rental TO rentaluser;

--4.Grant INSERT and UPDATE on rental table to GROUP
GRANT INSERT, UPDATE ON public.rental TO rental;
GRANT USAGE, SELECT, UPDATE ON SEQUENCE public.rental_rental_id_seq TO rental;

ALTER ROLE rentaluser INHERIT;

SET ROLE rentaluser;

INSERT INTO public.rental (rental_date, inventory_id, customer_id, staff_id)
SELECT NOW(), 
       (SELECT inventory_id FROM public.inventory LIMIT 1), 
       (SELECT customer_id FROM public.customer LIMIT 1), 
       (SELECT staff_id FROM public.staff LIMIT 1);


UPDATE public.rental
SET return_date = NOW()
WHERE rental_id = (SELECT MAX(rental_id) FROM public.rental);

RESET ROLE;

--5.Revoke INSERT permission from the group
REVOKE INSERT ON public.rental FROM rental;

SET ROLE rentaluser;

INSERT INTO public.rental (rental_date, inventory_id, customer_id, staff_id) 
SELECT NOW(), 
       (SELECT inventory_id FROM public.inventory LIMIT 1), 
       (SELECT customer_id FROM public.customer LIMIT 1), 
       (SELECT staff_id FROM public.staff LIMIT 1);

RESET ROLE;

-- 6. Create personalized role for a customer
--Clean up existing client roles
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT rolname FROM pg_roles WHERE rolname LIKE 'client_%' LOOP
        EXECUTE 'DROP ROLE ' || quote_ident(r.rolname);
    END LOOP;
END $$;

RESET ROLE;

DO $$
DECLARE
    cust RECORD;
    role_name TEXT;
BEGIN
    FOR cust IN
        SELECT c.customer_id, c.first_name, c.last_name
        FROM public.customer c
        WHERE EXISTS (SELECT 1 FROM public.payment p WHERE p.customer_id = c.customer_id)
          AND EXISTS (SELECT 1 FROM public.rental r WHERE r.customer_id = c.customer_id)
    LOOP
        role_name := 'client_' || LOWER(cust.first_name) || '_' || LOWER(cust.last_name);

        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = role_name) THEN
            EXECUTE 'CREATE ROLE ' || quote_ident(role_name) || ' LOGIN;';
        END IF;

        EXECUTE 'GRANT CONNECT ON DATABASE dvdrental TO ' || quote_ident(role_name);
        EXECUTE 'GRANT SELECT ON public.rental TO ' || quote_ident(role_name);
        EXECUTE 'GRANT SELECT ON public.payment TO ' || quote_ident(role_name);
        EXECUTE 'GRANT SELECT ON public.customer TO ' || quote_ident(role_name);

        RAISE NOTICE 'Created and granted role: % for customer_id: %', role_name, cust.customer_id;
    END LOOP;
END $$;
--Test
SELECT rolname
FROM pg_roles
WHERE rolname LIKE 'client_%'
ORDER BY rolname;


--Task 3.Implement row-level security
DROP POLICY IF EXISTS rental_rls_select ON public.rental;
DROP POLICY IF EXISTS rental_rls_update ON public.rental;
DROP POLICY IF EXISTS payment_rls_select ON public.payment;

ALTER TABLE public.rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment ENABLE ROW LEVEL SECURITY;

--Create helper function
CREATE OR REPLACE FUNCTION get_customer_id_from_role() RETURNS INTEGER AS $$
DECLARE
    role_parts TEXT[];
    cust_first TEXT;
    cust_last TEXT;
    cust_id INTEGER;
BEGIN
    role_parts := string_to_array(current_user, '_');
    
    IF array_length(role_parts, 1) >= 3 AND role_parts[1] = 'client' THEN
        cust_first := role_parts[2];
        cust_last := role_parts[3];
        
        SELECT customer_id INTO cust_id
        FROM public.customer
        WHERE LOWER(first_name) = cust_first AND LOWER(last_name) = cust_last
        LIMIT 1;
        
        RETURN cust_id;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE POLICY rental_rls_select
ON public.rental
FOR SELECT
TO PUBLIC
USING (customer_id = get_customer_id_from_role());

CREATE POLICY rental_rls_update
ON public.rental
FOR UPDATE
TO PUBLIC
USING (customer_id = get_customer_id_from_role());

CREATE POLICY payment_rls_select
ON public.payment
FOR SELECT
TO PUBLIC
USING (customer_id = get_customer_id_from_role());
