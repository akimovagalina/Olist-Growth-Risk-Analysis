-------------------------------------------------------------------------------------------
----------------------------------------BASE TABLES----------------------------------------
-------------------------------------------------------------------------------------------
-- orders items where order_id has a satus='delivery' in table orders
CREATE OR REPLACE TABLE metal-appliance-483807-n7.olist_base.base_order_items AS
SELECT
  oi.order_id,
  oi.order_item_id,
  oi.product_id,
  oi.seller_id,
  oi.price,
  o.order_status,
  date(o.order_purchase_timestamp) AS order_date,
  DATE_TRUNC(o.order_purchase_timestamp, month) AS month,
  s.seller_zip_code_prefix,
  s.seller_city,
  s.seller_state,
  p.product_category_name
FROM metal-appliance-483807-n7.olist_raw.order_items oi
INNER JOIN metal-appliance-483807-n7.olist_raw.orders o USING(order_id)
LEFT JOIN metal-appliance-483807-n7.olist_raw.sellers s USING(seller_id)
LEFT JOIN metal-appliance-483807-n7.olist_raw.products p USING(product_id)
WHERE o.order_status='delivered'
AND o.order_purchase_timestamp >= '2017-01-01'
;

-- payment by order_id
CREATE OR REPLACE TABLE metal-appliance-483807-n7.olist_base.base_orders AS
SELECT
  o.customer_id,
  DATE(o.order_purchase_timestamp) order_date,
  DATE_TRUNC(o.order_purchase_timestamp, month) AS month,
  ROUND(SUM(payment_value),2) AS revenue,
  o.order_id,
  c.customer_zip_code_prefix,
  c.customer_city,
  c.customer_state
FROM metal-appliance-483807-n7.olist_raw.orders AS o
LEFT JOIN metal-appliance-483807-n7.olist_raw.order_payments p USING(order_id)
LEFT JOIN metal-appliance-483807-n7.olist_raw.customers c USING(customer_id)
WHERE o.order_status = 'delivered'
AND o.order_purchase_timestamp >= '2017-01-01'
GROUP BY ALL
;

-----reviews and deleys
CREATE OR REPLACE TABLE metal-appliance-483807-n7.olist_base.base_rev_delays AS
SELECT
  o.customer_id,
  r.review_score AS review_score,
  o.order_id,
  DATE(o.order_purchase_timestamp) order_date,
  order_delivered_customer_date,
  order_estimated_delivery_date,
  DATE_DIFF(
    order_delivered_customer_date,
    order_estimated_delivery_date,
    DAY
  ) AS delivery_delay_days
FROM metal-appliance-483807-n7.olist_raw.orders AS o
LEFT JOIN metal-appliance-483807-n7.olist_raw.review r USING (order_id)
WHERE o.order_status = 'delivered'
AND o.order_purchase_timestamp >= '2017-01-01'
GROUP BY ALL
;