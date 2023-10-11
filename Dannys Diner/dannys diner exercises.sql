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

-- Example Query:
SELECT
  	product_id,
    product_name,
    price
FROM menu
ORDER BY price DESC
LIMIT 5;

-- 1. What is the total amount each customer spent at the restaurant?
SELECT
	s.customer_id,
	SUM(m.price) as total_spend
FROM sales s 
LEFT JOIN menu m
	ON 	s.product_id = m.product_id
GROUP BY s.customer_id 
ORDER BY SUM(price) DESC;

-- 2. How many days has each customer visited the restaurant?
SELECT 
	customer_id,
	COUNT(DISTINCT order_date) as total_visits
FROM sales s 
GROUP BY customer_id ;

-- 3. What was the first item from the menu purchased by each customer?
SELECT 
	customer_id,
	product_name  
FROM sales s 
LEFT JOIN menu m 
	ON s.product_id = m.product_id
WHERE order_date  = (
					SELECT
						MIN(order_date) 
					FROM sales s
					GROUP BY customer_id
					); --The part in the brackets returns the min(order date) for each customer
	
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
	m.product_name as item,
	COUNT(s.product_id) as times_purchased 
FROM sales s 
LEFT JOIN menu m 
	ON s.product_id = m.product_id 
GROUP BY s.product_id 
ORDER BY COUNT(s.product_id) DESC 
LIMIT 1
;			
					
-- Below query gives us how many times the most purchased menu item was purchased by EACH customer.
SELECT 
	s1.customer_id as customer,
	m.product_name as item,
	COUNT(s1.product_id) as number_of_times_purchased
FROM sales s1
JOIN menu m 
	ON s1.product_id = m.product_id  
WHERE s1.product_id = (SELECT 
						s.product_id
					FROM sales s 
					GROUP BY s.product_id 
					ORDER BY COUNT(s.product_id) DESC 
					LIMIT 1
					) -- Get the count per product_id, sort the table by Count in descending order, then take the top 1
GROUP BY s1.customer_id,s1.product_id
;

-- 5. Which item was the most popular for each customer?
WITH popular AS (
				SELECT 
					s.customer_id as customer,	
					m.product_name as most_popular_item,
					DENSE_RANK () OVER (PARTITION BY customer_id -- PARTITION BY is like the Group By part in Alteryx's Sample tool
										ORDER BY COUNT(s.product_id) desc) as rank, -- this is a window function. It cannot be put into having, where etc until the query is run
					COUNT(s.product_id) as times_purchased
				FROM sales s 
				LEFT JOIN menu m 
					ON s.product_id = m.product_id
				GROUP BY s.product_id, s.customer_id
				ORDER BY customer_id, COUNT(s.product_id) DESC
				) -- so the idea is to make the table first, and then do the WHERE or HAVING clause to the window function. 
SELECT 
	customer,
	most_popular_item,
	times_purchased
FROM popular
WHERE rank = 1
;
-- 6. Which item was purchased first by the customer after they became a member?
WITH firstitem AS (
	SELECT 
		s.customer_id as customer,
		s.order_date as order_date,
		s.product_id as item_id,
		m.join_date as join_date,
		DENSE_RANK () OVER (PARTITION BY s.customer_id 
							ORDER BY order_date ASC) as rank
	FROM sales s 
	LEFT JOIN members m 
		ON s.customer_id = m.customer_id 
	WHERE s.order_date > m.join_date
)
SELECT 
	customer,
	menu.product_name as item,
	order_date
FROM firstitem
LEFT JOIN menu
	ON firstitem.item_id = menu.product_id
WHERE rank = 1
;
-- 7. Which item was purchased just before the customer became a member?
WITH last_item AS (
	SELECT 
		s.customer_id ,
		s.order_date ,
		s.product_id ,
		m.join_date ,
 		RANK () OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) as rank
FROM sales s 
LEFT JOIN members m 
	ON s.customer_id  = m.customer_id 
WHERE m.join_date > s.order_date 
)
SELECT 
	last_item.customer_id ,
	m.product_name
FROM last_item
LEFT JOIN menu m 
	ON last_item.product_id = m.product_id 
WHERE rank = 1
;
-- 8. What is the total items and amount spent for each member before they became a member?
SELECT
	s.customer_id  as customer,
	me.product_name as item,
	SUM(me.price) as total_spent
FROM sales s 
LEFT JOIN members m 
	ON s.customer_id = m.customer_id 
LEFT JOIN menu me 
	ON s.product_id = me.product_id
WHERE m.join_date > s.order_date
GROUP BY s.customer_id, me.product_name 
;
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH points
AS ( 
SELECT 
	s.customer_id ,
	s.product_id ,
	CASE WHEN m.product_name = 'sushi' THEN  m.price * 20 ELSE m.price * 10 END as points
FROM sales s 
JOIN menu m ON s.product_id = m.product_id
)
SELECT 
	customer_id as customer,
	SUM(points) as points
FROM points
GROUP BY customer
;
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
with first_week_promo as (
SELECT 
	s.customer_id,
	s.order_date,
	20 as multiplier
FROM sales s 
JOIN members m ON s.customer_id = m.customer_id
WHERE s.order_date BETWEEN m.join_date AND DATEADD(day,6,s.order_date)
)
SELECT
	s.product_id
FROM sales s
JOIN first_week_promo f on s.customer_id = f.customer_id