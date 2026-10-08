# shop_db: Setup and Sample Data

A PostgreSQL script that builds a small online-shop database (`shop_db`) and fills it with sample data. It is designed for practising SQL: joins, aggregates, filtering, and constraints. The script is safe to re-run, because it drops and recreates every table first.

## Contents

| File | Purpose |
|------|---------|
| `01_setup_sample_data.sql` | Drops and recreates all tables, inserts sample data, and runs a row-count check |

## Quick Start

```bash
# 1. Create the database
psql -U postgres -c "CREATE DATABASE shop_db;"

# 2. Run the script against it
psql -U postgres -d shop_db -f 01_setup_sample_data.sql
```

Or, inside `psql`:

```sql
CREATE DATABASE shop_db;
\c shop_db
\i 01_setup_sample_data.sql
```

The last query in the script prints a row count per table. You should see:

| Table | Rows |
|-------|------|
| customers | 7 |
| products | 9 |
| orders | 7 |
| order_items | 10 |

(`categories` has 5 rows but isn't part of the final check.)

## Schema

```
customers ──< orders ──< order_items >── products >── categories
```

### `customers`
| Column | Type | Notes |
|--------|------|-------|
| `customer_id` | INTEGER, identity, PK | Auto-generated |
| `first_name`, `last_name` | VARCHAR(50) | Required |
| `email` | VARCHAR(120) | Required, unique |
| `city` | VARCHAR(60) | Optional |
| `country` | VARCHAR(60) | Required, defaults to `'Uganda'` |
| `created_at` | TIMESTAMP | Defaults to the current time |

### `categories`
| Column | Type | Notes |
|--------|------|-------|
| `category_id` | INTEGER, identity, PK | Auto-generated |
| `name` | VARCHAR(60) | Required, unique |

### `products`
| Column | Type | Notes |
|--------|------|-------|
| `product_id` | INTEGER, identity, PK | Auto-generated |
| `name` | VARCHAR(100) | Required |
| `category_id` | INTEGER, FK | → `categories`; set to `NULL` if the category is deleted |
| `price` | NUMERIC(10,2) | Required, must be >= 0 |
| `stock` | INTEGER | Defaults to 0, must be >= 0 |
| `is_active` | BOOLEAN | Defaults to `TRUE` |

### `orders`
| Column | Type | Notes |
|--------|------|-------|
| `order_id` | INTEGER, identity, PK | Auto-generated |
| `customer_id` | INTEGER, FK | → `customers`; orders are deleted if the customer is deleted |
| `order_date` | DATE | Defaults to today |
| `status` | VARCHAR(20) | One of `pending`, `paid`, `shipped`, `delivered`, `cancelled`. Defaults to `pending` |

### `order_items`
A junction table that links orders and products (a many-to-many relationship).

| Column | Type | Notes |
|--------|------|-------|
| `order_id` | INTEGER, FK | → `orders`; deleted with the order |
| `product_id` | INTEGER, FK | → `products`; a product that has been ordered **cannot be deleted** (`RESTRICT`) |
| `quantity` | INTEGER | Must be > 0 |
| `unit_price` | NUMERIC(10,2) | Price at the time of the order |

**Primary key:** the pair (`order_id`, `product_id`), so a product can appear only once per order.

## Foreign Key Behaviour

| Relationship | On delete |
|--------------|-----------|
| `orders.customer_id` → `customers` | `CASCADE` (the customer's orders are removed) |
| `order_items.order_id` → `orders` | `CASCADE` (items are removed with the order) |
| `order_items.product_id` → `products` | `RESTRICT` (blocks deleting an ordered product) |
| `products.category_id` → `categories` | `SET NULL` (product stays, category cleared) |

## Sample Data Highlights

The data includes a few deliberate edge cases for practising joins and `NULL` handling:

- **Customers 6 (Fatuma) and 7 (Grace) have no orders.** Good for `LEFT JOIN` and "customers who never ordered" queries.
- **Grace has a `NULL` city.** Good for `IS NULL` and `COALESCE`.
- **The `Toys` category has no products.** Good for finding empty categories.
- **"Old Phone Case" is inactive with 0 stock.** Good for filtering on `is_active` and `stock`.
- **Order statuses are mixed:** three delivered, plus one each of paid, shipped, cancelled, and pending, for filtering and grouping.
- **Customers come from three countries:** Uganda, Kenya, Tanzania.

## Example Practice Queries

```sql
-- Customers who have never placed an order
SELECT c.first_name, c.last_name
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;

-- Total value of each order
SELECT order_id, SUM(quantity * unit_price) AS total
FROM order_items
GROUP BY order_id
ORDER BY order_id;

-- Number of products per category (including empty ones)
SELECT cat.name, COUNT(p.product_id) AS products
FROM categories cat
LEFT JOIN products p ON p.category_id = cat.category_id
GROUP BY cat.name;
```

## Notes

- **Money uses `NUMERIC(10,2)`, never `FLOAT`,** so amounts are exact. Prices are in Ugandan shillings.
- `DROP TABLE ... CASCADE` at the top also removes any objects that depend on these tables (such as views), so be careful if you've built extras on top.
- `unit_price` is stored on each order item, so past orders keep their original price even if a product's price changes later.
- Order dates in the sample data fall between January and April 2026.
