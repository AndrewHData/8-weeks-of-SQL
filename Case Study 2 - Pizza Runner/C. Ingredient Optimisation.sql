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
    pt.topping_name as [Toppings]

FROM pizza_recipes_cleaned prc
    JOIN pizza_names pn
        ON prc.pizza_id = pn.pizza_id
    JOIN pizza_toppings pt
        ON prc.topping_id = pt.topping_id
;


-- Using STUFF and FOR XML PATH to make cross tab as a string list --
SELECT
    pn.pizza_name as [Pizza Type],
    Toppings = STUFF(
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

select extras from customer_orders;



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

/* Exclusions */

-- Use split_string on exclusions and create new table for exclusions
SELECT
    row_id,
    order_id,
    pizza_id,
    CAST(VALUE as INT) as [exclusions2]

INTO #exc1

FROM #customer_orders
CROSS APPLY STRING_SPLIT(exclusions, ',');

select * from #exc1;

-- Join to get names of pizzas and their toppings
SELECT 
    e.row_id,
    order_id,
    n.pizza_name as pizza_name,
    t.topping_name as exclusions

INTO #exc2

FROM #exc1 e
    INNER JOIN pizza_names n
        ON e.pizza_id = n.pizza_id
    INNER JOIN pizza_toppings t
        ON e.exclusions2 = t.topping_id;

-- Drop #exc1 temp table. Check temp table #exc2
DROP TABLE #exc1;

SELECT * FROM #exc2;

-- Concatenate #exc2
SELECT
    e1.row_id,
    e1.order_id,
    e1.pizza_name,
    STUFF(
            (
            SELECT ', ' + e2.exclusions
            FROM #exc2 AS e2
            WHERE e1.row_id = e2.row_id
            FOR XML PATH('')
            ), 
            1,
            2,
            ''
        ) as [exclusion_name]

INTO #exclusions

FROM (
    SELECT DISTINCT row_id, order_id, pizza_name 
    FROM #exc2
) AS e1;

-- Drop the second exclusion temp table #exc2 and check #exclusions
DROP TABLE #exc2;

-- We'll save the #exclusions temp table for later
SELECT * FROM #exclusions;


/* Extras */
-- Similar process to extras
-- Use split_string on exclusions and create new table for exclusions
SELECT
    row_id,
    order_id,
    pizza_id,
    CAST(VALUE as INT) as [extras2]

INTO #ext1

FROM #customer_orders
CROSS APPLY STRING_SPLIT(extras, ',');

select * from #ext1;

-- Join to get names of pizzas and their toppings
SELECT 
    e.row_id,
    e.order_id,
    n.pizza_name as pizza_name,
    t.topping_name as exclusions

INTO #ext2

FROM #ext1 e
    INNER JOIN pizza_names n
        ON e.pizza_id = n.pizza_id
    INNER JOIN pizza_toppings t
        ON e.extras2 = t.topping_id;

-- Drop #ext1 temp table. Check temp table #ext2
DROP TABLE #ext1;

SELECT * FROM #ext2;

-- Concatenate #ext2
SELECT
    e1.row_id,
    e1.order_id,
    e1.pizza_name,
    STUFF(
            (
            SELECT ', ' + e2.exclusions
            FROM #ext2 AS e2
            WHERE e1.row_id = e2.row_id
            FOR XML PATH('')
            ), 
            1,
            2,
            ''
        ) as [extra_name]
        

INTO #extras

FROM (
    SELECT DISTINCT row_id, order_id, pizza_name 
    FROM #ext2
) AS e1;

-- Drop the second exclusion temp table #exc2 and check #extras
DROP TABLE #ext2;

-- The data we want for extras!
SELECT * FROM #extras;

-- The original #customer_orders table
SELECT 
    row_id,
    order_id,
    pizza_name,
    exclusions as exclusion_name,
    extras as extra_name
FROM #customer_orders c
    INNER JOIN pizza_names n
        ON c.pizza_id = n.pizza_id

WHERE exclusions IS NULL
    AND extras IS NULL
;

/*
Use a full Join with and filter for no nulls on one table's id.
Then union with the id's that were previously filtered out.
And also union with the original #customer_orders table above.
*/
(
SELECT 
    exc.order_id as order_id,
    [Pizza ordered] =   exc.pizza_name +
                        CASE 
                        WHEN exclusion_name IS NOT NULL 
                            AND extra_name IS NOT NULL
                        THEN ' - Exclude ' + exclusion_name + ' - Extra ' + extra_name
                        WHEN exclusion_name IS NULL 
                        THEN '' 
                        WHEN exclusion_name IS NOT NULL
                        THEN ' - Exclude ' + exclusion_name
                        WHEN extra_name IS NOT NULL
                        THEN ' - Extra ' + extra_name
                        ELSE ''
                        END

FROM #exclusions exc
    FULL JOIN #extras ext
        ON exc.row_id = ext.row_id
WHERE exc.row_id IS NOT NULL
)

UNION

(
SELECT
    ext.order_id as order_id,
    [Pizza ordered] =   ext.pizza_name +
                        CASE 
                        WHEN exclusion_name IS NULL 
                        THEN '' 
                        WHEN exclusion_name IS NOT NULL
                        THEN ' - Exclude ' + exclusion_name
                        WHEN extra_name IS NULL
                        THEN ''
                        WHEN extra_name IS NOT NULL
                        THEN ' - Extra ' + extra_name
                        END
FROM #exclusions exc
    FULL JOIN #extras ext
        ON exc.row_id = ext.row_id
WHERE ext.row_id IS NOT NULL
)

UNION

(
-- The original #customer_orders table
SELECT 
    order_id,
    pizza_name as [Pizza ordered]
FROM #customer_orders c
    INNER JOIN pizza_names n
        ON c.pizza_id = n.pizza_id
WHERE exclusions IS NULL
    AND extras IS NULL
)

-- *NB* I could probably add in customer_id or something.

/*
-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
*/

