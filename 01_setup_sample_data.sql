-- =====================================================================
-- 01 SETUP: DDL (Data Definition Language) + sample data
-- Run inside:  CREATE DATABASE shop_db;  \c shop_db
-- =====================================================================

-- Clean start (safe to re-run). CASCADE also drops dependent objects.
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders      CASCADE;
DROP TABLE IF EXISTS products    CASCADE;
DROP TABLE IF EXISTS categories  CASCADE;
DROP TABLE IF EXISTS customers   CASCADE;

-- ---------------------------------------------------------------------
-- COMMON DATA TYPES
--   INTEGER / BIGINT / SMALLINT       whole numbers
--   NUMERIC(10,2)                     exact decimals (USE FOR MONEY, never FLOAT)
--   REAL / DOUBLE PRECISION           approximate decimals
--   VARCHAR(n) / TEXT                 text (TEXT = unlimited)
--   BOOLEAN                           TRUE / FALSE
--   DATE / TIME / TIMESTAMP / TIMESTAMPTZ   dates and times
--   UUID, JSONB, ARRAY                special types
-- ---------------------------------------------------------------------

-- CONSTRAINTS keep data valid:
--   PRIMARY KEY  unique + not null row identifier
--   FOREIGN KEY  link to another table's primary key
--   NOT NULL     value required
--   UNIQUE       no duplicates
--   CHECK        custom rule
--   DEFAULT      value used when none given

CREATE TABLE customers (
    customer_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name   VARCHAR(50)  NOT NULL,
    last_name    VARCHAR(50)  NOT NULL,
    email        VARCHAR(120) NOT NULL UNIQUE,
    city         VARCHAR(60),
    country      VARCHAR(60)  NOT NULL DEFAULT 'Uganda',
    created_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categories (
    category_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name         VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE products (
    product_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    category_id  INTEGER REFERENCES categories(category_id) ON DELETE SET NULL,
    price        NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    stock        INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    is_active    BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE orders (
    order_id     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id  INTEGER NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    order_date   DATE NOT NULL DEFAULT CURRENT_DATE,
    status       VARCHAR(20) NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending','paid','shipped','delivered','cancelled'))
);

-- Junction table: resolves the many-to-many between orders and products
CREATE TABLE order_items (
    order_id    INTEGER NOT NULL REFERENCES orders(order_id)     ON DELETE CASCADE,
    product_id  INTEGER NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
    quantity    INTEGER NOT NULL CHECK (quantity > 0),
    unit_price  NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (order_id, product_id)          -- composite primary key
);

-- ---------------------------------------------------------------------
-- SAMPLE DATA
-- ---------------------------------------------------------------------
INSERT INTO customers (first_name, last_name, email, city, country) VALUES
('Amina',  'Nakato',  'amina@example.com',  'Kampala', 'Uganda'),
('Brian',  'Okello',  'brian@example.com',  'Mukono',  'Uganda'),
('Cynthia','Mugisha', 'cynthia@example.com','Entebbe', 'Uganda'),
('David',  'Kamau',   'david@example.com',  'Nairobi', 'Kenya'),
('Esther', 'Mwangi',  'esther@example.com', 'Nairobi', 'Kenya'),
('Fatuma', 'Juma',    'fatuma@example.com', 'Dar es Salaam', 'Tanzania'),
('Grace',  'Auma',    'grace@example.com',  NULL,      'Uganda');   -- NULL city on purpose

INSERT INTO categories (name) VALUES
('Electronics'), ('Books'), ('Clothing'), ('Home'), ('Toys');       -- Toys has no products on purpose

INSERT INTO products (name, category_id, price, stock, is_active) VALUES
('Wireless Mouse',      1,  45000.00, 50, TRUE),
('USB-C Charger',       1,  60000.00, 30, TRUE),
('Mechanical Keyboard', 1, 180000.00, 10, TRUE),
('SQL Made Easy',       2,  75000.00, 25, TRUE),
('Python Crash Course', 2,  95000.00, 15, TRUE),
('T-Shirt',             3,  30000.00, 100, TRUE),
('Hoodie',              3,  85000.00, 40, TRUE),
('Desk Lamp',           4,  55000.00, 20, TRUE),
('Old Phone Case',      1,   5000.00,  0, FALSE);

INSERT INTO orders (customer_id, order_date, status) VALUES
(1, '2026-01-10', 'delivered'),
(1, '2026-02-14', 'paid'),
(2, '2026-02-20', 'shipped'),
(3, '2026-03-05', 'delivered'),
(4, '2026-03-18', 'cancelled'),
(5, '2026-04-01', 'pending'),
(1, '2026-04-12', 'delivered');
-- Customers 6 and 7 have never ordered (on purpose, for LEFT JOIN practice)

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 2,  45000.00),
(1, 4, 1,  75000.00),
(2, 3, 1, 180000.00),
(3, 6, 3,  30000.00),
(3, 7, 1,  85000.00),
(4, 5, 2,  95000.00),
(5, 2, 1,  60000.00),
(6, 8, 1,  55000.00),
(7, 1, 1,  45000.00),
(7, 6, 2,  30000.00);

-- Quick check
SELECT 'customers' AS tbl, COUNT(*) FROM customers
UNION ALL SELECT 'products',    COUNT(*) FROM products
UNION ALL SELECT 'orders',      COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items;
