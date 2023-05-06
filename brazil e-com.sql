/* Sellers market insights */
SELECT osd.seller_id, 
	osd.seller_city, 
	COUNT(DISTINCT ood.order_id) AS total_order, 
	COUNT(DISTINCT ood.customer_id) AS total_customer,
	SUM(oopd.payment_value) AS total_rev,
	ROUND(SUM(oopd.payment_value)::NUMERIC/COUNT(DISTINCT ooid.order_id), 2) AS avg_order_value,
	ROUND(SUM(oopd.payment_value)::NUMERIC/COUNT(DISTINCT ood.customer_id), 2) AS avg_customer_value,
	ROUND(SUM(oord.review_score)::NUMERIC/COUNT(ood.order_id), 2) AS avg_ratings
FROM olist_sellers_dataset osd
LEFT JOIN olist_order_items_dataset ooid
ON osd.seller_id = ooid.seller_id
LEFT JOIN olist_orders_dataset ood 
ON ooid.order_id = ood.order_id
LEFT JOIN olist_order_payments_dataset oopd
ON ood.order_id = oopd.order_id
LEFT JOIN olist_order_reviews_dataset oord 
ON ood.order_id = oord.order_id 
GROUP BY 1, 2
ORDER BY 5 DESC
LIMIT 20;

/* Product categories market insights */
SELECT opd.product_category_name, 
	pcnt.product_category_name_english,
	COUNT(DISTINCT ooid.order_id) AS total_order, 
	COUNT(DISTINCT ood.customer_id) AS total_customer,
	SUM(oopd.payment_value) AS total_rev,
	ROUND(SUM(oopd.payment_value)::NUMERIC/COUNT(DISTINCT ooid.order_id), 2) AS avg_order_value,
	ROUND(SUM(oopd.payment_value)::NUMERIC/COUNT(DISTINCT ood.customer_id), 2) AS avg_customer_value,
	ROUND((SUM(oord.review_score)::NUMERIC/COUNT(ood.order_id)), 2) AS avg_ratings
FROM olist_products_dataset opd 
LEFT JOIN product_category_name_translation pcnt 
ON opd.product_category_name = pcnt.product_category_name 
LEFT JOIN olist_order_items_dataset ooid
ON opd.product_id = ooid.product_id 
LEFT JOIN olist_orders_dataset ood 
ON ooid.order_id = ood.order_id
LEFT JOIN olist_order_payments_dataset oopd
ON ood.order_id = oopd.order_id
LEFT JOIN olist_order_reviews_dataset oord 
ON ood.order_id = oord.order_id 
GROUP BY 1, 2
ORDER BY 5 DESC
LIMIT 20;

/* Olist yearly business insights */
SELECT DATE_PART('year', ood.order_purchase_timestamp) AS year,
	DATE_PART('month', ood.order_purchase_timestamp) AS month,
	COUNT(DISTINCT ood.order_id) AS total_order,
	COUNT(DISTINCT ood.customer_id) AS total_customer,
	SUM(oopd.payment_value) AS total_rev,
	ROUND(SUM(oopd.payment_value)::NUMERIC / COUNT(DISTINCT ood.order_id), 2) AS avg_value_per_order,
	ROUND(SUM(oopd.payment_value)::NUMERIC / COUNT(DISTINCT ood.customer_id), 2) AS avg_value_per_customer,
	JUSTIFY_INTERVAL(SUM(ood.order_delivered_carrier_date - ood.order_purchase_timestamp) / COUNT(DISTINCT ood.order_id)) AS avg_purchase_to_carrier,
	JUSTIFY_INTERVAL(SUM(ood.order_delivered_customer_date - ood.order_delivered_carrier_date) / COUNT(DISTINCT ood.order_id)) AS avg_carrier_to_customer,
	ROUND(SUM(oord.review_score)::NUMERIC / COUNT(ood.order_id), 2) AS avg_ratings
FROM olist_orders_dataset ood
LEFT JOIN olist_order_payments_dataset oopd 
ON ood.order_id = oopd.order_id 
LEFT JOIN olist_order_reviews_dataset oord 
ON ood.order_id = oord.order_id 
GROUP BY 1, 2
ORDER BY 1 DESC, 2 DESC;

/* Olist running yearly business insights */
WITH a AS (
SELECT DATE_PART('year', ood.order_purchase_timestamp) AS year,
	DATE_PART('month', ood.order_purchase_timestamp) AS month,
	COUNT(DISTINCT ood.order_id) AS total_order,
	COUNT(DISTINCT ood.customer_id) AS total_customer,
	SUM(oopd.payment_value) AS total_rev,
	ROUND(SUM(oopd.payment_value)::NUMERIC / COUNT(DISTINCT ood.order_id), 2) AS avg_value_per_order,
	ROUND(SUM(oopd.payment_value)::NUMERIC / COUNT(DISTINCT ood.customer_id), 2) AS avg_value_per_customer,
	JUSTIFY_INTERVAL(SUM(ood.order_delivered_carrier_date - ood.order_purchase_timestamp) / COUNT(DISTINCT ood.order_id)) AS avg_purchase_to_carrier,
	JUSTIFY_INTERVAL(SUM(ood.order_delivered_customer_date - ood.order_delivered_carrier_date) / COUNT(DISTINCT ood.order_id)) AS avg_carrier_to_customer,
	ROUND(SUM(oord.review_score)::NUMERIC / COUNT(ood.order_id), 2) AS avg_ratings
FROM olist_orders_dataset ood
LEFT JOIN olist_order_payments_dataset oopd 
ON ood.order_id = oopd.order_id 
LEFT JOIN olist_order_reviews_dataset oord 
ON ood.order_id = oord.order_id 
GROUP BY 1, 2),
b AS (
SELECT 
	year,
	month,
	SUM(total_customer) OVER (PARTITION BY year ORDER BY year, month) AS running_annual_customer,
	SUM(total_rev) OVER (PARTITION BY year ORDER BY year, month) AS running_annual_rev
FROM a)
SELECT 
	year,
	month,
	running_annual_customer,
	running_annual_rev,
	ROUND(running_annual_rev::NUMERIC/running_annual_customer, 2) AS running_avg_order_value
FROM b
ORDER BY 1 DESC, 2 DESC;

/* Percentage of order status */
SELECT order_status, ROUND(COUNT(order_status)::NUMERIC / 99441 * 100, 3) AS percentage FROM olist_orders_dataset ood 
GROUP BY 1
ORDER BY 2 DESC;

/* Percentage of payment methods */
WITH a AS (
SELECT 
	DATE_PART('year', ood.order_purchase_timestamp) AS year, 
	payment_type, 
	COUNT(payment_type) AS number_of_orders 
FROM olist_order_payments_dataset oopd
LEFT JOIN olist_orders_dataset ood 
ON oopd.order_id = ood.order_id 
GROUP BY 1, 2
ORDER BY 1 DESC)
SELECT 
	year, 
	payment_type, 
	number_of_orders, 
	ROUND(number_of_orders::NUMERIC / SUM(number_of_orders) OVER (PARTITION BY year), 3) AS percentage
FROM a
GROUP BY 1, 2, number_of_orders
ORDER BY 1 DESC, 2;






