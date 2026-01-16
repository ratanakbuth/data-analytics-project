/* -- Trend Analysis Change over time -- */
SELECT
YEAR(order_date) as order_year,
Month(order_date) as order_month,
SUM(sales_amount) as total_sale,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quantity
FROM gold.fact_sales
Where order_date IS NOT NULL
Group by YEAR(order_date), Month(order_date)
Order by YEAR(order_date), Month(order_date)

-- Using DateTrunc
SELECT
DATETRUNC(month, order_date) as order_date,
SUM(sales_amount) as total_sale,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quantity
FROM gold.fact_sales
Where order_date IS NOT NULL
Group by DATETRUNC(month, order_date)
Order by DATETRUNC(month, order_date)

-- Using Format Date
SELECT
FORMAT(order_date, 'yyyy-MMM') as order_date,
SUM(sales_amount) as total_sale,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quantity
FROM gold.fact_sales
Where order_date IS NOT NULL
Group by FORMAT(order_date, 'yyyy-MMM')
Order by FORMAT(order_date, 'yyyy-MMM')

/* -- Cumulative Analysis -- */
SELECT * FROM gold.fact_sales
-- Calculate the total sales per month
-- and the running total of sales over time
SELECT
order_date,
total_sales,
SUM(total_sales) OVER (Partition by order_date Order by order_date) as running_total_sales,
AVG(average_price) OVER (Partition by order_date Order by order_date) as moving_average_price
From
(
	SELECT
	DATETRUNC(month, order_date) as order_date,
	SUM(sales_amount) as total_sales,
	AVG(price) as average_price
	FROM gold.fact_sales
	Where order_date is NOT NULL
	Group by DATETRUNC(month, order_date)
) t

-- By Year --
SELECT
order_date,
total_sales,
SUM(total_sales) OVER (Order by order_date) as running_total_sales,
AVG(average_price) OVER (Order by order_date) as moving_average_price
From
(
	SELECT
	DATETRUNC(year, order_date) as order_date,
	SUM(sales_amount) as total_sales,
	AVG(price) as average_price
	FROM gold.fact_sales
	Where order_date is NOT NULL
	Group by DATETRUNC(year, order_date)
) t

/* -- Performance Analysis: current value with the target value -- */
/* Analyze the yearly performance of products by comparing their sales
to both the average sales performance of the product and the previous year's sales */
WITH yearly_product_sales as (
SELECT
	YEAR(f.order_date) as order_year,
	p.product_name,
	SUM(f.sales_amount) as current_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key = p.product_key
Where f.order_date IS NOT NULL
Group by
	YEAR(f.order_date),
	p.product_name
)

SELECT
	order_year,
	product_name,
	current_sales,
	AVG(current_sales) OVER (PARTITION BY product_name) avg_sales,
	current_sales - AVG(current_sales) OVER (PARTITION BY product_name) diff_avg,
	CASE WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
		 WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
		 ELSE 'Avg'
	END avg_change,
	-- Y-o-Y analysis
	LAG(current_sales) OVER (PARTITION BY product_name Order by order_year) py_sales,
	current_sales - LAG(current_sales) OVER (PARTITION BY product_name Order by order_year) as diff_py,
	CASE WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name Order by order_year) > 0 THEN 'Increase'
		 WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name Order by order_year) < 0 THEN 'Decrease'
		 ELSE 'No Change'
	END py_change
FROM yearly_product_sales
Order by  product_name, order_year

/* -- Part-to-Whole analysis: proportional analysis -- */
-- Which categories contribute the most to the overall sales?
WITH category_sales as(
SELECT
	category,
	SUM(sales_amount) as total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key = p.product_key
Group by category
)

SELECT
	category,
	total_sales,
	SUM(total_sales) OVER () overall_sales,
	CONCAT(Round((CAST(total_sales as float) / SUM(total_sales) OVER ()) * 100, 2), '%') as percentage_of_total
FROM category_sales
Order by total_sales DESC

/* -- Data Segmentation: group the data based on specific range -- */
-- Segment products into cost ranges and count how many products fall into each segment
WITH product_segment as(
SELECT
product_key,
product_name,
product_cost,
CASE WHEN product_cost < 100 Then 'Below 100'
	 WHEN product_cost BETWEEN 100 and 500 Then '100-500'
	 WHEN product_cost BETWEEN 500 and 1000 Then '500-1000'
	 ELSE 'Above 1000'
END cost_range
FROM gold.dim_products)

SELECT
	cost_range,
	COUNT(product_key) as total_products
FROM product_segment
Group by cost_range
Order by total_products DESC

/* Group customers into three segments based on their spending behavior
- VIP: at least 12 months of history and spending more than $5000.
- Regular: at least 12 months of history but spending $5000 or less.
- New: lifespan less than 12 months. */
WITH customer_segement as(
SELECT
	c.customer_key,
	SUM(f.sales_amount) as total_spend,
	MIN(f.order_date) as first_order,
	MAX(f.order_date) as last_order,
	DATEDIFF(month, MIN(f.order_date), MAX(f.order_date)) as lifespan
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key = c.customer_key
Group by c.customer_key)

SELECT
customer_type,
COUNT(customer_key) as total_customer
FROM (
SELECT 
	customer_key,
	CASE WHEN total_spend <= 5000 AND lifespan >= 12 THEN 'Regular'
		 WHEN total_spend > 5000 AND lifespan >= 12 THEN 'VIP'
		 ELSE 'New'
	END customer_type
FROM customer_segement ) t
Group by customer_type
Order by total_customer DESC
