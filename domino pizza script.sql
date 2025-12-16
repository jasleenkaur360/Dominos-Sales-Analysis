
-- -------------------
-- Dominos store
-- Analysis & Reports 
-- --------------------

/*1. Orders Volume Analysis Queries

Stakeholder (operations Manager):

"We are trying to understand our volume in detail so we can measure store performance and benchmark growth.
Instead of just knowing the total number of unique orders, I'd like a deeper breakown:

- What is the total number of unique order placed so far?
- How has this order volume changed month- over-month anff year over year ?
- Can we identify peak and off -peak ordering days?
- How do order volumes very by day of the week(e.g. , weekends vs weekdays)?
- What is the average number of orders per customer?
- Who are our top repeat customers driving the order volume?
- Can you also project the expected order growth trend based on historical data?"



 Analyst Tasks: 

1. Count the total number of unique orders (COUNT(DISTINCT order_id) ).
2. Break down orders by month and year (GROUP BY EXTRACT (MONTH/YEAR FROM order_date)).
3. Find day-wise order distribution (TO_CHAR(order_date,'Day')).
4. Compute average orders per customer ( COUNT( order_id)/COUNT(DISTINCT custId)).
5. Identify repeat customers and their order frequency (HAVING COUNT(order_id)>1).
6. Use window function to calculate month-over-month growth % (LAG(order_count) over _).
7. Build a trend projection using cumulative counts or forecasting methods. */

-- 1.1 
Select count(DISTINCT ORDER_ID )FROM ORDERS;

-- 1.2 (a) Month over month

WITH monthly_orders AS (
  SELECT 
    month(order_date) AS month,
    COUNT(order_id) AS order_count
  FROM orders
  GROUP BY month(order_date)
)
SELECT month,
 order_count,
 lag(order_count) OVER (order by month) as prev_month,
Round ( 
100.0 * (order_count - LAG(order_count) over(order by month)) / nullif(lag (order_count) over(order by month),0),2)  mom_growth_pct
FROM monthly_orders

ORDER BY montH;

-- (b) year-over-year 

Select * from orders;
WITH yearly_orders AS (
  SELECT 
    YEAR(order_date) AS year,
    COUNT(order_id) AS order_count
  FROM orders
  GROUP BY YEAR(order_date)
)

SELECT 
year,
order_count,
  LAG(order_count) OVER (ORDER BY year) AS prev_year,
  ROUND(
    100.0 * (order_count - LAG(order_count) OVER (ORDER BY year)) 
    / NULLIF(LAG(order_count) OVER (ORDER BY year), 0),
    2
  ) AS yoy_growth_pct
FROM yearly_orders
ORDER BY year;

-- 1.3 

-- orders by day of Week 
Select 
DAYNAME(order_date) as weekday,
COUNT(distinct order_id) as total_orders

from orders
GROUP BY DAYNAME(order_date)
order by total_orders ;

-- 1.4 
With category_orders as(
select 
case 
when dayofweek(order_date) in (1,7) then 'weekend'
ELSE 'weekday'
End as day_category,
count (order_id)as order_count
from orders
group  by day_category
)

SELECT
  day_category,
  order_count,
  LAG(order_count) OVER (ORDER BY day_category) AS prev_category_orders,
  ROUND(
    100.0 * (order_count - LAG(order_count) OVER (ORDER BY day_category))
    / NULLIF(LAG(order_count) OVER (ORDER BY day_category), 0),
    2
  ) AS change_pct
FROM category_orders;

-- 1.5 (average orders per customer )

Select
 ROUND ( ( COUNT(distinct order_id ) * 1.0 / 
  Count( distinct custid)),2) as avg_order_per_customer
from orders;

-- 1.6  (repeat customers WITH FREQUENCY)
Select 
  custid,
  count(distinct order_id) as order_count
  from orders
  group by custid
  order by order_count desc;

-- 1.7 (Cumulative Order Trends)
select  order_date,
        count(order_id) as daily_orders,
        sum(order_id) over (order by order_date) as cumlative_orders
        from orders
    group by order_date
    order by order_date;
	



/* 2. Total Revenue from Pizza Store

Stakeholder (Finance Team) : 

"We need to report monthly revenue to management.
can you calculate the total revenue generated from all pizza sales, 
considering price * quatity from each order?" 

Analyst Task : Join order_details with pizza and sum ( price * quantity). 
*/

Select * from order_details;
select * from pizzas;

Select SUM(od.quantity * p.price) as total_revenue
from order_details od
join pizzas p on od.pizza_id = p.pizza_id;

/* 3. Highest_priced pizza

stakeholder (Menu Manager):

"Our premium pizzas must be correctly priced. Can you find out which pizza
has the highest price on our menu and confirm its categoryand size?"

analyst task : query the pizza table for the maximum price, joining with pizza_type fro details.
*/

select 
pt.name,
p.size,
CONCAT('$',p.price) as price
from pizzas p
join pizza_type pt on p.pizza_type_id = p.pizza_type_id
order by p.price desc;

/* 4 Most common pizza size ordered

"To optimize packaging and raw material supply, I need to know which 
pizza size ( S,M,L, XL,XXL) is ordered the most?"

Analyst Task: Count and group orders by pizza size from pizzas * order_details

*/

-- Query:
Select p.size, count(*) as total_orders
from 
order_details od
join pizzas p on od.pizza_id = p.pizza_id
join pizza_type pt on p.pizza_type_id = pt.Pizza_type_id
group by p.size
 order by total_orders Desc;


/* 5. Top 5 Most Ordered Pizza Types

(Product Head):

" We want to promote our top-selling pizzas. can you provide the top 5 pizza types
ordered by quantity, along with the exact number of unit sold?"

Analyst task : Join order_details with pizza_type, group by pizza name, and rank top 5. 
*/

SELECT 
   p.pizza_id, 
   sum(od.quantity) as total_qty
from 
order_details od
join pizzas p on p.pizza_id = od.pizza_id
join pizza_type pt on pt.pizza_type_id = p.pizza_type_id

group by p.pizza_id
order by total_qty desc
limit 5;

/* 6  Total Quantity by Pizza Category

Marketing Manager : 
 
 " We run promotions based on categories ( classic, Veggies, Supreme, Chicken, etc.).
 Can you calculate the total number of pizzas sold in each category
 so we can plan targeted campaigns?"
 
 Analyst Task : Join Pizzas with pizza_types and sum quantities by category.
 */
 
 -- Query 
 
 Select 
 pt.category,
 sum(od.quantity) as total_qty
from
order_details od 
Join  pizzas p on od.pizza_id = p.pizza_id
join pizza_type pt on pt.pizza_type_id = p.Pizza_type_id
group by pt.category ;


/* 7. Orders by Hours of the Day

Operations Head :

"When are customers ordering the most? Do they prefer lunch (12-2 PM),
evenings (6-9 PM), or late-night? Please give me a distritution
of orders by hours of the day so we can adjust staffing."

Analyst Task: Extract the hour from the order_time in orders table and count frequency.
*/

Select 
date_format (order_time, "%H:00") as order_hour,
count(*) as order_count
from orders
Group by order_hour
order by order_hour;

/* 8. Category-Wise Pizza Distribution

CEO:

" Which categories (like Veggies, chicken, Supreme) dominate
our menu sales? Can you Prepare a breakdown of orders per category with percentage share?"

Analyst Task : Join tables and calculate share of each category. 
*/

   
SELECT 
    pt.category,
    ROUND(SUM(od.quantity * p.price), 2) AS category_revenue,
    ROUND(
        100 * SUM(od.quantity * p.price) /
        SUM(SUM(od.quantity * p.price)) OVER ()
    , 2) AS percentage_share
FROM order_details od
JOIN pizzas p 
    ON od.pizza_id = p.pizza_id
JOIN pizza_type pt 
    ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category
ORDER BY category_revenue DESC;

/* 9. Average pizzas ordered per day 

CEO: 
" I want to see if our daily demand  is concistent.
Can you group orders by date and tell me the average number of pizzas ordered per day ?"

Analyst Task : Aggregate by order_date, calculate total pizzas per day, then average. */

Select Round( AVG(daily_total),2) as avg_pizzas_per_day
from (
      Select o.order_date, Sum(od.quantity) AS daily_total
      from orders o
      join order_details od ON o.order_id = od.order_id
      group by o.order_date
      )t;

/* 10. Top 3 Pizzas by Revenue

Finance Team: 

" we need to know which pizzas are our biggest revenue drivers.
Please provide the top 3 Pizzas by revenue generated."alter

Analyst task: Calculate revenue per pizza (price * quantity) and rank top 3.
*/
  
  WITH pizza_revenue AS (
  SELECT 
    pt.name,
    SUM(od.quantity * p.price) AS revenue
  FROM order_details od
  JOIN pizzas p 
      ON od.pizza_id = p.pizza_id
  JOIN pizza_type pt 
      ON p.pizza_type_id = pt.pizza_type_id
  GROUP BY pt.name
),
ranked_pizzas AS (
  SELECT 
    name,
    revenue,
    RANK() OVER (ORDER BY revenue DESC) AS ranks
  FROM pizza_revenue
)
SELECT 
  name,
  revenue
FROM ranked_pizzas
WHERE ranks <= 3;


/* ADVANCED ANALYSIS

11. Revenue Contribution per Pizza

(CEO) :

" For our revenue mix analysis, I need to know what percentage of 
total revenue each pizza contributes.
This will show which item carry the business.'

Analyst Task : Divide revenue of each pizza by total revenue, express in %.alter
*/

-- Query

SELECT  
  pt.category,
  ROUND(SUM(od.quantity * p.price), 2) AS category_revenue,
  ROUND(
    100 * SUM(od.quantity * p.price) 
    / SUM(SUM(od.quantity * p.price)) OVER (),
    2
  ) AS pct_contribution
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_type pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category
ORDER BY category_revenue DESC;

/* 12   Cumulative revenue Over Time 

Board of Directors

"We want to see how our cumulative revenue has grown month by month since launch.
can you prepare a cumulative revenue trend time?"


Analyst Task: Aggregate revenue by date/month and calculate renning total.
*/

-- Query 

Select order_date,
Daily_revenue,
Sum (Daily_revenue) over (order by order_date) as cumulative_revenue
from ( 
     select 
     o.order_date,
     Sum(od.quantity * p.price) as daily_revenue
     from 
     orders o
     join order_details od on o.order_id = od.order_id
     join pizza p on od.pizza_id = p.pizza_id
     group by 
     o.order_date
     ) t;


/* 13

 Top 3 pizzas by category ( revenue_based )
 
 Product Head:
 
 'Within eaxh pizza category, which 3 pizza bring the most revenue?
 This will help us decide which pizza to promote or expand."
 
 Analyst Task: Partition by category, calculate revenue per pizza, rank TOP 3.
 */
 use domino_store;
 WITH cat_rank AS (
      Select pt.category, pt.name,
      Sum(od.quantity * p.price) as revenue,
      RANK() over (partition by pt.category order by SUM(od.quantity *p.price) desc) as rnk
	from order_details od
    join pizzas p on od.pizza_id = p.pizza_id
    join pizza_type pt on p.pizza_type_id = pt.pizza_type_id
    group by pt.category, pt.name 
)

SELECT category, name, revenue
from cat_rank
where rnk<= 3 ;

/* Extended Bussiness case studies

14. Top 10 customers by spending

Customer Retention Manager  :
 "Who are our top 10 customers based on totel spend? 
 we want to reward them with loyalty offers ! "
 
 */
SELECT 
    c.custid,
    concat( c.first_name, ' ' , c.last_name) AS name,
    SUM(od.quantity * p.price) AS total_spent
FROM
    Customers c
        JOIN
    orders o ON c.custid = o.custid
        JOIN
    order_details od ON o.order_id = od.order_id
        JOIN
    pizzas p ON od.pizza_id = p.pizza_id
GROUP BY c.custid , name
ORDER BY total_spent DESC
LIMIT 10;
 
 
/* 15. Orders by Weekday

Marketing Team : 
"Which days of the week are the busiest for orders?
Do customers order more on weekends?"

*/
SELECT 
    DAYNAME(order_date) AS weekday,
    COUNT(*) AS total_orders
FROM orders
GROUP BY DAYNAME(order_date), DAYOFWEEK(order_date)
ORDER BY DAYOFWEEK(order_date) desc;

/* 16. Average Order Size 

Supply Chain Manager :

" What's the average number of pizzas per order?
This help us in planning inventory and staffing."

*/
Select 
 round( avg(order_size), 0) as avg_order_size
from 
  ( 
  select 
  od.order_id,
  SUM(od.quantity) as order_size
  from order_details od
  group by od.order_id
  )as t;
  
  /* 17.  Seasonal Trends
  
  Stakeholder (Finance Head) :
 
 " Do we see peak sales in certain months or holidays?
 This will help us manage seasonal demand."
 
 */
 
 Select extract(month from order_date) as month,
 count(*) as total_orders
 from orders
 group by extract( month from order_date)
 order by month ;
 



 