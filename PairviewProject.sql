-- Proving shift toward digital

select distinct a.ProductID, a.SalesOrderID, 
	   c.Name , e.Name as Category, d.Name as SubCategory, 
	   a.OrderQty, c.StandardCost, 
	   (a.OrderQty*c.StandardCost) as TotalCost,
	   c.ListPrice, -- Selling price
	   a.UnitPrice, -- Selling price of single product
	   a.UnitPriceDiscount as Discount_Percent, 
	   (a.UnitPrice * a.UnitPriceDiscount * a.OrderQty) as TotalDiscount, h.Description,
	   a.LineTotal as Revenue, (a.LineTotal - (a.OrderQty*c.StandardCost)) as Profit, 
	   f.Name as Location,  f.[Group] as Area, b.OrderDate, 
	   case when b.OnlineOrderFlag = 0 then 'Reseller' else 'Online' end as Channel
from sales.SalesOrderDetail as a
join Sales.SalesOrderHeader as b
on a.SalesOrderID = b.SalesOrderID
join production.Product as c
on c.ProductID = a.ProductID
join Production.ProductSubcategory as d
on c.ProductSubcategoryID = d.ProductSubcategoryID
join Production.ProductCategory as e
on d.ProductCategoryID = e.ProductCategoryID
join Sales.SalesTerritory as f
on b.TerritoryID = f.TerritoryID
join sales.SpecialOfferProduct as g
on a.SpecialOfferID = g.SpecialOfferID
join sales.SpecialOffer as h
on g.SpecialOfferID = h.SpecialOfferID


-- Proving change in customer demographic

SELECT a.CustomerID, a.salesorderID,
case when a.OnlineOrderFlag = 1 then 'Online' else 'Reseller' end as Channel,
concat(b.FirstName, ' ', b.LastName) as FullName,
b.BirthDate, Floor(DateDiff(DD, b.BirthDate, GetDate()) / 365.25) as Age,
case when Floor(DateDiff(DD, b.BirthDate, GetDate()) / 365.25) >= 70 then 'Over 70s'
when Floor(DateDiff(DD, b.BirthDate, GetDate()) / 365.25) >= 60 then '60s'
when Floor(DateDiff(DD, b.BirthDate, GetDate()) / 365.25) >= 50 then '50s'
when Floor(DateDiff(DD, b.BirthDate, GetDate()) / 365.25) > 40 then '40s'
when Floor(DateDiff(DD, b.BirthDate, GetDate()) / 365.25) > 30 then '30s'
else 'Under 30' end as AgeRange,
b.MaritalStatus, b.Gender, b.TotalChildren, b.YearlyIncome,
b.EnglishEducation, b.EnglishOccupation, 
cast(a.OrderDate as date) as OrderDate, b.DateFirstPurchase,
b.CommuteDistance, b.NumberCarsOwned
from sales.SalesOrderHeader as a
left join [AdventureWorksDW2017].[dbo].[DimCustomer] as b
on a .CustomerID = b.CustomerKey
order by CustomerID, OrderDate


-- Purchasing from vendors

select c.ProductID, a.PurchaseOrderID,
	   d.Name as Product_Name,
	   b.OrderQty, b.UnitPrice, b.LineTotal, b.ReceivedQty, b.RejectedQty,
	   a.OrderDate,b.DueDate, a.ShipDate ,
	   c.AverageLeadTime,	 -- Days between placing an order with the vendor and receiving the purchased product
	   case when a.ShipDate > b.DueDate then cast((a.ShipDate - b.DueDate) as int) else 0 end as DaysItemDelay,
	   e.name as Shipping_Method, e.ShipBase, e.ShipRate, a.Freight,
	   f.Name as Vendor, f.PreferredVendorStatus,	 -- 1 Preferred over other vendors
	   f.ActiveFlag as Actively_used	-- 1 Vendor actively used
from Purchasing.PurchaseOrderHeader as a
join Purchasing.PurchaseOrderDetail as b
on a.PurchaseOrderID = b.PurchaseOrderID
join Purchasing.ProductVendor as c
on b.ProductID = c.ProductID
join Production.Product as d
on c.ProductID = d.ProductID
join Purchasing.ShipMethod as e
on e.ShipMethodID = a.ShipMethodID
join Purchasing.vendor as f
on f.BusinessEntityID = a.VendorID
where d.MakeFlag = 0	-- where Product is purchased and not manufactured in house 
order by DaysItemDelay desc


-- Manufacturing

select c.ProductID, a.WorkOrderID,
	   c.name as Product, 
	   a.OrderQty as QtytoBuild, a.ScrappedQty, d.name as ScrapReason,
	   b.ScheduledStartDate, b.ActualStartDate, 
	   case when b.ActualStartDate > b.ScheduledStartDate then cast((b.ActualStartDate - b.ScheduledStartDate) as int) else 0 end as DaysStartDelay,
	   b.ScheduledEndDate, b.ActualEndDate, 
	   case when b.ActualEndDate > b.ScheduledEndDate then cast((b.ActualEndDate - b.ScheduledEndDate) as int) else 0 end as DaysEndDelay,
	   cast((b.ActualEndDate - b.ActualStartDate) as int) as ActualDaysToManufact,
	   cast((b.ScheduledEndDate - b.ScheduledStartDate) as int) as PlannedDaystoManufact,
	   e.Name as ManufactLocation,
	   b.ActualResourceHrs, b.PlannedCost, b.ActualCost,
	   case when b.ActualCost > b.PlannedCost then b.ActualCost - b.PlannedCost else 0 end as CostOutBudget
from Production.WorkOrder as a
join Production.WorkOrderRouting as b
on a.WorkOrderID = b.WorkOrderID
join Production.Product as c
on b.ProductID = c.ProductID
left join Production.ScrapReason as d
on d.ScrapReasonID = a.ScrapReasonID
join Production.Location as e
on e.LocationID = b.LocationID


-- Delivery of Products

select a.SalesOrderID, c.ProductID, 
       c.Name,
	   a.OrderDate, a.DueDate, a.ShipDate,
	   case when a.ShipDate > a.DueDate then cast((a.ShipDate - a.DueDate) as int) else 0 end as DaysDeliveryDelay,
	   case when a.ShipDate < a.DueDate then cast((a.DueDate - a.ShipDate) as int) else 0 end as DaystoDeliver,
	   e.City, d.Name as CountryRegion, d.CountryRegionCode,
	   f.Name as ShippingCompany
from sales.SalesOrderHeader as a 
left join Sales.SalesOrderDetail as b
on a.SalesOrderID = b.SalesOrderID
left join Production.Product as c
on b.ProductID = c.ProductID
join Sales.SalesTerritory as d
on d.TerritoryID = a.TerritoryID
join Person.Address as e
on a.ShipToAddressID = e.AddressID
join Purchasing.ShipMethod as f
on f.ShipMethodID = a.ShipMethodID


-- Market Basket Analysis, online only

select a.SalesOrderID, b.Name
from Sales.SalesOrderDetail as a
join Production.Product as b
on a.ProductID = b.ProductID
join Sales.SalesOrderHeader as c
on c.SalesOrderID = a.SalesOrderID
where c.OnlineOrderFlag = 1
order by 1 


select x.Product, AVG(x.AvgPrice) as AvgPrice, AVG(x.QuantitySold) as AvgQuantitySold,
       AVG(x.AvgCost) as AvgCost, (AVG(x.AvgPrice) - AVG(x.AvgCost)) as AvgProfit
from(
select b.Name as Product, format(c.OrderDate, 'MM-yyyy') as Date,
	   sum(OrderQty) as QuantitySold,
	   avg(unitPrice) as AvgPrice,
	   avg(b.StandardCost) as AvgCost
from Sales.SalesOrderDetail as a
join Production.Product as b
on a.ProductID = b.ProductID
join Sales.SalesOrderHeader as c
on c.SalesOrderID = a.SalesOrderID
where c.OnlineOrderFlag = 1
group by b.name, format(c.OrderDate, 'MM-yyyy')
) as x
group by x.Product


-- Forecast tables:

-- Reseller:

-- Per Quarter

select datepart(YEAR, b.OrderDate) as Year, 
	   datepart(QUARTER, b.OrderDate) as Quarter, 
	   sum(a.LineTotal) as Revenue
from sales.SalesOrderDetail as a
left join Sales.SalesOrderHeader as b
on a.SalesOrderID = b.SalesOrderID
left join Sales.SalesTerritory as c
on b.TerritoryID = c.TerritoryID
where b.OnlineOrderFlag = 0 and c.Name = 'Central'
group by datepart(YEAR, b.OrderDate), datepart(QUARTER, b.OrderDate), c.Name
order by 1,2 

-- Per Month

select datepart(YEAR, b.OrderDate) as Year, datepart(MONTH, b.OrderDate) as Month, 
	   sum(a.LineTotal) as Revenue
from sales.SalesOrderDetail as a
left join Sales.SalesOrderHeader as b
on a.SalesOrderID = b.SalesOrderID
left join Sales.SalesTerritory as c
on b.TerritoryID = c.TerritoryID
where b.OnlineOrderFlag = 0 and c.Name = 'Central'
group by datepart(YEAR, b.OrderDate), datepart(MONTH, b.OrderDate), c.Name
order by 1, 2


-- b. Online:

-- Per Quarter

select datepart(YEAR, b.OrderDate) as Year, datepart(QUARTER, b.OrderDate) as Quarter,
	   sum(a.LineTotal) as Revenue
from sales.SalesOrderDetail as a
left join Sales.SalesOrderHeader as b
on a.SalesOrderID = b.SalesOrderID
left join Sales.SalesTerritory as c
on b.TerritoryID = c.TerritoryID
where b.OnlineOrderFlag = 1 and c.Name = 'Germany'
group by datepart(YEAR, b.OrderDate), c.Name, datepart(QUARTER, b.OrderDate)
order by 1, 2

-- Per Month

select datepart(YEAR, b.OrderDate) as Year, datepart(MONTH, b.OrderDate) as Month, 
	   sum(a.LineTotal) as Revenue
from sales.SalesOrderDetail as a
left join Sales.SalesOrderHeader as b
on a.SalesOrderID = b.SalesOrderID
left join Sales.SalesTerritory as c
on b.TerritoryID = c.TerritoryID
where b.OnlineOrderFlag = 1 and c.Name = 'Germany'
group by datepart(YEAR, b.OrderDate), datepart(MONTH, b.OrderDate), c.Name
order by 1, 2


-- Sales Reasons per year

select T1.year as Year,
       cast(sum(T1.SalesReason_Manufacturer) as float)/cast(count(t1.SalesOrderID) as float)*100 as Manufacturer_reason, 
       cast(sum(T1.SalesReason_Other)as float)/cast(count(t1.SalesOrderID)as float)*100 as Other_reason,
       cast(sum(t1.SalesReason_Price)as float)/cast(count(t1.SalesOrderID)as float)*100 as Price_reason, 
	   cast(sum(t1.SalesReason_Promotion)as float)/cast(count(t1.SalesOrderID)as float)*100 as Promotion_reason,
	   cast(sum(t1.SalesReason_Quality)as float)/cast(count(t1.SalesOrderID)as float)*100 as Quality_reason, 
	   cast(sum(t1.SalesReason_Review)as float)/cast(count(t1.SalesOrderID)as float)*100 as Review_reason,
	   cast(sum(t1.SalesReason_TV)as float)/cast(count(t1.SalesOrderID)as float)*100 as TV_reason
from(
SELECT 
year(C.OrderDate) as Year, A.[SalesOrderID]
,CASE WHEN B.[Name] = 'Price' THEN 1 ELSE 0 END AS SalesReason_Price
,CASE WHEN B.[Name] = 'Quality' THEN 1 ELSE 0 END AS SalesReason_Quality
,CASE WHEN B.[Name] = 'Review' THEN 1 ELSE 0 END AS SalesReason_Review
,CASE WHEN B.[Name] = 'Other' THEN 1 ELSE 0 END AS SalesReason_Other
,CASE WHEN B.[Name] = 'Television  Advertisement' THEN 1 ELSE 0 END AS SalesReason_TV
,CASE WHEN B.[Name] = 'Manufacturer' THEN 1 ELSE 0 END AS SalesReason_Manufacturer
,CASE WHEN B.[Name] = 'On Promotion' THEN 1 ELSE 0 END AS SalesReason_Promotion
FROM [Sales].[SalesOrderHeaderSalesReason] AS A
LEFT JOIN [Sales].[SalesReason] AS B
ON A.SalesReasonID = B.SalesReasonID
left join Sales.SalesOrderHeader as C
on C.SalesOrderID = a.SalesOrderID
) as T1
group by t1.Year
order by 1



