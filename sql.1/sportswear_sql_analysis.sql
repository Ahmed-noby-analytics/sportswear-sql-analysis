/* ------------------------------------------------------------
   Project: Sportswear Store SQL Analysis
   Description: Synthetic sales data (4 CSV files) loaded into a
   SQLite database. This script creates the tables, checks the data,
   and answers 8 business questions aimed at increasing profit.
   Profit = Revenue - Cost, on Completed orders only.
------------------------------------------------------------- */


/* ============================
      1. CREATE TABLES
=============================== */

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id  INTEGER PRIMARY KEY,
    signup_date  DATE NOT NULL,
    city         TEXT,
    gender       TEXT,
    age_group    TEXT
);

CREATE TABLE products (
    product_id   INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category     TEXT NOT NULL,
    unit_price   REAL NOT NULL,
    unit_cost    REAL NOT NULL
);

CREATE TABLE orders (
    order_id       INTEGER PRIMARY KEY,
    customer_id    INTEGER NOT NULL REFERENCES customers(customer_id),
    order_date     DATE NOT NULL,
    channel        TEXT,
    payment_method TEXT,
    order_status   TEXT,
    discount_pct   INTEGER
);

CREATE TABLE order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id      INTEGER NOT NULL REFERENCES orders(order_id),
    product_id    INTEGER NOT NULL REFERENCES products(product_id),
    quantity      INTEGER NOT NULL,
    unit_price    REAL NOT NULL
);


/* ============================
      2. IMPORT DATA
=============================== */

-- The four CSV files in the data folder were loaded into the tables above
-- (for example with pandas to_sql, or Import Table from CSV in DB Browser for SQLite).
-- Load order: customers, products, orders, order_items.


/* ============================
      3. DATA CHECKS
=============================== */

-- Check 1: number of rows in each table
SELECT 'customers' AS table_name, COUNT(*) AS total_rows FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items;


-- Check 2: customers with a missing city
SELECT COUNT(*) AS customers_missing_city
FROM customers
WHERE city IS NULL;


-- Check 3: orders by status
SELECT order_status, COUNT(*) AS orders
FROM orders
GROUP BY order_status;


/* ============================
      4. SALES VIEW
=============================== */

-- One row per order item, with revenue and cost calculated.
-- Revenue = quantity x unit_price x (1 - discount). Cost = quantity x unit_cost.
CREATE VIEW v_sales AS
SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    strftime('%Y-%m', o.order_date) AS order_month,
    o.channel,
    o.payment_method,
    o.order_status,
    o.discount_pct,
    p.product_name,
    p.category,
    oi.quantity,
    oi.quantity * oi.unit_price * (1 - o.discount_pct / 100.0) AS revenue,
    oi.quantity * p.unit_cost AS cost
FROM order_items oi
JOIN orders o   ON o.order_id   = oi.order_id
JOIN products p ON p.product_id = oi.product_id;


/* ============================
      5. BUSINESS QUESTIONS
=============================== */

-- Q1) Which categories bring the highest profit and the best margin?
SELECT category,
       ROUND(SUM(revenue)) AS revenue,
       ROUND(SUM(revenue - cost)) AS profit,
       ROUND(100.0 * SUM(revenue - cost) / SUM(revenue), 1) AS margin_pct
FROM v_sales
WHERE order_status = 'Completed'
GROUP BY category
ORDER BY profit DESC;


-- Q2a) Top 10 products by profit
SELECT product_name,
       category,
       SUM(quantity) AS units_sold,
       ROUND(SUM(revenue - cost)) AS profit,
       ROUND(100.0 * SUM(revenue - cost) / SUM(revenue), 1) AS margin_pct
FROM v_sales
WHERE order_status = 'Completed'
GROUP BY product_name, category
ORDER BY profit DESC
LIMIT 10;


-- Q2b) Bottom 5 products by profit
SELECT product_name,
       category,
       SUM(quantity) AS units_sold,
       ROUND(SUM(revenue - cost)) AS profit,
       ROUND(100.0 * SUM(revenue - cost) / SUM(revenue), 1) AS margin_pct
FROM v_sales
WHERE order_status = 'Completed'
GROUP BY product_name, category
ORDER BY profit ASC
LIMIT 5;


-- Q3) Monthly revenue, profit and margin (seasonality)
SELECT order_month,
       COUNT(DISTINCT order_id) AS orders,
       ROUND(SUM(revenue)) AS revenue,
       ROUND(SUM(revenue - cost)) AS profit,
       ROUND(100.0 * SUM(revenue - cost) / SUM(revenue), 1) AS margin_pct
FROM v_sales
WHERE order_status = 'Completed'
GROUP BY order_month
ORDER BY order_month;


-- Q3b) Are November orders discounted more than other months?
SELECT CASE WHEN strftime('%m', order_date) = '11' THEN 'November' ELSE 'Other months' END AS period,
       COUNT(*) AS orders,
       ROUND(100.0 * SUM(CASE WHEN discount_pct > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS discounted_orders_pct
FROM orders
WHERE order_status = 'Completed'
GROUP BY period;


-- Q4) Top 10 customers by amount spent
SELECT customer_id,
       COUNT(DISTINCT order_id) AS orders,
       ROUND(SUM(revenue)) AS amount_spent,
       ROUND(SUM(revenue - cost)) AS profit
FROM v_sales
WHERE order_status = 'Completed'
GROUP BY customer_id
ORDER BY amount_spent DESC
LIMIT 10;


-- Q5) How does the discount level affect margin and profit?
SELECT discount_pct,
       COUNT(DISTINCT order_id) AS orders,
       ROUND(SUM(revenue - cost)) AS profit,
       ROUND(100.0 * SUM(revenue - cost) / SUM(revenue), 1) AS margin_pct
FROM v_sales
WHERE order_status = 'Completed'
GROUP BY discount_pct
ORDER BY discount_pct;


-- Q6a) Orders by payment method and status (cancelled and returned)
SELECT payment_method,
       order_status,
       COUNT(*) AS orders
FROM orders
GROUP BY payment_method, order_status
ORDER BY payment_method, order_status;


-- Q6b) Revenue by order status (how much revenue is lost)
SELECT order_status,
       ROUND(SUM(revenue)) AS revenue
FROM v_sales
GROUP BY order_status;


-- Q7) Which cities bring the highest profit?
SELECT LOWER(c.city) AS city,
       COUNT(DISTINCT s.order_id) AS orders,
       ROUND(SUM(s.revenue - s.cost)) AS profit
FROM v_sales s
JOIN customers c ON c.customer_id = s.customer_id
WHERE s.order_status = 'Completed'
  AND c.city IS NOT NULL
GROUP BY LOWER(c.city)
ORDER BY profit DESC;


-- Q8) Online vs Store
SELECT channel,
       COUNT(DISTINCT order_id) AS orders,
       ROUND(SUM(revenue)) AS revenue,
       ROUND(SUM(revenue - cost)) AS profit
FROM v_sales
WHERE order_status = 'Completed'
GROUP BY channel
ORDER BY profit DESC;
