/*
=========================================================================
Customer Reporting
=========================================================================
Purpose:
	This report consolidates key customer metrics and behaviors

Highlights:
1. Gathers essential fields such as names, ages, and trasaction details.
2. Segments customers into categories (VIP, Regular, New) and age groups.
3. Aggregates customer-level metrics:
	- total orders
	- total sales
	- total quantity purchased
	- total products
	- lifespan (in months)
4. Calculates valuable KPIs:
	- recency (months since last order)
	- average order value
	- average monthly spend
=========================================================================
*/
IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
	DROP VIEW gold.report_customers;
GO

CREATE VIEW gold.report_customers AS
WITH base_query as (
-- built base query
SELECT
	f.order_number,
	f.product_key,
	f.order_date,
	f.sales_amount,
	f.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name, ' ', c.last_name) as customer_name,
	DATEDIFF(year, c.birthdate, GETDATE()) as age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key = c.customer_id
Where f.order_date IS NOT NULL AND c.customer_key is NOT NULL)

, customer_aggregation as(
-- built customer aggregation
SELECT
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT order_number) as total_orders,
	SUM(sales_amount) as total_sales,
	SUM(quantity) as total_quantity,
	COUNT(DISTINCT product_key) as total_products,
	MAX(order_date) as last_order_date,
	DATEDIFF(month, MIN(order_date), MAX(order_date)) as lifespan
From base_query
Group by
	customer_key,
	customer_number,
	customer_name,
	age
)

SELECT
	customer_key,
	customer_number,
	customer_name,
	age,
	-- Segment customer age group
	CASE WHEN age < 20 THEN 'Under 20'
		 WHEN age between 20 and 29 THEN '20-29'
		 WHEN age between 30 and 39 THEN '30-39'
		 WHEN age between 40 and 49 THEN '40-49'
		 ELSE '50 and above'
	END age_group,
	-- Segment customer type
	CASE WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
		 WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
		 ELSE 'New'
	END customer_segment,
	last_order_date,
	-- Calculate KPI recency
	DATEDIFF(month, last_order_date, GETDATE()) as recency,
	total_orders,
	total_sales,
	total_quantity,
	total_products,
	lifespan,
	-- Calculate average order value
	CASE WHEN total_sales = 0 THEN 0
		 ELSE total_sales / total_orders 
	END as avg_order_value,
	-- Calculate average monthly spending
	CASE WHEN lifespan = 0 THEN total_sales
		 ELSE total_sales / lifespan 
	END as avg_monthly_spending
FROM customer_aggregation
