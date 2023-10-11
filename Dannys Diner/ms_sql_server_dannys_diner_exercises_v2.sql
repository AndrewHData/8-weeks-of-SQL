/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


-- 1. What is the total amount each customer spent at the restaurant?
SELECT 
	customer_id AS customer,
	SUM(price) AS total_spend
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY total_spend DESC
;

-- 2. How many days has each customer visited the restaurant?
SELECT
	customer_id AS customer,
	COUNT(DISTINCT(order_date)) AS days_visited
FROM sales
GROUP BY customer_id
ORDER BY days_visited DESC
;

-- 3. What was the first item from the menu purchased by each customer?
WITH first_order AS(
	SELECT
		customer_id,
		MIN(order_date) AS first_date
	FROM sales
	GROUP BY customer_id
) 
SELECT
	s.customer_id AS customer,
	m.product_name AS first_item
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN first_order f ON f.customer_id = s.customer_id AND f.first_date = s.order_date  -- We can use Joins to filter down

/* This version gives us the items bought on the first date. */
;
WITH first_item AS(
SELECT
	customer_id AS customer,
	product_name AS item,
	DENSE_RANK() OVER (PARTITION BY customer_id
				 ORDER BY order_date ASC
				 ) AS ranking
FROM sales s
JOIN menu m on s.product_id = m.product_id
group by customer_id,order_date,product_name
)
SELECT
	customer,
	item
FROM first_item
where ranking = 1
/* This version counts the items once */
;
select * from sales s join menu m on s.product_id = m.product_id
/* Use the above SQL statement to check */

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
	s.customer_id AS customer,
	m.product_name AS item,
	COUNT(s.product_id) AS times_bought
FROM sales s
JOIN menu m ON s.product_id = m.product_id
WHERE s.product_id = (	SELECT TOP 1						-- this part tells us which product was purchased the most
							product_id
						FROM sales
						GROUP BY product_id
						ORDER BY COUNT(product_id) DESC )	-- ordered in descending order to allow TOP 1 to get highest count
GROUP BY s.customer_id, m.product_name
;
-- 5. Which item was the most popular for each customer?
with rank_cte as (												-- We need to enclose any window functions in a cte because we can't use the WHERE clause
	SELECT														-- on window functions.
		customer_id,
		product_id,
		DENSE_RANK() OVER (PARTITION BY customer_id 
							ORDER BY COUNT(product_id) DESC
							) AS rank
	FROM sales
	GROUP BY customer_id, product_id
)														
SELECT
	customer_id as customer,
	m.product_name as product
FROM rank_cte r
JOIN menu m ON r.product_id = m.product_id
WHERE rank = 1
;
-- 6. Which item was purchased first by the customer after they became a member?
WITH rank_cte AS (
SELECT
	s.customer_id as customer,
	me.product_name as first_item,
	DENSE_RANK() OVER (PARTITION BY s.customer_id 
						ORDER BY MIN(order_date) ASC
						) AS rank
FROM sales s
JOIN members m	ON s.customer_id = m.customer_id
				AND s.order_date > m.join_date		-- this clause ensures that we only get order dates that are greater than (aka after) the join date
JOIN menu me ON s.product_id = me.product_id
GROUP BY s.customer_id, me.product_name
)
SELECT
	customer,
	first_item
FROM rank_cte
WHERE rank = 1