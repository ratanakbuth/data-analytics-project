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
-- Calculate the total sales per month
-- and the running total of sales over time
SELECT
order_date,
total_sales,
SUM(total_sales) OVER (Partition by order_date Order by order_date) as running_total_sales
From
(
	SELECT
	DATETRUNC(month, order_date) as order_date,
	SUM(sales_amount) as total_sales
	FROM gold.fact_sales
	Where order_date is NOT NULL
	Group by DATETRUNC(month, order_date)
) t
