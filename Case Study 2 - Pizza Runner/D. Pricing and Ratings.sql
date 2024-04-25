/*
-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
-- 2. What if there was an additional $1 charge for any pizza extras?
    -- Add cheese is $1 extra
-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
-- 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
    -- customer_id
    -- order_id
    -- runner_id
    -- rating
    -- order_time
    -- pickup_time
    -- Time between order and pickup
    -- Delivery duration
    -- Average speed
    -- Total number of pizzas
-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
*/


/* Specify the databse to use*/
USE pizza_runner;

-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?


SELECT
     [Pizza type] = pn.pizza_name
    ,[Total revenue] =  
        '$'+ 
        CAST( 
            ((COUNT(*)) * ( CASE WHEN co.pizza_id = 1 THEN 12 ELSE 10 END )) 
        as VARCHAR) 
        
FROM dbo.customer_orders co
JOIN dbo.pizza_names pn
    ON co.pizza_id = pn.pizza_id
GROUP BY pn.pizza_name, co.pizza_id;


-- 2. What if there was an additional $1 charge for any pizza extras?
    -- Add cheese is $1 extra

/* Previously, when I cleaned the data, I used this:
/* Cleaning the pizza_recipes table */
-- Best to cross tab/pivot the table 
-- Create the new temp table for cleaned pizza_recipes data 
DROP TABLE IF EXISTS pizza_recipes_cleaned
CREATE TABLE pizza_recipes_cleaned
(
    pizza_id INT,
    topping_id INT
)
;

-- Create a CTE to split the toppings into separate rows
WITH ToppingsCTE AS 
(
    SELECT
        pizza_id,
        value
    FROM
        pizza_recipes
    CROSS APPLY STRING_SPLIT(CONVERT(nvarchar(MAX), toppings), ',')
)

-- Insert the values after the INSERT INTO into the temp table
INSERT INTO pizza_recipes_cleaned

-- Specify what to do with the pizza_id and value from Toppings CTE    
SELECT
    pizza_id,
    CAST(value as INT) AS topping_id

FROM  ToppingsCTE
;
*/
-- *** Use the below query if the pizza_recipes_cleaned table has not been created *** --
DROP TABLE IF EXISTS pizza_recipes_cleaned
CREATE TABLE pizza_recipes_cleaned
(
    pizza_id INT,
    topping_id INT
)
;

-- Create a CTE to split the toppings into separate rows
WITH ToppingsCTE AS 
(
    SELECT
        pizza_id,
        value
    FROM
        pizza_recipes
    CROSS APPLY STRING_SPLIT(CONVERT(nvarchar(MAX), toppings), ',')
)

-- Insert the values after the INSERT INTO into a new table
INSERT INTO pizza_recipes_cleaned

-- Specify what to do with the pizza_id and value from Toppings CTE    
SELECT
    pizza_id,
    CAST(value as INT) AS topping_id

FROM  ToppingsCTE;

-- Check the new table
select * from pizza_recipes_cleaned;

-- *** Use the above query if the pizza_recipes_cleaned table has not been created *** --



-- COUNT each row and GROUP BY pizza to join with table in previous question
WITH sumtoppingscte AS (
    SELECT
        pizza_id
        ,[sum_toppings] = COUNT(*)
    FROM pizza_recipes_cleaned
    GROUP BY pizza_id
)

-- Bring the aggregates of pizza from the previous question
SELECT
     [Pizza type] = co.pizza_id
    ,[Revenue] = (COUNT(*)) * ( CASE WHEN co.pizza_id = 1 THEN 12 ELSE 10 END )
    ,[sum_toppings]

        
FROM dbo.customer_orders co
JOIN sumtoppingscte stc
    on co.pizza_id = stc.pizza_id
GROUP BY co.pizza_id, stc.pizza_id;