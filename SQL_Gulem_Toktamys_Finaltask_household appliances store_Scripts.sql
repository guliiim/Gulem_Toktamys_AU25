CREATE DATABASE household_store_db;

CREATE SCHEMA IF NOT EXISTS household_store;

--Create Table
CREATE TABLE IF NOT EXISTS household_store.products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    brand VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    category VARCHAR(50) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    stock_quantity INT NOT NULL 
);

CREATE TABLE IF NOT EXISTS household_store.customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address VARCHAR(200),
    full_name VARCHAR(120) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED
);

CREATE TABLE IF NOT EXISTS household_store.employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    position VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    full_name VARCHAR(120) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED
);

CREATE TABLE IF NOT EXISTS household_store.suppliers (
    supplier_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact_name VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    address VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS household_store.orders (
    order_id SERIAL PRIMARY KEY,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    customer_id INT NOT NULL REFERENCES household_store.customers(customer_id),
    employee_id INT NOT NULL REFERENCES household_store.employees(employee_id),
    status VARCHAR(20) NOT NULL,
    total_amount DECIMAL(10,2) DEFAULT 0
);

CREATE TABLE IF NOT EXISTS household_store.order_details (
    order_id INT REFERENCES household_store.orders(order_id) ON DELETE CASCADE,
    product_id INT REFERENCES household_store.products(product_id),
    quantity INT NOT NULL CHECK (quantity > 0),
    price_each DECIMAL(10,2) NOT NULL CHECK (price_each > 0),
    PRIMARY KEY (order_id, product_id)
);

CREATE TABLE IF NOT EXISTS household_store.product_suppliers (
    product_id INT REFERENCES household_store.products(product_id),
    supplier_id INT REFERENCES household_store.suppliers(supplier_id),
    supply_price DECIMAL(10,2) NOT NULL CHECK (supply_price > 0),
    PRIMARY KEY (product_id, supplier_id)
);

--Add Constraints
ALTER TABLE household_store.products
ADD CONSTRAINT chk_product_price_positive
CHECK (price > 0);

ALTER TABLE household_store.products
ADD CONSTRAINT chk_stock_quantity_nonnegative
CHECK (stock_quantity >= 0);

ALTER TABLE household_store.orders
ADD CONSTRAINT chk_order_date_after_2024
CHECK (order_date >= '2024-01-01');

ALTER TABLE household_store.orders
ADD CONSTRAINT chk_order_status_values
CHECK (status IN ('Pending', 'Shipped', 'Delivered', 'Cancelled'));

ALTER TABLE household_store.order_details
ADD CONSTRAINT chk_order_details_quantity_positive
CHECK (quantity > 0);

--Insert Data
INSERT INTO household_store.products (name, brand, model, category, price, stock_quantity)
SELECT 
    'Product ' || i AS name,
    'Brand ' || ((i % 5) + 1) AS brand,
    'Model ' || i AS model,
    CASE WHEN i % 3 = 0 THEN 'Kitchen'
         WHEN i % 3 = 1 THEN 'Cleaning'
         ELSE 'Laundry' END AS category,
    (50 + random() * 1000)::DECIMAL(10,2) AS price,
    (1 + (random() * 50)::INT) AS stock_quantity 
FROM generate_series(1, 6) AS s(i)
ON CONFLICT DO NOTHING;

INSERT INTO household_store.customers (first_name, last_name, email, phone, address)
SELECT 
    'FirstName' || i,
    'LastName' || i,
    'customer' || i || '@example.com',
    '+7701' || (1000000 + i) AS phone,
    i || ' Example St, City'
FROM generate_series(1, 6) AS s(i)
ON CONFLICT DO NOTHING;


INSERT INTO household_store.employees (first_name, last_name, position, email, phone)
SELECT 
    'EmployeeFirst' || i,
    'EmployeeLast' || i,
    CASE WHEN i % 3 = 0 THEN 'Sales Manager'
         WHEN i % 3 = 1 THEN 'Cashier'
         ELSE 'Technician' END,
    'employee' || i || '@company.com',
    '+7702' || (1000000 + i)
FROM generate_series(1, 6) AS s(i)
ON CONFLICT DO NOTHING;


INSERT INTO household_store.suppliers (name, contact_name, phone, email, address)
SELECT
    'Supplier ' || i,
    'Contact ' || i,
    '+7703' || (1000000 + i),
    'supplier' || i || '@mail.com',
    i || ' Supplier Rd, City'
FROM generate_series(1, 6) AS s(i)
ON CONFLICT DO NOTHING;


INSERT INTO household_store.orders (order_date, customer_id, employee_id, status, total_amount)
SELECT
    CURRENT_DATE - ((random() * 90)::INT) AS order_date,
    c.customer_id,
    e.employee_id,
    CASE WHEN random() < 0.25 THEN 'Pending'
         WHEN random() < 0.5 THEN 'Shipped'
         WHEN random() < 0.75 THEN 'Delivered'
         ELSE 'Cancelled' END AS status,
    0 
FROM household_store.customers c
JOIN household_store.employees e ON random() < 0.5
LIMIT 6
ON CONFLICT DO NOTHING;


INSERT INTO household_store.order_details (order_id, product_id, quantity, price_each)
SELECT
    o.order_id,
    p.product_id,
    (1 + (random() * 5)::INT) AS quantity, 
    p.price 
FROM household_store.orders o
JOIN household_store.products p ON random() < 0.5
LIMIT 6
ON CONFLICT DO NOTHING;


INSERT INTO household_store.product_suppliers (product_id, supplier_id, supply_price)
SELECT
    p.product_id,
    s.supplier_id,
    (p.price * (0.5 + random() * 0.5))::DECIMAL(10,2)
FROM household_store.products p
JOIN household_store.suppliers s ON random() < 0.5
LIMIT 6
ON CONFLICT DO NOTHING;


--Functions
--Update Function
CREATE OR REPLACE FUNCTION household_store.update_product_column(
    p_product_id INT,
    p_column_name TEXT,
    p_new_value TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    EXECUTE format(
        'UPDATE household_store.products SET %I = %L WHERE product_id = %L',
        p_column_name,
        p_new_value,
        p_product_id
    );
END;
$$;

--Test
--SELECT household_store.update_product_column(2, 'price', '1000.00');
--SELECT * FROM household_store.products;

--INSERT Function
CREATE OR REPLACE FUNCTION household_store.add_order(
    p_customer_id INT,
    p_employee_id INT,
    p_status VARCHAR,
    p_order_date DATE DEFAULT CURRENT_DATE,
    p_total_amount DECIMAL DEFAULT 0
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO household_store.orders (
        customer_id,
        employee_id,
        status,
        order_date,
        total_amount
    )
    VALUES (
        p_customer_id,
        p_employee_id,
        p_status,
        p_order_date,
        p_total_amount
    );
    RETURN 'Order successfully added';
END;
$$;

--Test
SELECT household_store.add_order(
    3,
    1,
    'Shipped'
);
SELECT * FROM household_store.orders;


--View
CREATE OR REPLACE VIEW household_store.quarterly_sales_analytics AS
WITH latest_quarter AS (
    SELECT
        EXTRACT(YEAR FROM order_date) AS year,
        EXTRACT(QUARTER FROM order_date) AS quarter
    FROM household_store.orders
    ORDER BY order_date DESC
    LIMIT 1
)
SELECT DISTINCT
    c.full_name AS customer_name,
    e.full_name AS employee_name,
    p.name AS product_name,
    od.quantity,
    od.quantity * od.price_each AS total_price,
    o.status AS order_status,
    o.order_date
FROM household_store.orders o
INNER JOIN household_store.customers c ON o.customer_id = c.customer_id
INNER JOIN household_store.employees e ON o.employee_id = e.employee_id
INNER JOIN household_store.order_details od ON o.order_id = od.order_id
INNER JOIN household_store.products p ON od.product_id = p.product_id
INNER JOIN latest_quarter lq
	ON EXTRACT(YEAR FROM o.order_date) = lq.year
	AND EXTRACT(QUARTER FROM o.order_date) = lq.quarter
ORDER BY o.order_date DESC, c.full_name, p.name;

SELECT * FROM household_store.quarterly_sales_analytics;

--Role
CREATE ROLE manager_ro
LOGIN
PASSWORD 'Secure123';

GRANT USAGE ON SCHEMA household_store TO manager_ro;

GRANT SELECT ON ALL TABLES IN SCHEMA household_store TO manager_ro;

ALTER DEFAULT PRIVILEGES IN SCHEMA household_store
GRANT SELECT ON TABLES TO manager_ro;