/*  At the beginning of 2023, a  Nigerian restaurant was opened and three food were being sold
"Rice, Beans, yam", a set of data of data was collected and will be used to understand customer visiting patterns, expenditure, and favorite menu items.
To improve the sales and know what the customer prefers I analyze from the data given by understanding customers to deliver a personalized experience and 
improve loyalty
INSIGHTS: to decide whether to expand the existing customer loyalty program  */

/*this project test my knowledge on How to create tables, JOIN's, Subquery, CTE's, inserting Data into Tables, Group by, Order by and some functions like ROW_NUMBER.  */
------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CREATING A DATABASE
CREATE DATABASE cus_proj_behaviour;

USE cus_proj_behaviour;
------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CREATE THE FIRST TABLE (SALES)
CREATE TABLE sales (
	customer_id VARCHAR(25),
    order_date DATE,
	product_id INTEGER
);
-- INSERT DATASET INTO THE FIRST TABLE (SALES)
INSERT INTO sales 
	(customer_id, order_date, product_id)
VALUES 	(1001, "2023-01-01", 1), 
		(1001, "2023-01-01", 2),
        (1001, "2023-01-07", 2),
        (1001, "2023-01-10", 3),
        (1001, "2013-01-11", 3),
        (1001, "2023-01-11", 3),
        (1002, "2023-01-01", 2),
        (1002, "2023-01-02", 2),
        (1002, "2023-01-04", 1),
        (1002, "2023-01-11", 1),
        (1002, "2023-01-16", 3),
        (1002, "2023-02-01", 3),
        (1003, "2023-01-01", 3),
        (1003, "2023-01-01", 3),
        (1003, "2023-01-07", 3);
        
        SELECT *
        FROM sales;
-----------------------------------------------------------------------------------------------------------------------------------------------------------
--  CREATE THE SECOND TABLE (MENU)
        
CREATE TABLE menu (
			product_id INTEGER,
            product_name VARCHAR(25),
			price INTEGER
        );
        
         
SELECT *
	FROM menu;
-- INSERT DATASET INTO THE SECOND TABLE (MENU)        
INSERT INTO menu
        VALUES 	(1, "rice", 10),
				(2, "beans", 15),
                (3, "yam", 12);
	
----------------------------------------------------------------------------------------------------------------------------------
 -- CREATE THE THIRD TABLE (MEMBERS)
CREATE TABLE members (
			customer_id VARCHAR(25),
            join_date DATE
            );
-- INSERT DATASET INTO THE FIRST TABLE (SALES)
INSERT INTO members 
	VALUES (1001, "2023-01-02"),
			(1002, "2023-01-09");
------------------------------------------------------------------------------------------------------------------------------------------------

-- I ask these questions to improve the sales and know what the customer prefers analyze from the data provided the best way he can go about it


-- 1) What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price) AS total_spent
FROM sales s
JOIN menu m
	ON s.product_id = m.product_id
GROUP BY s.customer_id;
--------------------------------------------------------------------------------------------------------------------------------------------------

--  2) How many days has each customer visited the restaurant?
SELECT s.customer_id, COUNT(DISTINCT s.order_date) AS days_visited
FROM sales s
GROUP BY customer_id;
--------------------------------------------------------------------------------------------------------------------------------------------------

-- 3) What was the first item from the menu purchased by each customers?

WITH customer_first_purchase AS (
	SELECT customer_id, MIN(order_date) AS first_purchase_date
	FROM sales s
	GROUP BY customer_id
)
SELECT cfp.customer_id, cfp.first_purchase_date, m.product_name
FROM customer_first_purchase cfp
JOIN sales s 
	ON cfp.customer_id = s.customer_id
    AND cfp.first_purchase_date = s.order_date
JOIN menu m
	ON s.product_id = m.product_id;
-----------------------------------------------------------------------------------------------------------------------------------------------------

-- 4) What is the most purchased item on the menu and how many times?
SELECT m.product_name, COUNT(*) AS total_purchased
FROM sales s
JOIN menu m
	ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_purchased DESC
limit 3;
------------------------------------------------------------------------------------------------------------------------------------------------------
-- 5) Which Item was the most popular for each customer?
WITH item_popularity AS
(SELECT s.customer_id, m.product_name, COUNT(*) AS purchase_count,
DENSE_RANK() OVER(PARTITION BY s.customer_id 
ORDER BY COUNT(*) DESC) AS item_list
FROM sales s 
JOIN menu m
	ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name)
SELECT ip.customer_id, ip.product_name, ip.purchase_count
FROM item_popularity ip
WHERE item_list = 1;
----------------------------------------------------------------------------------------------------------------------------------------------
-- 6) Which item was purchased first by the customer after they became a member?

WITH first_product_purchase_after_membership AS
(
SELECT s.customer_id, MIN(s.order_date) AS first_purchase_date
FROM sales s
JOIN members mb
	ON s.customer_id =mb.customer_id
WHERE s.order_date >= mb.join_date
GROUP BY customer_id
)
SELECT fpp.customer_id, fpp.first_purchase_date, m.product_name
FROM first_product_purchase_after_membership fpp
JOIN sales s
ON fpp.customer_id = s.customer_id
AND fpp.first_purchase_date = s.order_date
JOIN menu m
ON s.product_id = m.product_id;
-------------------------------------------------------------------------------------------------------------------------------------------------------

-- 7) Which item was purchased just before the customer became a memeber?

WITH last_purchase_before_membership AS
(SELECT s.customer_id, MAX(s.order_date) AS last_purchase_date
FROM sales s 
JOIN members mb 
	ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id)
SELECT lpbm.customer_id, lpbm.last_purchase_date, m.product_name
FROM last_purchase_before_membership lpbm
JOIN sales s
ON lpbm.customer_id = s.customer_id
AND lpbm.last_purchase_date = s.order_date
JOIN menu m
ON s.product_id = m.product_id
ORDER BY customer_id; 
------------------------------------------------------------------------------------------------------------------------------------------------

-- 8) What is the total items and amount spent for each member before they became members?

SELECT s.customer_id,COUNT(*) AS total_items,  SUM(m.price) AS total_amount_spent
FROM sales s
JOIN menu m
	ON s.product_id = m.product_id
JOIN members mb
	ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id;
---------------------------------------------------------------------------------------------------------------------------------------

-- 9) If each $1 spent equates to 10 points and sushi has a 2x points multiplier. How many points would each customer have?

SELECT s.customer_id, SUM(
	CASE
        WHEN m.product_name = "sushi" THEN (m.price * 20)
        ELSE (m.price * 10) 
	END) AS total_points 
FROM sales s 
JOIN MENU m 
	ON s.product_id = m.product_id
GROUP BY s.customer_id;
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* 10) In the first week after a customer joins the program (icluding their join date) they earn 2x points on all items, not just sushi. 
-- How many points do customer A and B have at the end of January?*/
SELECT s.customer_id, SUM(
	CASE 
		WHEN s.order_date BETWEEN mb.join_date and (mb.join_date + 7)
        THEN m.price * 20
        WHEN m.product_name = "sushi" 
        THEN m.price * 20
        ELSE m.price * 10
	END) AS total_points
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
LEFT JOIN members mb 
	ON s.customer_id = mb.customer_id 
WHERE s.customer_id IN (1001, 1002) AND s.order_date <= "2023-01-31"
GROUP BY s.customer_id;

-- 11) find the members of the company among the customers

SELECT s.customer_id, s.order_date, m.product_name, m.price,
	CASE 
		WHEN s.order_date >= mb.join_date THEN "Member"
        ELSE "Not a member"
	END AS company_members
FROM sales s
JOIN menu m
	ON s.product_id = m.product_id
LEFT JOIN members mb
	ON s.customer_id = mb.customer_id
ORDER BY s.customer_id, s.order_date;
