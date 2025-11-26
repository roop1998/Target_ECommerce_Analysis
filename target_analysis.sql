-- ======================================================
-- target_analysis.sql
-- PostgreSQL-ready analysis for Target Brazil (2016-2018)
-- ======================================================
-- How to use:
-- 1) Create a new Postgres DB (or use your local instance).
-- 2) Place your CSVs in a folder on the machine that runs Postgres.
-- 3) Uncomment and update the COPY commands below with the CSV paths.
-- 4) Run this file (psql -f target_analysis.sql) or paste sections into your SQL editor.
--
-- NOTE: geolocation.csv is optional and intentionally omitted (file was >25MB).
-- ======================================================

-- ======================================================
-- 1) TABLE DEFINITIONS
-- ======================================================

CREATE TABLE IF NOT EXISTS customers (
  customer_id               VARCHAR PRIMARY KEY,
  customer_unique_id        VARCHAR,
  customer_zip_code_prefix  INTEGER,
  customer_city             VARCHAR,
  customer_state            VARCHAR
);

CREATE TABLE IF NOT EXISTS sellers (
  seller_id                 VARCHAR PRIMARY KEY,
  seller_zip_code_prefix    INTEGER,
  seller_city               VARCHAR,
  seller_state              VARCHAR
);

CREATE TABLE IF NOT EXISTS products (
  product_id                VARCHAR PRIMARY KEY,
  product_category          VARCHAR,
  product_name_length       INTEGER,
  product_description_length INTEGER,
  product_photos_qty        INTEGER,
  product_weight_g          INTEGER,
  product_length_cm         INTEGER,
  product_height_cm         INTEGER,
  product_width_cm          INTEGER
);

CREATE TABLE IF NOT EXISTS orders (
  order_id                      VARCHAR PRIMARY KEY,
  customer_id                   VARCHAR,
  order_status                  VARCHAR,
  order_purchase_timestamp      TIMESTAMP,
  order_approved_at             TIMESTAMP,
  order_delivered_carrier_date  TIMESTAMP,
  order_delivered_customer_date TIMESTAMP,
  order_estimated_delivery_date TIMESTAMP
);

CREATE TABLE IF NOT EXISTS order_items (
  order_id          VARCHAR,
  order_item_id     INTEGER,
  product_id        VARCHAR,
  seller_id         VARCHAR,
  shipping_limit_date TIMESTAMP,
  price             NUMERIC,
  freight_value     NUMERIC
);

CREATE TABLE IF NOT EXISTS payments (
  order_id             VARCHAR,
  payment_sequential   INTEGER,
  payment_type         VARCHAR,
  payment_installments INTEGER,
  payment_value        NUMERIC
);

CREATE TABLE IF NOT EXISTS order_reviews (
  review_id              VARCHAR PRIMARY KEY,
  order_id               VARCHAR,
  review_score           INTEGER,
  review_comment_title   TEXT,
  review_creation_date   TIMESTAMP,
  review_answer_timestamp TIMESTAMP
);

-- ======================================================
-- 2) LOAD CSVs (UNCOMMENT and set correct absolute paths)
-- ======================================================
-- Example (on Linux/macOS). Replace /full/path/to/ with your path:
-- COPY customers FROM '/full/path/to/data/customers.csv' WITH (FORMAT csv, HEADER true);
-- COPY sellers FROM '/full/path/to/data/sellers.csv' WITH (FORMAT csv, HEADER true);
-- COPY products FROM '/full/path/to/data/products.csv' WITH (FORMAT csv, HEADER true);
-- COPY orders FROM '/full/path/to/data/orders.csv' WITH (FORMAT csv, HEADER true);
-- COPY order_items FROM '/full/path/to/data/order_items.csv' WITH (FORMAT csv, HEADER true);
-- COPY payments FROM '/full/path/to/data/payments.csv' WITH (FORMAT csv, HEADER true);
-- COPY order_reviews FROM '/full/path/to/data/order_reviews.csv' WITH (FORMAT csv, HEADER true);

-- ======================================================
-- 3) QUICK CHECKS & EXPLORATORY QUERIES
-- ======================================================

/*
  3.1 Data types for customers table (schema confirmation)
  Recruiter: This shows columns / types for customers.
*/
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'customers'
ORDER BY ordinal_position;

/*
  3.2 Time range of orders
  Expected output: first_order (earliest) and last_order (latest)
  Insight (from your run): first order ~ 2016-09-04, last order ~ 2018-10-17
*/
SELECT MIN(order_purchase_timestamp) AS first_order,
       MAX(order_purchase_timestamp) AS latest_order
FROM orders;

/*
  3.3 Distinct counts: cities & states
  Shows number of unique cities and states where customers placed orders.
*/
SELECT COUNT(DISTINCT customer_city)  AS total_unique_cities,
       COUNT(DISTINCT customer_state) AS total_unique_states
FROM customers;

-- Show 10 sample cities and states (for recruiter to eyeball)
SELECT DISTINCT customer_city FROM customers LIMIT 10;
SELECT DISTINCT customer_state FROM customers LIMIT 10;

-- ======================================================
-- 4) IN-DEPTH EXPLORATION: TRENDS & SEASONALITY
-- ======================================================

/*
  4.1 Growing trend: orders per year
  Insight: use this to show whether year-over-year orders increased.
*/
SELECT EXTRACT(YEAR FROM order_purchase_timestamp)::INT AS year,
       COUNT(DISTINCT order_id) AS orders_count
FROM orders
GROUP BY 1
ORDER BY 1;

/*
  4.2 Monthly seasonality: orders per month across all years
  Useful to plot monthly trends (year_month).
*/
SELECT to_char(order_purchase_timestamp, 'YYYY-MM') AS year_month,
       COUNT(DISTINCT order_id) AS orders_count
FROM orders
GROUP BY 1
ORDER BY 1;

/*
  4.3 Time of day distribution
  Map hour -> Dawn / Morning / Afternoon / Night as per problem statement:
    0-6   -> Dawn
    7-12  -> Morning
    13-18 -> Afternoon
    19-23 -> Night
  Insight: peak ordering hours are 10–17 (approx).
*/
SELECT
  CASE
    WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 0 AND 6 THEN 'Dawn'
    WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 7 AND 12 THEN 'Morning'
    WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 13 AND 18 THEN 'Afternoon'
    ELSE 'Night'
  END AS time_of_day,
  COUNT(DISTINCT order_id) AS orders_count
FROM orders
GROUP BY time_of_day
ORDER BY orders_count DESC;

-- Optional: exact hour counts (to reproduce your hour table)
SELECT EXTRACT(HOUR FROM order_purchase_timestamp) AS hour,
       COUNT(DISTINCT order_id) AS orders_count
FROM orders
GROUP BY hour
ORDER BY orders_count DESC;

-- ======================================================
-- 5) EVOLUTION BY STATE (month-on-month)
-- ======================================================

/*
  5.1 Month-on-month orders by state (useful for map + small-multiples)
  Recruiter: will see which states drive volume each month; SP expected to dominate.
*/
SELECT to_char(o.order_purchase_timestamp,'YYYY-MM') AS year_month,
       c.customer_state,
       COUNT(DISTINCT o.order_id) AS orders_count
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY 1,2
ORDER BY 1, 3 DESC;

/*
  5.2 Customer distribution across states (number of distinct customers)
  Insight: SP highest, RR smallest.
*/
SELECT customer_state,
       COUNT(DISTINCT customer_id) AS n_customers
FROM customers
GROUP BY customer_state
ORDER BY n_customers DESC;

-- ======================================================
-- 6) IMPACT ON ECONOMY: MONEY MOVEMENT (2017 vs 2018 Jan–Aug)
-- ======================================================

/*
  6.1 % increase in payment_value from 2017 -> 2018 for months Jan–Aug.
  - We compute monthly totals for 2017 and 2018 (Jan–Aug) and show percent change.
*/
WITH payments_2017 AS (
  SELECT EXTRACT(MONTH FROM o.order_purchase_timestamp)::INT AS month,
         SUM(p.payment_value)::NUMERIC AS total_2017
  FROM payments p
  JOIN orders o ON p.order_id = o.order_id
  WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2017
    AND EXTRACT(MONTH FROM o.order_purchase_timestamp) BETWEEN 1 AND 8
  GROUP BY 1
),
payments_2018 AS (
  SELECT EXTRACT(MONTH FROM o.order_purchase_timestamp)::INT AS month,
         SUM(p.payment_value)::NUMERIC AS total_2018
  FROM payments p
  JOIN orders o ON p.order_id = o.order_id
  WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018
    AND EXTRACT(MONTH FROM o.order_purchase_timestamp) BETWEEN 1 AND 8
  GROUP BY 1
)
SELECT p17.month,
       p17.total_2017,
       p18.total_2018,
       (p18.total_2018 - p17.total_2017) AS diff_value,
       ROUND( (p18.total_2018 - p17.total_2017) * 100.0 / NULLIF(p17.total_2017,0), 2) AS pct_change
FROM payments_2017 p17
JOIN payments_2018 p18 USING (month)
ORDER BY p17.month;

/*
  6.2 Total & average order payment value per state
  Use payments -> orders -> customers join to map payment values to states.
*/
SELECT c.customer_state,
       COUNT(DISTINCT o.order_id) AS n_orders,
       ROUND(SUM(p.payment_value),2) AS total_payment,
       ROUND(AVG(p.payment_value),2) AS avg_payment
FROM payments p
JOIN orders o ON p.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY total_payment DESC;

/*
  6.3 Total & average freight value per state
  Use order_items -> orders -> customers join.
*/
SELECT c.customer_state,
       COUNT(oi.order_id) AS n_items,
       ROUND(SUM(oi.freight_value),2) AS total_freight,
       ROUND(AVG(oi.freight_value),2) AS avg_freight
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY total_freight DESC;

-- ======================================================
-- 7) SALES, FREIGHT & DELIVERY TIME ANALYSIS (single-query delivery metrics)
-- ======================================================

/*
  7.1 For each order, compute:
    - time_to_deliver_days = order_delivered_customer_date - order_purchase_timestamp (in days)
    - diff_estimated_delivery_days = order_delivered_customer_date - order_estimated_delivery_date (in days)
  NOTE: we compute days as round(extract(epoch ...)/86400)
*/
SELECT
  order_id,
  order_purchase_timestamp,
  order_delivered_customer_date,
  order_estimated_delivery_date,
  ROUND(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp))/86400,2) AS time_to_deliver_days,
  ROUND(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_estimated_delivery_date))/86400,2) AS diff_estimated_delivery_days
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
LIMIT 100;

/*
  7.2 Top 5 states with highest & lowest average freight value
*/
WITH state_freight AS (
  SELECT c.customer_state,
         AVG(oi.freight_value) AS avg_freight
  FROM order_items oi
  JOIN orders o ON oi.order_id = o.order_id
  JOIN customers c ON o.customer_id = c.customer_id
  GROUP BY c.customer_state
)
SELECT * FROM state_freight ORDER BY avg_freight DESC LIMIT 5;
SELECT * FROM state_freight ORDER BY avg_freight ASC LIMIT 5;

/*
  7.3 Top 5 states with highest & lowest average delivery time (purchase -> actual delivered)
*/
WITH state_delivery AS (
  SELECT c.customer_state,
         AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))/86400) AS avg_delivery_days
  FROM orders o
  JOIN customers c ON o.customer_id = c.customer_id
  WHERE o.order_delivered_customer_date IS NOT NULL
  GROUP BY c.customer_state
)
SELECT * FROM state_delivery ORDER BY avg_delivery_days DESC LIMIT 5;
SELECT * FROM state_delivery ORDER BY avg_delivery_days ASC LIMIT 5;

/*
  7.4 Top 5 states where delivery is faster than estimate
  Here avg_diff = avg(order_delivered_customer_date - order_estimated_delivery_date)
  Negative avg_diff => delivered earlier than estimated on average (faster).
*/
WITH state_diff AS (
  SELECT c.customer_state,
         AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date))/86400) AS avg_diff_days
  FROM orders o
  JOIN customers c ON o.customer_id = c.customer_id
  WHERE o.order_delivered_customer_date IS NOT NULL AND o.order_estimated_delivery_date IS NOT NULL
  GROUP BY c.customer_state
)
-- fastest (most negative avg_diff_days)
SELECT * FROM state_diff ORDER BY avg_diff_days ASC LIMIT 5;
-- slowest (most positive avg_diff_days)
SELECT * FROM state_diff ORDER BY avg_diff_days DESC LIMIT 5;

-- ======================================================
-- 8) PAYMENTS ANALYSIS
-- ======================================================

/*
  8.1 Month-on-month number of orders by payment type
*/
SELECT to_char(o.order_purchase_timestamp,'YYYY-MM') AS year_month,
       p.payment_type,
       COUNT(DISTINCT o.order_id) AS orders_count
FROM payments p
JOIN orders o ON p.order_id = o.order_id
GROUP BY 1,2
ORDER BY 1, orders_count DESC;

/*
  8.2 Number of orders by payment_installments
  Insight: most customers pay in 1 installment; long installment counts are rare.
*/
SELECT p.payment_installments,
       COUNT(DISTINCT p.order_id) AS n_orders
FROM payments p
GROUP BY p.payment_installments
ORDER BY n_orders DESC;

-- ======================================================
-- END OF FILE
-- ======================================================
