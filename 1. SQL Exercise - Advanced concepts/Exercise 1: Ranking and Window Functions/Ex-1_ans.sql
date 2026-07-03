-- ============================================================
-- Advanced SQL Exercises — Answer Key
-- Online Retail Store: Ranking, Aggregation, CTEs, MERGE, PIVOT/UNPIVOT
-- Dialect: T-SQL (SQL Server) unless noted otherwise
-- ============================================================

-- ============================================================
-- ASSUMED SCHEMA
-- ============================================================
-- Customers       (CustomerID PK, Name, Region)
-- Products        (ProductID PK, ProductName, Category, Price)
-- Orders          (OrderID PK, CustomerID FK, OrderDate)
-- OrderDetails    (OrderDetailID PK, OrderID FK, ProductID FK, Quantity)
-- StagingProducts (ProductID, ProductName, Category, Price)  -- Exercise 3 only


-- ============================================================
-- EXERCISE 1: Ranking and Window Functions
-- Goal: Top 3 most expensive products per category
-- ============================================================

-- Step 1 & 3: ROW_NUMBER() with PARTITION BY / ORDER BY
WITH RankedProducts AS (
    SELECT
        ProductID,
        ProductName,
        Category,
        Price,
        ROW_NUMBER() OVER (
            PARTITION BY Category
            ORDER BY Price DESC
        ) AS RowNum
    FROM Products
)
SELECT ProductID, ProductName, Category, Price, RowNum
FROM RankedProducts
WHERE RowNum <= 3
ORDER BY Category, RowNum;


-- Step 2: Compare ROW_NUMBER(), RANK(), DENSE_RANK() side by side
SELECT
    ProductID,
    ProductName,
    Category,
    Price,
    ROW_NUMBER() OVER (PARTITION BY Category ORDER BY Price DESC) AS RowNum,
    RANK()       OVER (PARTITION BY Category ORDER BY Price DESC) AS PriceRank,
    DENSE_RANK() OVER (PARTITION BY Category ORDER BY Price DESC) AS PriceDenseRank
FROM Products
ORDER BY Category, Price DESC;


-- Top 3 per category using DENSE_RANK() instead (preserves ties)
WITH RankedProductsDense AS (
    SELECT
        ProductID, ProductName, Category, Price,
        DENSE_RANK() OVER (PARTITION BY Category ORDER BY Price DESC) AS PriceDenseRank
    FROM Products
)
SELECT *
FROM RankedProductsDense
WHERE PriceDenseRank <= 3
ORDER BY Category, PriceDenseRank;

-- Notes:
--   ROW_NUMBER() -> always unique (1,2,3,4), breaks ties arbitrarily
--   RANK()       -> ties share a rank, then skips ahead (1,2,2,4)
--   DENSE_RANK() -> ties share a rank, no gap afterward (1,2,2,3)


-- ============================================================
-- EXERCISE 2: GROUPING SETS, CUBE, and ROLLUP
-- Goal: Total quantity sold by Region and Category
-- ============================================================

-- Base join (starting point for all three techniques)
SELECT
    c.Region,
    p.Category,
    SUM(od.Quantity) AS TotalQuantity
FROM Orders o
JOIN OrderDetails od ON od.OrderID = o.OrderID
JOIN Customers c ON c.CustomerID = o.CustomerID
JOIN Products p ON p.ProductID = od.ProductID
GROUP BY c.Region, p.Category;


-- Step 2: GROUPING SETS — exact combinations requested
SELECT
    c.Region,
    p.Category,
    SUM(od.Quantity) AS TotalQuantity
FROM Orders o
JOIN OrderDetails od ON od.OrderID = o.OrderID
JOIN Customers c ON c.CustomerID = o.CustomerID
JOIN Products p ON p.ProductID = od.ProductID
GROUP BY GROUPING SETS (
    (c.Region),
    (p.Category),
    (c.Region, p.Category)
)
ORDER BY c.Region, p.Category;


-- Step 3: ROLLUP — hierarchical subtotals + grand total
SELECT
    c.Region,
    p.Category,
    SUM(od.Quantity) AS TotalQuantity
FROM Orders o
JOIN OrderDetails od ON od.OrderID = o.OrderID
JOIN Customers c ON c.CustomerID = o.CustomerID
JOIN Products p ON p.ProductID = od.ProductID
GROUP BY ROLLUP (c.Region, p.Category)
ORDER BY c.Region, p.Category;


-- Step 4: CUBE — every combination of Region and Category
SELECT
    c.Region,
    p.Category,
    SUM(od.Quantity) AS TotalQuantity
FROM Orders o
JOIN OrderDetails od ON od.OrderID = o.OrderID
JOIN Customers c ON c.CustomerID = o.CustomerID
JOIN Products p ON p.ProductID = od.ProductID
GROUP BY CUBE (c.Region, p.Category)
ORDER BY c.Region, p.Category;


-- Optional: use GROUPING() to flag which NULLs are subtotal rows
SELECT
    c.Region,
    p.Category,
    SUM(od.Quantity) AS TotalQuantity,
    GROUPING(c.Region)   AS IsRegionSubtotal,
    GROUPING(p.Category) AS IsCategorySubtotal
FROM Orders o
JOIN OrderDetails od ON od.OrderID = o.OrderID
JOIN Customers c ON c.CustomerID = o.CustomerID
JOIN Products p ON p.ProductID = od.ProductID
GROUP BY CUBE (c.Region, p.Category)
ORDER BY c.Region, p.Category;

-- Notes:
--   MySQL: no GROUPING SETS / CUBE; ROLLUP via "GROUP BY ... WITH ROLLUP"
--   PostgreSQL: supports all three natively, same syntax as above


-- ============================================================
-- EXERCISE 3: CTEs and MERGE
-- Goal: Recursive CTE calendar table + MERGE from staging table
-- ============================================================

-- Part A: Recursive CTE — dates from 2025-01-01 to 2025-01-31
WITH DateSequence AS (
    -- Anchor member
    SELECT CAST('2025-01-01' AS DATE) AS CalendarDate

    UNION ALL

    -- Recursive member
    SELECT DATEADD(DAY, 1, CalendarDate)
    FROM DateSequence
    WHERE CalendarDate < '2025-01-31'
)
SELECT CalendarDate
FROM DateSequence
OPTION (MAXRECURSION 100);   -- SQL Server safeguard against infinite recursion

-- PostgreSQL equivalent: replace DATEADD(DAY, 1, CalendarDate)
-- with  CalendarDate + INTERVAL '1 day'  and drop the OPTION clause.


-- Part B, Step 2: Staging table with updated/new product prices
CREATE TABLE StagingProducts (
    ProductID   INT,
    ProductName VARCHAR(100),
    Category    VARCHAR(50),
    Price       DECIMAL(10,2)
);

INSERT INTO StagingProducts (ProductID, ProductName, Category, Price)
VALUES
    (101, 'Wireless Headphones', 'Electronics', 449.99),  -- price update
    (999, 'Smart Home Hub',      'Electronics', 129.99);  -- new product


-- Part B, Step 3: MERGE — update existing rows, insert new ones
MERGE INTO Products AS target
USING StagingProducts AS source
    ON target.ProductID = source.ProductID
WHEN MATCHED THEN
    UPDATE SET
        target.Price       = source.Price,
        target.ProductName = source.ProductName,
        target.Category    = source.Category
WHEN NOT MATCHED BY TARGET THEN
    INSERT (ProductID, ProductName, Category, Price)
    VALUES (source.ProductID, source.ProductName, source.Category, source.Price);

-- Notes:
--   MySQL:  no MERGE; use INSERT ... ON DUPLICATE KEY UPDATE
--   PostgreSQL: MERGE supported natively from v15+;
--               INSERT ... ON CONFLICT DO UPDATE also works


-- ============================================================
-- EXERCISE 4: PIVOT and UNPIVOT
-- Goal: Monthly sales quantity per product, pivoted and unpivoted
-- ============================================================

-- Step 1: Aggregate sales by Product and Month
SELECT
    p.ProductName,
    MONTH(o.OrderDate) AS OrderMonth,
    SUM(od.Quantity)   AS TotalQuantity
FROM Orders o
JOIN OrderDetails od ON od.OrderID = o.OrderID
JOIN Products p ON p.ProductID = od.ProductID
GROUP BY p.ProductName, MONTH(o.OrderDate);


-- Step 2: PIVOT — months become columns
SELECT
    ProductName,
    [1] AS Jan, [2] AS Feb, [3] AS Mar, [4] AS Apr,
    [5] AS May, [6] AS Jun, [7] AS Jul, [8] AS Aug,
    [9] AS Sep, [10] AS Oct, [11] AS Nov, [12] AS Dec
FROM (
    SELECT
        p.ProductName,
        MONTH(o.OrderDate) AS OrderMonth,
        od.Quantity
    FROM Orders o
    JOIN OrderDetails od ON od.OrderID = o.OrderID
    JOIN Products p ON p.ProductID = od.ProductID
) AS SourceData
PIVOT (
    SUM(Quantity)
    FOR OrderMonth IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])
) AS PivotTable
ORDER BY ProductName;


-- Step 3: UNPIVOT — columns back into rows
SELECT
    ProductName,
    MonthName,
    Quantity
FROM (
    SELECT
        ProductName,
        [1] AS Jan, [2] AS Feb, [3] AS Mar, [4] AS Apr,
        [5] AS May, [6] AS Jun, [7] AS Jul, [8] AS Aug,
        [9] AS Sep, [10] AS Oct, [11] AS Nov, [12] AS Dec
    FROM (
        SELECT p.ProductName, MONTH(o.OrderDate) AS OrderMonth, od.Quantity
        FROM Orders o
        JOIN OrderDetails od ON od.OrderID = o.OrderID
        JOIN Products p ON p.ProductID = od.ProductID
    ) AS SourceData
    PIVOT (
        SUM(Quantity)
        FOR OrderMonth IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])
    ) AS PivotTable
) AS PivotedResult
UNPIVOT (
    Quantity FOR MonthName IN (Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec)
) AS UnpivotedResult
ORDER BY ProductName, MonthName;

-- Notes:
--   PIVOT/UNPIVOT are T-SQL-specific.
--   PostgreSQL: use crosstab() (tablefunc extension) to pivot;
--               UNION ALL of individual columns to unpivot.
--   MySQL: use conditional aggregation instead of PIVOT, e.g.
--               SUM(CASE WHEN OrderMonth = 1 THEN Quantity END) AS Jan


-- ============================================================
-- EXERCISE 5: Using a CTE to Simplify a Query
-- Goal: Customers who have placed more than 3 orders
-- ============================================================

WITH CustomerOrderCounts AS (
    SELECT
        o.CustomerID,
        COUNT(o.OrderID) AS OrderCount
    FROM Orders o
    GROUP BY o.CustomerID
)
SELECT
    c.CustomerID,
    c.Name,
    coc.OrderCount
FROM CustomerOrderCounts coc
JOIN Customers c ON c.CustomerID = coc.CustomerID
WHERE coc.OrderCount > 3
ORDER BY coc.OrderCount DESC;


-- Equivalent without a CTE (for comparison)
SELECT
    c.CustomerID,
    c.Name,
    COUNT(o.OrderID) AS OrderCount
FROM Customers c
JOIN Orders o ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.Name
HAVING COUNT(o.OrderID) > 3
ORDER BY OrderCount DESC;

-- Note: HAVING is more compact for a single aggregation;
-- the CTE scales better once more logic needs to build on CustomerOrderCounts.
