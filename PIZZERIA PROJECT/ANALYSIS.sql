-- CHECKING WHETHER THE DATA IS CORRECTLY IMPORTED
SELECT * FROM order_details;
SELECT * FROM orders;
SELECT * FROM pizza_types;
SELECT * FROM pizzas;

-- BASIC LEVEL OF ANALYSIS
-- 1] TOTAL ORDERS PLACE
SELECT COUNT(DISTINCT order_id) AS "TOTAL ORDERS"
FROM orders;

-- 2] CALCULATING TOTAL REVENUE
-- 2.1] GET TO KNOW THE DETAILS
SELECT od.pizza_id, od.quantity, p.price
FROM order_details od
INNER JOIN pizzas p
ON od.pizza_id = p.pizza_id;

-- 2.2] NOW CALCULATING THE REVENUE
SELECT ROUND(SUM(od.quantity * p.price),2) AS "TOTAL REVENUE"
FROM order_details od
INNER JOIN pizzas p
ON od.pizza_id = p.pizza_id;

-- 3] IDENTIFYING THE HIGHEST PRICED PIZZA
SELECT pt.name, p.price as "HIGHEST PRICE"
FROM pizza_types pt
JOIN pizzas p
ON p.pizza_type_id = pt.pizza_type_id
ORDER BY p.price DESC
LIMIT 1;

-- 4] IDENTIFYING THE MOST COMMON PIZZA SIZE ORDERED     [FOR INVENTORY MANAGEMENT]
SELECT p.size,
COUNT(DISTINCT order_id) AS "NO OF ORDERS", 
SUM(quantity) AS "TOTAL QUANTITY ORDERED"
FROM order_details od
INNER JOIN pizzas p
ON p.pizza_id = od.pizza_id
GROUP BY p.size
ORDER BY COUNT(DISTINCT order_id) DESC;

-- 5] IDENTIFYING MOST ORDERED PIZZA ALONG WITH ITS QUANTITY
SELECT DISTINCT pt.name AS Pizza, 
SUM(od.quantity) AS "TOTAL ORDERED" 
FROM pizza_types pt
JOIN pizzas p
ON pt.pizza_type_id = p.pizza_type_id
JOIN order_details od
ON p.pizza_id = od.pizza_id
GROUP BY  pt.name
ORDER BY SUM(od.quantity) DESC
LIMIT 5;

-- INTERMEDIATE ANALYSIS
-- 1] IDENTIFYING THE TOTAL QUANTITY OF EACH PIZZA CATEGORY ORDERED
SELECT 
	pt.category, sum(quantity) AS "TOTAL QUANTITY ORDERED"
FROM order_details od
INNER JOIN pizzas p
ON p.pizza_id = od.pizza_id
INNER JOIN pizza_types pt 
ON pt.pizza_type_id = p.pizza_type_id
GROUP BY pt.category
ORDER BY SUM(quantity) DESC;

-- 2] DETERMINING THE DISTRIBUTION OF THE ORDERS BY HOUR OF THE DAY
SELECT  HOUR(o.time) AS "HOURS", 
COUNT(DISTINCT o.order_id) AS "TOTAL ORDERS"
FROM orders o
INNER JOIN order_details od
ON o.order_id = od.order_id
GROUP BY HOUR(o.time)
ORDER BY COUNT(DISTINCT o.order_id) DESC;

-- 3] CATEGORY WISE DISTRIBUTION OF PIZZA ORDERS
SELECT pt.category, count(DISTINCT od.order_id) AS "TOTAL ORDERS"
FROM pizza_types pt
JOIN pizzas p
ON pt.pizza_type_id = p.pizza_type_id
JOIN order_details od
ON p.pizza_id = od.pizza_id
GROUP BY pt.category
ORDER BY COUNT(DISTINCT order_id) DESC;

-- 4] CATEGORY WISE DISTIRBUTION OF PIZZA [FOR INVENTORY MANAGEMENT]
SELECT category, COUNT(DISTINCT pt.pizza_type_id) AS "INSTOCK PIZZAS"
FROM pizza_types pt
INNER JOIN pizzas p
ON pt.pizza_type_id =p.pizza_type_id
GROUP BY category
ORDER BY COUNT(DISTINCT pizza_id) DESC;

-- 5] CALCULATING THE NUMBER OF PIZZAS ORDERED PER DAY
WITH cte as (
SELECT o.date, SUM(od.quantity) AS tot_orders 
FROM orders o
INNER JOIN order_details od
ON o.order_id = od.order_id
GROUP BY o.date)

SELECT ROUND(AVG(tot_orders),2) AS "AVERAGE NUMBER OF PIZZA PER DAY" 
FROM cte;

-- 6] TOP 3 PIZZA TYPES BASED ON REVENUE
SELECT pt.name, ROUND(SUM(od.quantity * p.price),2) AS "REVENUE"
FROM pizza_types pt
INNER JOIN pizzas p
ON pt.pizza_type_id = p.pizza_type_id
INNER JOIN order_details od
ON p.pizza_id = od.pizza_id
GROUP BY pt.name
ORDER BY SUM(od.quantity * p.price) DESC
LIMIT 3 ;

-- ADVANCED ANALYSIS
-- 1] CALCULATING THE PERCENTAGE CONTRIBUTION OF EACH PIZZA CATEGORY TO THE TOTAL REVENUE
SELECT pt.category, 
CONCAT(CAST(
	(SUM(od.quantity * p.price)/ 
    (SELECT SUM(od.quantity * p.price) 
    FROM order_details od
    JOIN pizzas p ON
    p.pizza_id = od.pizza_id)) * 100.0 AS DECIMAL(2)),  '%') AS `REVENUE CONTRIBUTION FROM PIZZA`
FROM  order_details od
INNER JOIN pizzas p ON p.pizza_id = od.pizza_id
INNER JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY pt.category
ORDER BY `REVENUE CONTRIBUTION FROM PIZZA` DESC;

-- 2]  CALCULATING THE PERCENTAGE CONTRIBUTION OF EACH PIZZA TYPE TO THE TOTAL REVENUE 
SELECT pt.name AS "Pizza", 
CONCAT(CAST(
	(SUM(od.quantity * p.price)/ 
    (SELECT SUM(od.quantity * p.price) 
    FROM order_details od
    JOIN pizzas p ON
    p.pizza_id = od.pizza_id)) * 100.0 AS DECIMAL(2)),  '%') AS `REVENUE CONTRIBUTION FROM PIZZA`
FROM  order_details od
INNER JOIN pizzas p ON p.pizza_id = od.pizza_id
INNER JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY pt.name
ORDER BY `REVENUE CONTRIBUTION FROM PIZZA` DESC;

-- 3] ANALYZING THE CUMULATIVE REVENUE GENERATED OVER TIME
WITH cte AS (
	SELECT date as `DATE`,
		CAST(SUM(od.quantity * p.price) AS DECIMAL) AS revenue
	FROM  order_details od
	INNER JOIN orders o ON o.order_id = od.order_id
	INNER JOIN pizzas p ON p.pizza_id = od.pizza_id
	GROUP BY `DATE`)
SELECT `DATE`, SUM(revenue) OVER(ORDER BY `DATE`) AS `CUMULATIVE REVENUE`
FROM cte
GROUP BY `DATE`, revenue;

-- 4] TOP 3 MOST ORDERED PIZZA TYPES BASED ON REVENUE FOR EACH PIZZA CATEGORY
WITH tot_rev AS (
	SELECT pt.name, pt.category,
		ROUND(SUM(od.quantity * p.price),2) AS `REVENUE`
	FROM pizza_types pt
	INNER JOIN pizzas p ON p.pizza_type_id = pt.pizza_type_id
	INNER JOIN order_details od ON od.pizza_id = p.pizza_id
	GROUP BY pt.name, pt.category
	ORDER BY `REVENUE` DESC),
top AS (
	SELECT name, category, `REVENUE`,
    RANK() OVER(PARTITION BY category ORDER BY `REVENUE` DESC) AS rnk
    FROM tot_rev)
SELECT  name, category, `REVENUE` 
FROM top
WHERE rnk <=3
ORDER BY category, name, `REVENUE`;

SELECT * FROM pizzas;
SELECT * FROM pizza_types;
SELECT * FROM order_details;
SELECT * FROM orders;