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
   s.customer_id as [customer],
   CAST(SUM(m.price) as MONEY) as [$_amount_spent]

FROM sales s
   JOIN menu m 
      ON s.product_id = m.product_id

GROUP BY s.customer_id
;


-- 2. How many days has each customer visited the restaurant?
SELECT
   customer_id as [customer],
   COUNT(DISTINCT(order_date)) as [no_of_days]

FROM sales

GROUP BY customer_id
;


-- 3. What was the first item from the menu purchased by each customer?
WITH purchase AS
(

SELECT
   s.customer_id as [customer],
   m.product_name as [item],
   DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date ASC ) as [item_rank]

FROM sales s
   JOIN menu m 
      ON s.product_id = m.product_id

) 

SELECT
   customer,
   item as [first_item_ordered]

FROM purchase

WHERE item_rank = 1
;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT TOP 1
   m.product_name as [item],
   COUNT(m.product_name) as [times_purchased]

FROM sales s
   JOIN menu m 
      ON s.product_id = m.product_id

GROUP BY m.product_name

ORDER BY times_purchased DESC
;

-- 5. Which item was the most popular for each customer?
WITH items_purchased AS
(

SELECT
   s.customer_id as [customer],
   m.product_name as [item],
   COUNT(m.product_name) as [times_purchased],
   DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY (COUNT(m.product_name)) DESC) AS [purchase_rank]

FROM sales s
   JOIN menu m 
      ON s.product_id = m.product_id

GROUP BY m.product_name, s.customer_id

)

SELECT
   customer,
   item,
   times_purchased

FROM items_purchased

WHERE purchase_rank = 1
;


-- 6. Which item was purchased first by the customer after they became a member?
WITH purchase_order AS
(

SELECT
   s.customer_id as [customer],
   mu.product_name as [item],
   ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date ASC) as [order_rank]

FROM sales s
   JOIN members mb
      ON s.customer_id = mb.customer_id
   JOIN menu mu
      ON s.product_id = mu.product_id

WHERE s.order_date >= mb.join_date

)

SELECT
   customer,
   item

FROM purchase_order

WHERE order_rank = 1
;


-- 7. Which item was purchased just before the customer became a member?
-- CTE version --
WITH purchase_order AS
(

SELECT
   s.customer_id as [customer],
   mu.product_name as [item],
   ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) as [order_rank]

FROM sales s
   JOIN members mb
      ON s.customer_id = mb.customer_id
   JOIN menu mu
      ON s.product_id = mu.product_id

WHERE s.order_date < mb.join_date

)

SELECT
   customer,
   item

FROM purchase_order

WHERE order_rank = 1
;


-- Temp table version --
-- Create temp table (with price to use in next question)
SELECT
   s.customer_id as [customer],
   mu.product_name as [item],
   mu.price as [price],
   RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) as [order_rank]

INTO #before_membership

FROM sales s
   JOIN members mb
      ON s.customer_id = mb.customer_id
   JOIN menu mu
      ON s.product_id = mu.product_id

WHERE s.order_date < mb.join_date

-- Select desired columns
SELECT 
   customer,
   item

FROM #before_membership

WHERE order_rank = 1
;


-- 8. What is the total items and amount spent for each member before they became a member?
-- We can select from the temp table created in previous question
SELECT
   customer,
   item,
   SUM(price) as [amount_spent]

FROM #before_membership

GROUP BY customer, item

ORDER BY customer ASC
;


-- Dropping the temp table so it doesn't take up memory
DROP TABLE #before_membership
;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- We can build a sub-query for the points
SELECT
   s.customer_id as [customer],
   SUM(
      mu.price *  (CASE                                 -- price multiplied by 20 or 10 depending 
                  WHEN mu.product_name = 'sushi'        -- on whether the condition of 'sushi' is met
                  THEN 20 
                  ELSE 10 
                  END 
               ) 
   ) as [points]

FROM sales s
      JOIN menu mu
         ON s.product_id = mu.product_id

GROUP BY s.customer_id

ORDER BY customer ASC
;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT
   s.customer_id as [customer],
   SUM(
      mu.price *  (CASE                                     
                  WHEN mu.product_name = 'sushi' 
                  THEN 20
                  WHEN s.order_date BETWEEN mem.join_date AND DATEADD(DAY,6,mem.join_date)      -- we put 6 days as the dateadd function is not inclusive. 
                  THEN 20                                                                       -- eg. 6 days from the 1st is the 7th
                  ELSE 10 
                  END 
               ) 
   ) as [points]

FROM sales s
      JOIN menu mu
         ON s.product_id = mu.product_id
      JOIN members mem 
         ON s.customer_id = mem.customer_id

WHERE s.order_date < DATEFROMPARTS(2021,2,1) 

GROUP BY s.customer_id
ORDER BY customer ASC
;


--Bonus Questions
/* Join All The Things
The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.

Recreate the following table output using the available data:
customer_id	order_date	product_name	price	member
      A	   2021-01-01	   curry	        15	  N
      A	   2021-01-01	   sushi	        10	  N
      A	   2021-01-07	   curry	        15	  Y
      A	   2021-01-10	   ramen	        12	  Y
      A	   2021-01-11	   ramen	        12	  Y
      A	   2021-01-11	   ramen	        12	  Y
      B	   2021-01-01	   curry	        15	  N
      B	   2021-01-02	   curry	        15	  N
      B	   2021-01-04	   sushi	        10	  N
      B	   2021-01-11	   sushi	        10	  Y
      B	   2021-01-16	   ramen	        12	  Y
      B  	2021-02-01	   ramen	        12	  Y
      C	   2021-01-01	   ramen	        12	  N
      C	   2021-01-01	   ramen	        12	  N
      C	   2021-01-07	   ramen	        12	  N

*/

SELECT
   s.customer_id,
   s.order_date, 
   mu.product_name,
   mu.price,
   [member] =  CASE 
               WHEN mem.join_date <= s.order_date
               THEN 'Y'
               ELSE 'N'
               END

FROM sales s
      JOIN menu mu
         ON s.product_id = mu.product_id
      LEFT JOIN members mem 
         ON s.customer_id = mem.customer_id

ORDER BY customer_id ASC, order_date ASC, product_name ASC
;


--Rank All The Things
/*
Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

customer_id	order_date	product_name	price	member	ranking
      A	   2021-01-01	   curry	      15	      N	   null
      A	   2021-01-01  	sushi	      10	      N	   null
      A	   2021-01-07  	curry    	15    	Y	   1
      A	   2021-01-10	   ramen	      12	      Y	   2
      A	   2021-01-11  	ramen	      12	      Y	   3
      A	   2021-01-11  	ramen	      12	      Y	   3
      B	   2021-01-01  	curry	      15	      N	   null
      B	   2021-01-02  	curry	      15	      N	   null
      B	   2021-01-04	   sushi	      10    	N	   null
      B	   2021-01-11	   sushi	      10    	Y	   1
      B	   2021-01-16	   ramen	      12    	Y	   2
      B	   2021-02-01	   ramen	      12       Y	   3
      C	   2021-01-01	   ramen	      12	      N	   null
      C	   2021-01-01	   ramen	      12	      N	   null
      C	   2021-01-07  	ramen	      12	      N	   null

*/


-- Use a CTE to create a table, then extract 'Y' members to insert into a temp table to join later.
-- Create CTE
WITH table1 AS(
   SELECT
      s.customer_id,
      s.order_date, 
      mu.product_name,
      mu.price,
      [member] =  CASE 
                  WHEN mem.join_date <= s.order_date
                  THEN 'Y'
                  ELSE 'N'
                  END,
      [row_id] = ROW_NUMBER() OVER(ORDER BY s.customer_id ASC)

   FROM sales s
         JOIN menu mu
            ON s.product_id = mu.product_id
         LEFT JOIN members mem 
            ON s.customer_id = mem.customer_id
)

-- Insert into #member_order_rank temp table after adding the ranking to Y members
SELECT 
   *,
   [ranking] = DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date)

INTO #member_order_rank   

FROM table1
WHERE member = 'Y'
;


-- Dropping the #member_order_rank temp table so it doesn't take up memory
DROP TABLE #member_order_rank


-- Check the table
SELECT * from #member_order_rank

-- Left join the temp table with the 'CTE' table
WITH table1 AS(
   SELECT
      s.customer_id,
      s.order_date, 
      mu.product_name,
      mu.price,
      [member] =  CASE 
                  WHEN mem.join_date <= s.order_date
                  THEN 'Y'
                  ELSE 'N'
                  END,
      [row_id] = ROW_NUMBER() OVER(ORDER BY s.customer_id ASC)

   FROM sales s
         JOIN menu mu
            ON s.product_id = mu.product_id
         LEFT JOIN members mem 
            ON s.customer_id = mem.customer_id
)

SELECT
   t.customer_id,
   t.order_date,
   t.product_name,
   t.price,
   t.member,
   m.ranking


FROM table1 t
   LEFT JOIN #member_order_rank m
      ON t.row_id = m.row_id
;


-- Dropping the #member_order_rank temp table so it doesn't take up memory
DROP TABLE #member_order_rank