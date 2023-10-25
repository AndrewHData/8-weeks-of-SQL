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
    [week_starting] = FORMAT(DATEADD(WEEK,DATEDIFF(WEEK,'2021-01-01',registration_date),'2021-01-01'),'yyyy-MM-dd'),
    [no_of_runners] = COUNT(runner_id)

FROM runners r

GROUP BY DATEADD(WEEK,DATEDIFF(WEEK,'2021-01-01',registration_date),'2021-01-01')
;


-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
WITH pickup_order_cte AS (

SELECT
    runner_id as [runner],
    DATEDIFF(MINUTE,order_time,pickup_time) as [pickup_time_mins]

FROM customer_orders co
    JOIN runner_orders_cleaned rc
        ON co.order_id = rc.order_id
)

SELECT 
    poc.runner,
    AVG(poc.pickup_time_mins) as [avg_pickup_time_mins]

FROM pickup_order_cte poc

WHERE poc.pickup_time_mins IS NOT NULL

GROUP BY poc.runner
;



-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?


-- selecting from tables
select * from runner_orders_cleaned;
select * from customer_orders;