Overview

This document describes the database schema for the Olist Marketplace analysis project. The structure is organized in three layers: RAW, BASE, and MART.
It includes the purpose of each table, key fields, and relationships between tables.

⸻

 RAW Layer

Source transactional tables from the Olist dataset. These tables contain the original, unprocessed data.

Table: orders

Column	Type	Description
order_id	string [PK]	Unique identifier of the order
customer_id	string	Customer who placed the order
order_delivered_carrier_date	timestamp	Date when order was delivered to carrier
order_delivered_customer_date	timestamp	Date when order was delivered to customer
order_approved_at	timestamp	Timestamp when order was approved
order_estimated_delivery_date	timestamp	Estimated delivery date
order_status	string	Status of the order (e.g., delivered, canceled)

Table: customers

Column	Type	Description
customer_id	string [PK]	Unique customer ID
customer_unique_id	string	Repeated customer ID across multiple orders
customer_zip_code_prefix	integer	Customer postal code
customer_city	string	Customer city
customer_state	string	Customer state

Table: order_items

Column	Type	Description
order_id	string	Associated order ID
order_item_id	int [PK]	Unique item ID within an order
product_id	string	Product identifier
seller_id	string	Seller who fulfilled the order
price	float	Item price

Table: order_payments

Column	Type	Description
order_id	string	Associated order ID
payment_sequential	integer	Sequence of payment (1,2,…)
payment_value	float	Payment amount
payment_type	string	Payment method
payment_installments	integer	Number of installments

Table: products

Column	Type	Description
product_id	string [PK]	Product identifier
product_category_name	string	Product category
product_name_length	integer	Length of product name
product_description_length	integer	Length of product description
product_photos_qty	integer	Number of product photos
product_weight_g	integer	Weight in grams
product_length_cm	integer	Length in cm
product_height_cm	integer	Height in cm
product_width_cm	integer	Width in cm

Table: sellers

Column	Type	Description
seller_id	string [PK]	Seller ID
seller_zip_code_prefix	integer	Seller postal code
seller_city	string	Seller city
seller_state	string	Seller state

Table: review

Column	Type	Description
review_id	string [PK]	Unique review ID
order_id	string	Associated order ID
review_score	int	Score given by customer (1–5)
review_creation_date	timestamp	Date of review creation
review_answer_timestamp	timestamp	Date of review response


⸻

 BASE Layer

Cleaned and structured tables with validated joins and derived fields. All date fields are normalized and revenue is calculated.

Table: base_order_items

Column	Type	Description
order_id	string [PK]	Order ID
order_item_id	int [PK]	Item ID within order
product_id	string	Product ID
seller_id	string	Seller ID
order_date	date	Date of purchase
month	date	Month of purchase (truncated)
product_category_name	string	Product category
price	float	Item price
order_status	string	Current order status
seller_zip_code_prefix	int	Seller postal code
seller_city	string	Seller city
seller_state	string	Seller state

Table: base_orders

Column	Type	Description
order_id	string	Order ID
customer_id	string	Customer ID
order_date	date	Date of purchase
month	date	Month of purchase
revenue	float	Total revenue for the order
customer_zip_code_prefix	integer	Customer postal code
customer_city	string	Customer city
customer_state	string	Customer state

Table: base_rev_delays

Column	Type	Description
order_id	string	Order ID
customer_id	string	Customer ID
order_date	date	Date of purchase
order_delivered_customer_date	date	Actual delivery date
order_estimated_delivery_date	date	Estimated delivery date
delivery_delay_days	integer	Difference between actual and estimated delivery
review_score	integer	Average review score for order


⸻

 MART Layer

Aggregated tables for business analytics and KPI dashboards.

Table: mart_monthly_revenue_growth

Monthly revenue and growth metrics.

Column	Type	Description
month	date	Month
monthly_revenue	float	Total revenue for month
mom_growth_pct	float	Month-over-month growth (%)
yoy_growth_pct	float	Year-over-year growth (%)
rolling_3m_revenue	float	3-month rolling revenue
rolling_6m_revenue	float	6-month rolling revenue

Table: mart_customer_ltv

Customer lifetime metrics.

Column	Type	Description
customer_id	string	Customer ID
first_order_date	date	First order date
orders_count	int	Total orders
lifetime_revenue	float	Sum of revenue
avg_order_value	float	Average order value

Table: mart_customer_geo

Customer distribution by geolocation and revenue quartiles.

Column	Type	Description
order_id	string	Order ID
customer_id	string	Customer ID
customer_city	string	Customer city
customer_state	string	Customer state
customer_zip_code_prefix	int	Postal code
quantile	int	Quartile by lifetime revenue

Table: mart_seller

Seller performance and cumulative revenue distribution.

Column	Type	Description
seller_id	string	Seller ID
seller_revenue	float	Total revenue per seller
cumulative_seller_share	float	Cumulative share of sellers
cumulative_revenue_share	float	Cumulative share of revenue

Table: mart_best_sellers

Top-performing sellers.

Column	Type	Description
seller_id	string	Seller ID
seller_revenue	float	Revenue
revenue_index	float	Revenue share index

Table: mart_product_category_revenue

Revenue per product category.

Column	Type	Description
product_category_name	string	Product category
seller_revenue	float	Total revenue
revenue_index	float	Relative revenue share

Table: mart_seller_geo_items

Order items mapped to seller geolocation.

Column	Type	Description
order_id	string	Order ID
order_item_id	int	Item ID
seller_id	string	Seller ID
price	float	Item price
seller_state	string	Seller state
seller_zip_code_prefix	int	Postal code
seller_city	string	City

Table: mart_product_level_revenue

Revenue by product category and month.

Column	Type	Description
month	date	Month
product_category_name	string	Product category
seller_revenue	float	Total revenue
level	int	Quantile level (1–10)

Table: mart_delay_table

Order delivery performance and review scores.

Column	Type	Description
order_id	string	Order ID
delivery_delay_days	int	Days delayed (actual – estimated)
review_score	int	Average review score
delivery_time_estimate	string	Classification: Early / On time / Late


⸻

 RAW → BASE Relationships
	•	order_items.order_id → base_order_items.order_id
	•	orders.order_id → base_order_items.order_id
	•	products.product_id → base_order_items.product_id
	•	sellers.seller_id → base_order_items.seller_id
	•	orders.order_id → base_orders.order_id
	•	order_payments.order_id → base_orders.order_id
	•	customers.customer_id → base_orders.customer_id
	•	review.order_id → base_orders.order_id

