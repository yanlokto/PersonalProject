# Pizza sales data in 2015 https://www.kaggle.com/datasets/michaeldsouza16/sql-analysis-using-pizass-data-set?select=order_details.csv

/*

Objectives and insights
The dataset contains pizza sales data from 5 datasets including orders (in time series) and information on different types of pizza 
It is therefore suitable to perform revenue analysis and identify customer behaviors in the pizza industry. 
Below are SQL codes for exploring data. Graphs and visualizations can be found at https://public.tableau.com/app/profile/lok.to.yan/vizzes

Revenue analysis:
Total revenue gradually increased in the first half of 2015, reached the top in July and declined sharply after July.
In general, sales revenue fluctuated a lot in 2015. Performances in even-number months are worse than previous odd-number months (eg. Performance in Feb is worse than Jan), 
If the company targets a steadily increasing revenue, it needs to target its strategies in 
even-number months to optimize the firm's sales revenue. 

Regarding revenue by products, "Top 3" of the pizzas are The Thai Chicken Pizza, The Barbecue Chicken Pizza and The California Chicken Pizza, and 
"Bottom 3" are The Spinach Supreme Pizza, The Green Garden Pizza and The Brie Carre Pizza. 

Customer preferences:

1. Types of Pizza
-Majority of customers order 1-4 pizzas each time. The proportions of ordering 1,2,3 and 4 pizzas are 0.38, 0.29, 0.15 and 0.15 respectively.
-Customer orders at most 28 pizzas in an order.
-Consider orders with 2 purchased items, many customers prefer to order small-sized Big Meat Pizza with other pizza. 
Large-sized Thai Chicken and Five Cheese Pizza are also popular choices.

The above findings help the company develop bundling strategies, increasing customer's loyalty and satisfaction ideally. 
The company can use the filtered data to forecast quantities of different types of pizzas.

2. Ingredients of Pizza
-Garlic, tomatoes, red onions and red peppers are the most common ingredients. 

These are fundamental toppings widely used in pizzas. The taste of most pizzas, thus branding and competitiveness of the company depends on 
the quality of these ingredients. The company should therefore emphasize the supplier sourcing of these ingredients.
For example, highlighting premium ingredients: Fresh and natural Roma tomatoes used in pizzas would differentiate their offerings from competitors. 

*/


# What is the monthly total revenue of pizza orders?
SELECT 
  Month(date) AS month, 
  (round(SUM(quantity*price),2)) AS monthly_revenue,
  sum(quantity) AS total_quantity
FROM order_details
JOIN orders 
  ON order_details.order_id=orders.order_id #Extract order date
JOIN pizza_details 
  ON order_details.pizza_id=pizza_details.pizza_id #Extract product price
GROUP BY month;

# Which pizza generate the most revenue?
SELECT 
  name, 
  ROUND(SUM(price*quantity),2) AS revenue_by_product,
  SUM(quantity) AS quantity_sold 
FROM order_details
JOIN pizza_details 
  ON order_details.pizza_id=pizza_details.pizza_id
JOIN pizza_types 
  ON pizza_details.pizza_type_id=pizza_types.pizza_type_id # Extract pizza name
GROUP BY name
ORDER BY 2 DESC;


# What product bundling preferences do cusomters have?
WITH distinct_pizza_order AS(
  SELECT 
    DISTINCT order_id, 
    SUM(quantity) OVER (PARTITION BY order_id) AS pizza_ordered 
  FROM order_details)
SELECT 
  pizza_ordered, 
  count(pizza_ordered) count, 
  count(pizza_ordered)/
    (SELECT count(*) 
    FROM distinct_pizza_order) proportion
FROM distinct_pizza_order
GROUP BY pizza_ordered
ORDER BY 1;

WITH order_summary AS(
  SELECT 
   DISTINCT order_id, 
   SUM(quantity) OVER (PARTITION BY order_id) AS pizza_ordered, 
   pizza_id 
  FROM order_details
),
order_two_pizzas AS(
  SELECT order_id,pizza_id 
   FROM order_summary
   WHERE pizza_ordered=2 # select orders with 2 purchased items
),
pizaa_list AS (
  SELECT order_id, 
   group_concat(pizza_id separator ', ') AS group_pizza_id # list of pizzas
  FROM order_two_pizzas
  GROUP BY order_id
)
SELECT group_pizza_id, 
  COUNT(group_pizza_id) count
FROM pizaa_list 
WHERE group_pizza_id Like '%big_meat_s%' # filter pizza_type
GROUP BY group_pizza_id
ORDER BY 2 DESC;

# What are the preferred ingredients of pizzas among customers?
WITH quantity_ingredient AS(
SELECT quantity, ingredient1, ingredient2, ingredient3, ingredient4, ingredient5, ingredient6, ingredient7, ingredient8 
FROM order_details
JOIN pizza_details # Join tables to extract quantity and ingredient data
  ON order_details.pizza_id=pizza_details.pizza_id
JOIN pizza_types
  ON pizza_details.pizza_type_id=pizza_types.pizza_type_id
),
ingredient AS(
SELECT 
  DISTINCT ingredient1,
  quantity,
  COUNT(ingredient1) OVER (PARTITION BY ingredient1, quantity) AS count # Count partition by ingredients and quantity
FROM quantity_ingredient 
WHERE ingredient1 <> '' 
UNION ALL # Use Union to combine countings of different columns
# Union "All" Include duplicates, in case any ingredient name and quantity of different columns are the same
SELECT 
  DISTINCT ingredient2,
  quantity,
  COUNT(ingredient1) OVER (PARTITION BY ingredient2, quantity)
FROM quantity_ingredient 
WHERE ingredient2 <> ''
UNION ALL # Union all the ingredient columns
SELECT DISTINCT ingredient3, quantity,COUNT(ingredient3) OVER (PARTITION BY ingredient3, quantity) 
# Use Select distinct to remove duplicate rows after counting
  FROM quantity_ingredient 
  WHERE ingredient3 <> ''
UNION ALL
SELECT DISTINCT ingredient4, quantity, COUNT(ingredient4) OVER (PARTITION BY ingredient4, quantity) 
  FROM quantity_ingredient 
  WHERE ingredient4 <> ''
UNION ALL
SELECT DISTINCT ingredient5, quantity, COUNT(ingredient5) OVER (PARTITION BY ingredient5, quantity) 
  FROM quantity_ingredient 
  WHERE ingredient5 <> ''
UNION ALL
SELECT DISTINCT ingredient6, quantity, COUNT(ingredient6) OVER (PARTITION BY ingredient6, quantity) 
  FROM quantity_ingredient 
  WHERE ingredient6 <> ''
UNION ALL
SELECT DISTINCT ingredient7, quantity, COUNT(ingredient7) OVER (PARTITION BY ingredient7, quantity) 
  FROM quantity_ingredient 
  WHERE ingredient7 <> ''
UNION ALL
SELECT DISTINCT ingredient8, quantity, COUNT(ingredient8) OVER (PARTITION BY ingredient8, quantity) 
  FROM quantity_ingredient 
  WHERE ingredient8 <> '')
SELECT 
  DISTINCT TRIM(ingredient1) AS ingredient_name,
  SUM(count*quantity) OVER (PARTITION BY TRIM(ingredient1)) AS total_number # Sum partition by ingredients
FROM ingredient
ORDER BY 2 DESC;
# Top 3 Ingredients: Garlic(27913 tiems), Tomatoes(27052 times), Red Unions(19834 times) & Red Peppers(16562 times)


