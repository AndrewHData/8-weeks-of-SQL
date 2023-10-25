/*
Pizza Metrics
1. How many pizzas were ordered?
2. How many unique customer orders were made?
3. How many successful orders were delivered by each runner?
4. How many of each type of pizza was delivered?
5. How many Vegetarian and Meatlovers were ordered by each customer?
6. What was the maximum number of pizzas delivered in a single order?
7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
8. How many pizzas were delivered that had both exclusions and extras?
9. What was the total volume of pizzas ordered for each hour of the day?
10. What was the volume of orders for each day of the week?
*/

USE pizza_runner;

-- 1. How many pizzas were ordered?
SELECT 
    COUNT(*) as [total_pizzas_ordered]

FROM customer_orders
;


-- 2. How many unique customer orders were made?
SELECT 
    COUNT(DISTINCT(order_id)) as [total_orders]
    
FROM customer_orders
;


-- 3. How many successful orders were delivered by each runner?
SELECT
    COUNT(*) as [successful_runs]

FROM dbo.runner_orders_cleaned

WHERE cancellation IS NULL
;


-- 4. How many of each type of pizza was delivered?
SELECT
    pn.pizza_name as [pizza_type],
    COUNT(*) as [successful_runs]

FROM dbo.runner_orders_cleaned rc
    JOIN customer_orders co
        ON rc.order_id = co.order_id
    JOIN pizza_names pn
        on co.pizza_id = pn.pizza_id

WHERE cancellation IS NULL

GROUP BY pn.pizza_name
;


-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
    co.customer_id as [customer],
    pn.pizza_name as [pizza_type],
    COUNT(*) as [pizzas_ordered]

FROM runner_orders_cleaned rc
    JOIN customer_orders co
        ON rc.order_id = co.order_id
    JOIN pizza_names pn
        on co.pizza_id = pn.pizza_id


GROUP BY co.customer_id, pn.pizza_name
;

-- 6. What was the maximum number of pizzas delivered in a single order?
WITH pizza_count AS
(
SELECT
    co.order_id as [order_id],
    COUNT(co.pizza_id) as [total_pizzas_ordered]

FROM customer_orders co

GROUP BY co.order_id
)

SELECT 
    MAX(total_pizzas_ordered) as [max_number_of_pizzas_ordered]

FROM pizza_count


-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT
    co.customer_id,
    SUM(  CASE
            WHEN co.exclusions IS NULL 
            AND co.extras IS NULL 
            THEN 1 
            ELSE 0 
            END
        ) as [no_changes],
    SUM(  CASE
            WHEN co.exclusions IS NOT NULL 
            OR co.extras IS NOT NULL 
            THEN 1 
            ELSE 0 
            END
        ) as [change_made]
    
FROM customer_orders co
    JOIN runner_orders_cleaned rc
        ON co.order_id = rc.order_id

WHERE rc.cancellation IS NULL

GROUP BY co.customer_id
;


-- 8. How many pizzas were delivered that had both exclusions and extras?
-- Method 1
SELECT
    SUM(  CASE
            WHEN co.exclusions IS NOT NULL 
            AND  co.extras IS NOT NULL 
            THEN 1 
            ELSE 0 
            END
        ) as [exclusions_and_extras]
    
FROM customer_orders co
    JOIN runner_orders_cleaned rc
        ON co.order_id = rc.order_id

WHERE rc.cancellation IS NULL
;

-- Method 2
SELECT 
    COUNT(*) as [exclusions_and_extras]
FROM customer_orders co
    JOIN runner_orders_cleaned rc
        ON co.order_id = rc.order_id

WHERE rc.cancellation IS NULL
    AND co.exclusions IS NOT NULL 
    AND co.extras IS NOT NULL 
;


-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT
    DATEPART(HOUR, order_time) as [hour],
    COUNT(*) as [total_pizzas]

FROM customer_orders co

GROUP BY DATEPART(HOUR, order_time)
;


-- 10. What was the volume of orders for each day of the week?
SELECT
    FORMAT(order_time, 'dddd') as [day],
    COUNT(*) as [total_pizzas]

FROM customer_orders co

GROUP BY FORMAT(order_time, 'dddd'), DATEPART(WEEKDAY,order_time) --Format for the weekday, datepart for sorting it

ORDER BY DATEPART(WEEKDAY,order_time) ASC
;
use pizza_runner
select * from runner_orders