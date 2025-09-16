-- 1. Customer Segmentation:

--- 1.1 RFM Analysis

---- 1.1.a Recency (Days since the last order):
SELECT 
customerid,
julianday(DATE('now')) - julianday(DATE(MAX(orderdate))) AS Recency_Days
FROM Orders
GROUP BY customerid
ORDER BY Recency_Days


--- 1.1.a Recency Based on Dataset's Last Order Date
SELECT 
customerid,
julianday((select (date(max(orderdate))) from orders)) - julianday(DATE(MAX(orderdate))) AS Recency_Days
FROM Orders
GROUP BY customerid
ORDER BY Recency_Days
    
--- 1.1.b: Frequency: Total number of orders (volumn). 
select 
customerid, 
count(orderid) as Frequency
from Orders
group by 1
order by 2

--1.1.c: Monetary Value: Total amount spent (revenue)
select 
customerid,
round(Sum((unitprice * quantity ) * (1 - discount))) as RevenuePerCustomer
from Orders
inner join "Order Details"
on orders.OrderID = "Order Details"."OrderID"
group by 1 
order by 2

--1.1.d: Create at least 3 customer segments
--create RFM view
create view RFM as 
SELECT 
o.customerid,
julianday((select (date(max(orderdate))) from orders)) - julianday(DATE(MAX(orderdate))) AS Recency_Days,
COUNT(DISTINCT o.orderid) AS Frequency,
ROUND(SUM((od.unitprice * od.quantity) * (1 - od.discount))) AS RevenuePerCustomer
FROM Orders o
INNER JOIN "Order Details" od 
ON o.OrderID = od."OrderID"
GROUP BY o.customerid

--create segments
SELECT 
    CASE
        WHEN Recency_Days <= 31 AND Frequency >= 170 AND RevenuePerCustomer >= 5500000 THEN 'Champion'
        WHEN (Frequency >= 170) OR (RevenuePerCustomer >= 5500000) THEN 'Potential Loyalist'
        ELSE 'At Risk'
    END AS Segment,
    COUNT(customerid) AS CustomerCount
FROM RFM
GROUP BY Segment
ORDER BY CustomerCount DESC
  
---- 1.2: Order Value:  

--Create CustomerOrderValue views
create view CustomerOrderValue as 
SELECT 
o.customerid,
AVG((od.UnitPrice * od.Quantity) * (1 - od.Discount)) AS AvgOrderValue
FROM "Order Details" od
INNER JOIN Orders o 
ON od.orderid = o.orderid
GROUP BY 1
order by 2 

-- Select customer order value segments
SELECT
  CASE
    WHEN AvgOrderValue BETWEEN 710 AND 730 THEN 'Low Value'
    WHEN AvgOrderValue BETWEEN 730 AND 750 THEN 'Medium Value'
    ELSE 'High Value'
  END AS OrderValueSegment,
  count(customerid) AS CustomerCount
FROM CustomerOrderValue
group by 1
ORDER BY 1

-- 2.Product Analysis:
---2.1 High Revenue Value: Identify the top 10 revenue generator products.
select 
productname,
ROUND(SUM((od.unitprice * od.quantity) * (1 - od.discount))) AS TotalRevenuePerProduct
from "Order Details" od
inner join Products p
on od.productid = p.ProductID
GROUP by 1 
order by 2 desc
limit 10

--2.2 High Sales Volume: Determine the top 10 most frequently ordered products.
select 
productname,
count(od.orderid) as QuantityPerProduct
from "Order Details" od
inner join Products p
on od.productid = p.ProductID
GROUP by 1 
order by 2 desc
limit 10

--2.3 Slow Movers: Identify products with low sales volume. (5 product)
select 
productname,
ROUND(SUM((od.unitprice * od.quantity) * (1 - od.discount))) AS TotalRevenuePerProduct
from "Order Details" od
inner join Products p
on od.productid = p.ProductID
GROUP by 1 
order by 2 
limit 5

-- 3.Order Analysis:

--3.1 Seasonality: Identify any seasonal fluctuations in order volume.
-- by month
select 
STRFTIME('%m', OrderDate) as "Month",
count(orderid) as "Order volume"
from orders
GROUP by "Month"
ORDER by "Month"

-- 3.2 Day-of-the-Week Analysis: Determine the most popular order days.
SELECT 
STRFTIME('%w', OrderDate) AS "DayOfWeek", 
COUNT(orderid) AS "OrderCount"
FROM Orders
GROUP BY "DayOfWeek"
ORDER BY "DayOfWeek"

--3.3 Order Size Analysis: Analyze the distribution of order quantities.
-- Create View for Total Quantity per Order
create view TotalOrderQuantity as 
SELECT orderid,
SUM(quantity) AS TotalOrderQuantity
FROM "Order Details"
GROUP BY 1

-- Categorize Orders into Segments
SELECT 
    CASE 
        WHEN TotalOrderQuantity <= 500 THEN 'Small Order'
        WHEN TotalOrderQuantity BETWEEN 500 AND 1000 THEN 'Medium Order'
        ELSE 'Large Order'
    END AS OrderSizeCategory,
    COUNT(*) AS OrderCount
FROM TotalOrderQuantity
group by 1

-- 4.Order Analysis:

-- 4.1 Total Revenue Generated Per Employee
select
o.employeeid,
ROUND(SUM((od.unitprice * od.quantity) * (1 - od.discount))) AS TotalRevenuePerEmployee
from "order details" od
inner join Orders o
on od.orderid = o.OrderID
group by 1
order by 1

--4.2 Total Sales Volume (Number of orders processed).
select
employeeid,
count(orderid) AS TotalOrdersPerEmployee
from Orders
group by 1
order by 1

--4.3 Average order value.
select
o.employeeid,
ROUND(avg((od.unitprice * od.quantity) * (1 - od.discount))) AS TotalRevenuePerEmployee
from "order details" od
inner join Orders o
on od.orderid = o.OrderID
group by 1
order by 1

