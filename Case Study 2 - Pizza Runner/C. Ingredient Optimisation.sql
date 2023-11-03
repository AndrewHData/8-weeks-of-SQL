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

/* SYNTAX FOR SPLIT STRING FOR MULTIPLE COLUMNS

SELECT t.id, s.value AS SplitColumn1, s2.value AS SplitColumn2
FROM YourTable t
CROSS APPLY STRING_SPLIT(t.Column1, ',') AS s
CROSS APPLY STRING_SPLIT(t.Column2, ',') AS s2;
*/


-- Step 1: Create a temp table with unique_id for each row
SELECT 
    ROW_NUMBER() OVER (ORDER BY order_id) as [unique_id],
    *

INTO #customer_orders

FROM customer_orders;

-- Checking the temp table
select * from #customer_orders;

-- Step 2: Start off with splitting the string 
-- *Note* The unique_id and Exclusions will be duplicated for each row.
SELECT 
    unique_id,
    v1.VALUE as [Exclusions],
    V2.VALUE as [Extras]

FROM #customer_orders co
CROSS APPLY string_split(co.exclusions, ',') as v1
CROSS APPLY string_split(co.extras, ',') as v2;


-- Step 3: Convert the Exclusion and Extras columns into INT type so we can perform sub query (in a similar way to a join, we will reference another table inthe sub-query)
SELECT 
    unique_id as [Unique ID],
    CAST(v1.VALUE AS INT) as [Exclusions],
    CAST(v2.VALUE AS INT) as [Extras]

FROM #customer_orders co
CROSS APPLY string_split(co.exclusions, ',') as v1
CROSS APPLY string_split(co.extras, ',') as v2;


-- Step 4: Now use sub-query to do the join and insert into another temp table. Don't drop the #customer_orders temp table as we'll be joining it later
SELECT
    [Unique ID],
    Exclusion_name = (SELECT topping_name FROM pizza_toppings pt WHERE coo.Exclusions = pt.topping_id),
    Extras_name = (SELECT topping_name FROM pizza_toppings pt WHERE coo.Extras = pt.topping_id)

INTO #exc_ext

FROM(
    SELECT 
    unique_id as [Unique ID],
    CAST(v1.VALUE AS INT) as [Exclusions],
    CAST(v2.VALUE AS INT) as [Extras]

    FROM #customer_orders co
    CROSS APPLY string_split(co.exclusions, ',') as v1
    CROSS APPLY string_split(co.extras, ',') as v2
) coo;


-- Check the new temp table
SELECT * FROM #exc_ext;

-- Step 4: Put back into comma separated list (many thanks to ChatGPT) and insert new values into ANOTHER temp table. Delete the #exc_ext after.
SELECT
    [Unique ID],
    STUFF(
            (
            SELECT DISTINCT
                ', ' + CAST(Exclusion_name AS VARCHAR)
            
            FROM #exc_ext as e2
            WHERE e1.[Unique ID] = e2.[Unique ID]
            FOR XML PATH ('')
        ),
        1,
        2,
        ''
    ) as [exclusions],
    STUFF(
            (
            SELECT DISTINCT
                ', ' + CAST(Extras_name AS VARCHAR)
            
            FROM #exc_ext as e3
            WHERE e1.[Unique ID] = e3.[Unique ID]
            FOR XML PATH ('')
        ),
        1,
        2,
        ''
    ) as [extras]

INTO #formatted_exc_ext

FROM (
    SELECT
        DISTINCT [Unique ID]
    FROM #exc_ext
) e1
;

-- Check to see if the new temp table has the values
SELECT * FROM #formatted_exc_ext;

-- Drop table #exc_ext
DROP TABLE #exc_ext;

-- Step 5: Join the #formatted_exc_ext with the 


-- Use this table to check
select * from pizza_toppings;


SELECT
    u.unique_id,
    t.topping_name AS exclusion_name
FROM #customer_orders u
CROSS APPLY STRING_SPLIT(u.exclusions, ',') AS t;
