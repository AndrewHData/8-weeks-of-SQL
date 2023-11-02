/*
Runner and Customer Experience
1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
4. What was the average distance travelled for each customer?
5. What was the difference between the longest and shortest delivery times for all orders?
6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
7. What is the successful delivery percentage for each runner?
*/

USE pizza_runner;

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT 
    [Week starting] = FORMAT(
                        DATEADD(WEEK,
                            DATEDIFF(WEEK,'2021-01-01',registration_date),
                            '2021-01-01'),
                            'yyyy-MM-dd'
                        ),
    [# of Runners] = COUNT(runner_id)

FROM runners r

GROUP BY DATEADD(
                WEEK, 
                DATEDIFF(
                        WEEK,
                        '2021-01-01',
                        registration_date
                        ),
                '2021-01-01')
;


-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

-- Using seconds then converting to minutes
WITH pickup_order_cte AS (

SELECT
    runner_id as [runner],
    CAST(DATEDIFF(SECOND,order_time,pickup_time) AS FLOAT) as [pickup_time_mins]

FROM customer_orders co
    JOIN runner_orders_cleaned rc
        ON co.order_id = rc.order_id
)

SELECT 
    poc.runner as [Runner Number],
    ROUND(AVG(poc.pickup_time_mins/60),2) as [Average Pickup Time (mins)]

FROM pickup_order_cte poc

WHERE poc.pickup_time_mins IS NOT NULL

GROUP BY poc.runner
;

-- Using minutes
WITH pickup_order_cte AS (

SELECT
    runner_id as [runner],
    CAST(DATEDIFF(MINUTE,order_time,pickup_time) AS FLOAT) as [pickup_time_mins]

FROM customer_orders co
    JOIN runner_orders_cleaned rc
        ON co.order_id = rc.order_id
)

SELECT 
    poc.runner,
    ROUND(AVG(poc.pickup_time_mins),2) as [avg_pickup_time_mins]

FROM pickup_order_cte poc

WHERE poc.pickup_time_mins IS NOT NULL

GROUP BY poc.runner
;


-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH pizza_cte AS(
    SELECT
        co.order_id as [order_id],
        COUNT(co.order_id) as [no_of_pizzas],
        CAST(DATEDIFF(MINUTE,order_time,pickup_time) AS FLOAT) as [time_mins]

    FROM customer_orders co
        JOIN runner_orders_cleaned rc
            ON co.order_id = rc.order_id

    WHERE rc.cancellation IS NULL

    GROUP BY co.order_id, DATEDIFF(MINUTE,order_time,pickup_time)
)
SELECT 
    pc.no_of_pizzas as [Number of pizzas],
    AVG(time_mins) as [Average time per order (mins)],
    (AVG(time_mins) / PC.no_of_pizzas) as [Average time per pizza (mins)]

FROM pizza_cte pc

GROUP BY pc.no_of_pizzas
;



-- 4. What was the average distance travelled for each customer?
SELECT
    co.customer_id as [Customer number],
    ROUND(AVG(rc.distance_km),2) as [Average travel distance (km)]

FROM customer_orders co
    JOIN runner_orders_cleaned rc
        ON co.order_id = rc.order_id

GROUP BY customer_id
;


-- 5. What was the difference between the longest and shortest delivery times for all orders?

-- Sub query version (shorter, nicer, and to the point)
SELECT 
    CAST(    
        (SELECT MAX(rc.duration_mins) FROM runner_orders_cleaned rc) 
        -
        (SELECT MIN(rc.duration_mins) FROM runner_orders_cleaned rc) 
    AS VARCHAR)
    + ' minutes'    AS [Difference between longest and shortest delivery times]
;

--CTE version (if you're a masochist)
WITH max_delivery_time AS 
(
    SELECT
        MAX(rc.duration_mins) as [max]

    FROM runner_orders_cleaned rc
),

min_delivery_time AS 
(
    SELECT
        MIN(rc.duration_mins) as [min]

    FROM runner_orders_cleaned rc
)

SELECT 
    CAST(
        ((SELECT * FROM max_delivery_time) - (SELECT * FROM min_delivery_time))
        AS VARCHAR) 
        + ' minutes' 
    as [Difference between longest and shortest delivery times] 
;



-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
-- Query for each runner and each delivery
SELECT
    runner_id as [Runner],
    order_id as [Order #],
    CAST(
        ROUND(
            SUM(distance_km) 
            / 
            SUM(duration_mins) * 60
        , 2) 
        AS VARCHAR) + ' km/hr' as [Speed]
    
FROM runner_orders_cleaned rc

WHERE rc.cancellation IS NULL

GROUP BY rc.runner_id, rc.order_id

ORDER BY Runner
;

-- We can use this to calculate the average speed for each runner overall
WITH speed AS
(
    SELECT
        COUNT(order_id) as [Number of orders],
        runner_id as [Runner],
        SUM(distance_km) / SUM(duration_mins) as [Avg KMs per minute]
        
    FROM runner_orders_cleaned rc

    WHERE rc.cancellation IS NULL

    GROUP BY rc.runner_id
)

SELECT
    Runner,
    [Number of orders],
    ROUND(AVG([Avg KMs per minute]) * 60 ,2) as [Avg KM/Hour per order]

FROM speed

GROUP BY Runner, [Number of orders]
;


-- 7. What is the successful delivery percentage for each runner?
WITH orders_cte AS
(
SELECT
    runner_id as [Runner],
    CAST(COUNT(order_id) AS float) as [Total orders],
    CAST(SUM(CASE WHEN cancellation IS NOT NULL THEN 1 ELSE 0 END) AS float) as [# of cancelled orders]

FROM runner_orders_cleaned

GROUP BY runner_id
)

SELECT
    Runner,
    [Total orders],
    [# of cancelled orders],
    CAST(
        ROUND(
            (1 - ([# of cancelled orders] / [Total orders]))
            * 100
            ,
            2)
    AS VARCHAR) + '%' as [Delivery success rate]

FROM orders_cte

-- selecting from tables
select * from customer_orders;
select * from runner_orders_cleaned;
select * from runners;
select * from pizza_names;
select * from pizza_recipes_cleaned;
select * from pizza_toppings;
