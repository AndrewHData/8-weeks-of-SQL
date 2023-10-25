/* CLEANING THE RUNNER_ORDERS TABLE */

-- For the customers_orders table, I already changed the "orders_time" field into a DATETIME from TIMESTAMP as it was producing an error whenever I tried to execute the query.

--------------------------------------------------------------------------------
  -- Below is code that will create a function to remove non-numeric characters
CREATE Function [dbo].[RemoveNonNumericCharacters](@Temp VarChar(1000))
Returns VarChar(1000)
AS
Begin

	While PatIndex('%[^0-9]%', @Temp) > 0
		Set @Temp = Stuff(@Temp, PatIndex('%[^0-9]%', @Temp), 1, '')

	Return @Temp
End
--------------------------------------------------------------------------------

  -- Below is code that will create a function to keep numeric characters. Includes decimal point and negative sign .-
Create Function dbo.GetNumbers(@Data VarChar(8000))
Returns VarChar(8000)
AS
Begin	
    Return Left(
             SubString(@Data, PatIndex('%[0-9.-]%', @Data), 8000), 
             PatIndex('%[^0-9.-]%', SubString(@Data, PatIndex('%[0-9.-]%', @Data), 8000) + 'X')-1)
End

--------------------------------------------------------------------------------
/* Creating tables for cleaned data */

/* Cleaning the runner_orders table */

-- Specify the database
USE pizza_runner
;

-- Creating a new table for the cleaned runner_orders
DROP TABLE IF EXISTS runner_orders_cleaned
CREATE TABLE runner_orders_cleaned
(
   order_id INT,
   runner_id INT,
   pickup_time DATETIME,
   distance_km FLOAT,
   duration_mins INT,
   cancellation VARCHAR(50) 

)

-- Insert the values after the INSERT INTO into the temp table
INSERT INTO runner_orders_cleaned

-- Change/Clean/Convert the values so that they match the datatype in the temp table
SELECT
    CAST(r.order_id AS INT) as order_id,
    CAST(r.runner_id AS INT) as runner_id,
    pickuptime = CASE WHEN r.pickup_time = 'null' THEN NULL ELSE CONVERT(DATETIME,r.pickup_time) END,
    distance = CASE WHEN r.distance = 'null' THEN NULL ELSE master.dbo.GetNumbers(r.distance) END,
    duration = CASE WHEN r.duration = 'null' THEN NULL ELSE master.dbo.GetNumbers(r.duration) END,
    cancellation = CASE WHEN r.cancellation = 'null' OR r.cancellation = '' THEN NULL ELSE r.cancellation END

FROM runner_orders r
;

-- Truncate temp table if required
TRUNCATE TABLE runner_orders_cleaned;

-- Test out the temp table
SELECT * FROM runner_orders_cleaned;

SELECT * FROM runner_orders;
---------------------------------------------------------------------------
/* Cleaning the pizza_recipes table */
-- Best to cross tab/pivot the table 
-- Create the new temp table for cleaned pizza_recipes data 
DROP TABLE IF EXISTS pizza_recipes_cleaned
CREATE TABLE pizza_recipes_cleaned
(
    pizza_id INT,
    topping_id INT
)


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
-- Test out the  temp table
Select * from pizza_recipes_cleaned;

---------------------------------------------------------------------------
/* Updating metadata in the pizza_names table because TEXT datatype doesn't exist on SQL Server */

-- Step 1: Create a new column with a temporary name
ALTER TABLE pizza_names
ALTER COLUMN pizza_name_new VARCHAR(255);

-- Step 2: Copy data from the old column to the new column
-- Example: Changing an INT column to a VARCHAR
UPDATE pizza_names
SET pizza_name_new = CAST(pizza_name AS VARCHAR(255));

-- Step 3: Drop the old column 
ALTER TABLE pizza_names
DROP COLUMN pizza_name;

-- Step 4: Rename the new column to the original column name
EXEC sys.sp_rename 'pizza_names.pizza_name_new', 'pizza_name', 'COLUMN';

-- Check the table
SELECT * FROM pizza_names
 
---------------------------------------------------------------------------
/* Updating the customer_orders table to change '' and 'null' into NULL */

-- Update the exclusions column
UPDATE customer_orders
SET exclusions =    CASE
                    WHEN exclusions = '' 
                        OR exclusions = 'null'
                    THEN NULL
                    ELSE exclusions
                    END
;

-- Update the extras column
UPDATE customer_orders
SET extras =    CASE
                WHEN extras = '' 
                    OR extras = 'null'
                THEN NULL
                ELSE extras
                END
;

---------------------------------------------------------------------------
