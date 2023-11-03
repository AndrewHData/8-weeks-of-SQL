/*
-- 1. What are the standard ingredients for each pizza?
-- 2. What was the most commonly added extra?
-- 3. What was the most common exclusion?
-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
    - Meat Lovers
    - Meat Lovers - Exclude Beef
    - Meat Lovers - Extra Bacon
    - Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
*/

-- Ensure we are using the right database
USE pizza_runner;



/* 1. What are the standard ingredients for each pizza? */
-- Simple version --
SELECT
    pn.pizza_name as [Pizza Type],
    pt.topping_name as [ToppingS]

FROM pizza_recipes_cleaned prc
    JOIN pizza_names pn
        ON prc.pizza_id = pn.pizza_id
    JOIN pizza_toppings pt
        ON prc.topping_id = pt.topping_id
;


-- Using STUFF and FOR XML PATH to make cross tab as a string list --
SELECT
    pn.pizza_name as [Pizza Type],
    ToppingS = STUFF(
        (
            SELECT 
                ', ' + CAST(pt.topping_name AS VARCHAR)
            
            FROM pizza_toppings pt
            WHERE pt.topping_id IN  (
                                        SELECT prc.topping_id
                                        FROM pizza_recipes_cleaned prc
                                        WHERE prc.pizza_id = pn.pizza_id
                                    )
            FOR XML PATH ('')
        ),
        1,
        2,
        ''
    )
FROM pizza_names pn;


/* 2. What was the most commonly added extra? */
-- Simple table
SELECT CAST(VALUE AS INT) as [Extra]
FROM customer_orders co
CROSS APPLY STRING_SPLIT(extras, ',')
;


-- Answering question fully with SQL
-- Create table, order by times ordered in descending and take top one
SELECT TOP 1
    pt.topping_name as [Most common topping added],
    COUNT(pt.topping_id) as [Times ordered]

FROM (
    SELECT CAST(VALUE AS INT) as [Extra]
    FROM customer_orders co
    CROSS APPLY STRING_SPLIT(extras, ',')
    ) c

    LEFT JOIN pizza_toppings pt
        ON c.Extra = pt.topping_id

GROUP BY pt.topping_name

ORDER BY [Times ordered] DESC
;


/* 3. What was the most common exclusion? */
-- Simple table
SELECT CAST(VALUE AS INT) as [Extra]
FROM customer_orders co
CROSS APPLY STRING_SPLIT(extras, ',')
;


-- Answering question fully with SQL
-- Create table, order by times ordered in descending and take top one
SELECT TOP 1
    pt.topping_name as [Most common topping excluded],
    COUNT(pt.topping_id) as [Times ordered]

FROM (
    SELECT CAST(VALUE AS INT) as [Exclusion]
    FROM customer_orders co
    CROSS APPLY STRING_SPLIT(exclusions, ',')
    ) c

    LEFT JOIN pizza_toppings pt
        ON c.Exclusion = pt.topping_id

GROUP BY pt.topping_name

ORDER BY [Times ordered] DESC
;


/* 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
    - Meat Lovers
    - Meat Lovers - Exclude Beef
    - Meat Lovers - Extra Bacon
    - Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
*/

-- Consider creating separate tables for exclusions and extras, then combining the tables via a unique id

-- Add unique id to customer orders table for each row and insert into temp table

SELECT
    ROW_NUMBER() OVER (ORDER BY order_time ASC) as [row_id],
    * 

INTO #customer_orders
FROM customer_orders;

select * from #customer_orders;
-- Use this table to check
select * from pizza_toppings;