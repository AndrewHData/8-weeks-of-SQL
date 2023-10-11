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
select 
	customer_id as customer,
	SUM(m.price) as total
from sales s
join menu m on s.product_id = m.product_id
group by customer_id
order by customer asc;

-- 2. How many days has each customer visited the restaurant?
select
	customer_id as customer,
	COUNT(distinct(s.order_date)) as number_of_visits
from sales s
group by customer_id
order by customer;

-- 3. What was the first item from the menu purchased by each customer?
with first_order as(
select 
	customer_id as customer,
	MIN(s.order_date) as first_date
from sales s
group by customer_id
)
select
	customer_id as customer,
	product_name as item
from sales s
join menu m on s.product_id = m.product_id
join first_order f on s.customer_id = f.customer and s.order_date = f.first_date
;
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select top 1
	product_name as item,
	COUNT(s.product_id) as count
from sales s
join menu m on s.product_id = m.product_id
group by product_name
order by count desc
;

-- 5. Which item was the most popular for each customer?
with most_popular_item as(
select 
	customer_id as customer,
	product_name as item,
	COUNT(s.product_id) as count,
	RANK () over (partition by customer_id order by Count(s.product_id)) as rank
from sales s
join menu m on s.product_id = m.product_id
group by customer_id, product_name
)
select 
	customer,
	item,
	count
from most_popular_item
where rank = 1
;

-- 6. Which item was purchased first by the customer after they became a member?
with first_member_purchase as (
select
	s.customer_id as customer,
	MIN(s.order_date) as earliest_order_date
from sales s
join members m on s.customer_id = m.customer_id
where order_date >= join_date
group by s.customer_id
)
select
	customer,
	m.product_name as item
from sales s
join first_member_purchase f on s.customer_id = f.customer and s.order_date = f.earliest_order_date
join menu m on s.product_id = m.product_id
;

-- 7. Which item was purchased just before the customer became a member?
with item_before_joining as(
select
	s.customer_id as customer,
	s.product_id as product_id,
	s.order_date as order_date,
	DENSE_RANK () over (partition by s.customer_id order by s.order_date desc) as rank
from members m
join sales s on s.customer_id = m.customer_id
where m.join_date > order_date
)
select 
	customer,
	product_name as item
from item_before_joining i
join menu m on m.product_id = i.product_id 
where rank = 1
;

-- 8. What is the total items and amount spent for each member before they became a member?
with before_joining as(
select
	s.customer_id as customer,
	s.product_id as product_id
from members m
join sales s on s.customer_id = m.customer_id
where m.join_date > order_date
)
select
	customer,
	COUNT(m.product_name) as total_items,
	SUM(m.price) as total_amount
from before_joining b
join menu m on b.product_id = m.product_id
group by customer
order by customer
;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with multiplier as (
select
	*,
	CASE WHEN product_name = 'sushi' THEN 20 ELSE 10 END as points
from menu m
)
select
	s.customer_id as customer,
	SUM(m.price * m.points) as total_points
from sales s
join multiplier m on s.product_id = m.product_id
group by customer_id
;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
with join_points_special as (
select
	s.customer_id as customer,
	s.order_date as order_date,
	m.join_date as join_date
from sales s
join members m on s.customer_id = m.customer_id 
)
select 
	s.customer_id as customer,
	SUM(CASE WHEN s.order_date between j.join_date and DATEADD(day,6,j.join_date)
	OR product_name = 'sushi' THEN 20 ELSE 10 END) as points
from sales s
join menu m on s.product_id = m.product_id
join join_points_special j on s.customer_id = j.customer and j.order_date = s.order_date
where s.order_date < '2021-02-01'
group by s.customer_id
;
select
	s.customer_id as customer,
	SUM((CASE WHEN s.order_date >= m.join_date 
			AND s.order_date <= DATEADD(day,6,m.join_date)
			OR me.product_name = 'sushi' 
	THEN 20 ELSE 10 END )*me.price) as points
from sales s
join members m on s.customer_id= m.customer_id
join menu me on s.product_id = me.product_id
WHERE s.order_date < '2021-02-01'
GROUP BY s.customer_id
;

-- Bonus Question: Join All The Things
-- The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.
/*
Recreate the following table output using the available data:

customer_id	order_date	product_name	price	member
A	2021-01-01	curry	15	N
A	2021-01-01	sushi	10	N
A	2021-01-07	curry	15	Y
A	2021-01-10	ramen	12	Y
A	2021-01-11	ramen	12	Y
A	2021-01-11	ramen	12	Y
B	2021-01-01	curry	15	N
B	2021-01-02	curry	15	N
B	2021-01-04	sushi	10	N
B	2021-01-11	sushi	10	Y
B	2021-01-16	ramen	12	Y
B	2021-02-01	ramen	12	Y
C	2021-01-01	ramen	12	N
C	2021-01-01	ramen	12	N
C	2021-01-07	ramen	12	N

*/
select
	s.customer_id,
	s.order_date,
	m.product_name,
	m.price,
	(CASE WHEN s.order_date >= mem.join_date THEN 'Y' ELSE 'N' END ) as member
from sales s
left join menu m on s.product_id = m.product_id
left join members mem on s.customer_id = mem.customer_id
;
-- Bonus Question: Join All The Things
/*
Rank All The Things
Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

customer_id	order_date	product_name	price	member	ranking
A	2021-01-01	curry	15	N	null
A	2021-01-01	sushi	10	N	null
A	2021-01-07	curry	15	Y	1
A	2021-01-10	ramen	12	Y	2
A	2021-01-11	ramen	12	Y	3
A	2021-01-11	ramen	12	Y	3
B	2021-01-01	curry	15	N	null
B	2021-01-02	curry	15	N	null
B	2021-01-04	sushi	10	N	null
B	2021-01-11	sushi	10	Y	1
B	2021-01-16	ramen	12	Y	2
B	2021-02-01	ramen	12	Y	3
C	2021-01-01	ramen	12	N	null
C	2021-01-01	ramen	12	N	null
C	2021-01-07	ramen	12	N	null
*/
with rank_date as (
select
	s.customer_id,
	s.order_date,
	m.join_date,
	DENSE_RANK() over (partition by s.customer_id order by s.order_date asc) as ranking
from sales s
join members m on s.customer_id = m.customer_id
where order_date >= join_date
)
select
	s.customer_id,
	s.order_date,
	m.product_name,
	m.price,
	(CASE WHEN s.order_date >= mem.join_date THEN 'Y' ELSE 'N' END ) as member,
	r.ranking
from sales s
left join menu m on s.product_id = m.product_id
left join members mem on s.customer_id = mem.customer_id	
left join rank_date r on s.customer_id = r.customer_id and s.order_date = r.order_date
order by customer_id,order_date,product_name
;