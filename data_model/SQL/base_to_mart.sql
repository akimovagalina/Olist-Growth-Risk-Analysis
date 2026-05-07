-------------------------------------------------------------------------------------------
----------------------------------------MART TABLES----------------------------------------
-------------------------------------------------------------------------------------------
-- Revenue dinamic
CREATE OR REPLACE TABLE metal-appliance-483807-n7.olist_mart.mart_monthly_revenue_growth AS
 WITH month_revenue AS (
    SELECT 
    month,
    ROUND(SUM(revenue),0) AS monthly_revenue
    FROM metal-appliance-483807-n7.olist_base.base_orders
    GROUP BY month
    ORDER BY month
    )
SELECT 
month,
monthly_revenue,
-- Month-over-Month
ROUND(monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month),2) AS mom_growth_abs,

ROUND(
    (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month))
    / NULLIF(LAG(monthly_revenue) OVER (ORDER BY month), 0),
    4) AS mom_growth_pct,

-- Year-over-Year
ROUND(monthly_revenue - LAG(monthly_revenue, 12) OVER (ORDER BY month),2) AS yoy_growth,

ROUND((monthly_revenue - LAG(monthly_revenue, 12) OVER (ORDER BY month))
    /NULLIF(LAG(monthly_revenue, 12) OVER (ORDER BY month), 0),
  2) AS yoy_growth_pct,

--MART 3 — Rolling Metrics
ROUND(AVG(monthly_revenue)  OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 
2) AS rolling_3m_revenue,

ROUND(AVG(monthly_revenue) OVER (ORDER BY month ROWS BETWEEN 5 PRECEDING AND CURRENT ROW),
2) AS rolling_6m_revenue

  FROM
  month_revenue
;
--------------------------CUSTOMERS--------------------------------------------------
-- determine the first_order_date,orders_count,lifetime_revenue,avg_order_value,life_time_days by customer_id
CREATE OR REPLACE TABLE metal-appliance-483807-n7.olist_mart.mart_customer_ltv AS
  SELECT
    customer_id,
    MIN(order_date) AS first_order_date,
    COUNT(*) AS orders_count,
    ROUND(SUM(revenue), 2) AS lifetime_revenue,
    ROUND(AVG(revenue), 2) AS avg_order_value,
    DATE_DIFF(MAX(order_date), MIN(order_date), DAY) AS life_time_days
  FROM metal-appliance-483807-n7.olist_base.base_orders
  GROUP BY customer_id
;

--map of orders be geolocation of customers
CREATE OR REPLACE TABLE metal-appliance-483807-n7.olist_mart.mart_customer_geo AS
WITH mart_customer_ltv AS (
  SELECT
  customer_id,
  customer_zip_code_prefix,
  customer_city,
  customer_state,
  MIN(order_date) AS first_order_date,
  COUNT(*) AS orders_count,
  ROUND(SUM(revenue), 2) AS lifetime_revenue,
  ROUND(AVG(revenue), 2) AS avg_order_value,
  DATE_DIFF(MAX(order_date), MIN(order_date), DAY) AS life_time_days
  FROM metal-appliance-483807-n7.olist_base.base_orders
  GROUP BY ALL
)
SELECT
m.customer_id,
m.lifetime_revenue,
m.customer_zip_code_prefix,
m.customer_city,
m.customer_state,
NTILE(4) OVER (ORDER BY lifetime_revenue) as quantile
FROM mart_customer_ltv m
LEFT JOIN metal-appliance-483807-n7.olist_raw.customers c USING(customer_id)
;

--------------------------SELLERS--------------------------------------------------
-- arrange the companies in descending order of their profits and calculate the cumulative percentage of profit and the number of sellers
CREATE OR REPLACE TABLE metal-appliance-483807-n7.olist_mart.mart_seller AS
WITH seller_revenue AS (
  SELECT
    oi.seller_id,
    SUM(oi.price) AS revenue
  FROM metal-appliance-483807-n7.olist_base.base_order_items oi
  GROUP BY oi.seller_id
)
  SELECT
    seller_id,
    revenue AS seller_revenue,
    ROUND(COUNT(seller_id) OVER (ORDER BY revenue DESC)/COUNT(seller_id) OVER (),2) AS cumulative_seller_share,
    ROUND(SUM(revenue) OVER (ORDER BY revenue DESC)/ SUM(revenue) OVER (),2) AS cumulative_share
  FROM seller_revenue
;
--map of orders be geolocation of sellers
CREATE OR REPLACE TABLE metal-appliance-483807-n7.olist_mart.mart_seller_geo_items AS
SELECT
  oi.order_id,
  oi.order_item_id,
  oi.seller_id,
  oi.price,
  oi.seller_state,
  oi.seller_zip_code_prefix,
  oi.seller_city
FROM metal-appliance-483807-n7.olist_base.base_order_items oi
;
--------------------------------------------------------------------------
--------------------------PRODUCTS-------------------------------------------------
-- determine which areas bring in the most revenue
CREATE OR REPLACE TABLE metal-appliance-483807-n7.olist_mart.mart_product_level_revenue AS
SELECT 
month,
product_category_name,
seller_revenue,
NTILE(10) OVER (PARTITION BY month ORDER BY seller_revenue) as level
FROM
(
SELECT
month,
product_category_name,
ROUND(SUM(price),2) AS seller_revenue,
ROUND((SUM(price) / SUM(SUM(price)) OVER (PARTITION BY month)),2) AS revenue_index
FROM `metal-appliance-483807-n7.olist_base.base_order_items`
GROUP BY product_category_name, month
ORDER BY  month 
) as a
;

--------------------------REVIEWS and DELIVERY--------------------------------
-- -- determine delay time of orders
CREATE OR REPLACE TABLE metal-appliance-483807-n7.olist_mart.mart_delay_table AS 
  SELECT 
  order_id,
  review_score,
  delivery_delay_days,
  CASE WHEN delivery_delay_days<0 THEN 'Early'
  WHEN delivery_delay_days>0 THEN 'Late'
  ELSE 'At time' End AS delivery_time_estimate
  FROM `metal-appliance-483807-n7.olist_base.base_rev_delays`
  WHERE order_delivered_customer_date IS NOT NULL
;
