-- ===========================================
-- Exercise 1: Ranking and Window Functions
-- ===========================================

/*
Goal:
Use ROW_NUMBER(), RANK(), DENSE_RANK(), OVER(), and PARTITION BY
to find the top 3 most expensive products in each category.

Table: Products
Columns:
- ProductID
- ProductName
- Category
- Price
*/

-- ===========================================
-- 1. ROW_NUMBER()
-- Assigns a unique rank to every product,
-- even if two products have the same price.
-- ===========================================

SELECT *
FROM (
    SELECT
        ProductID,
        ProductName,
        Category,
        Price,
        ROW_NUMBER() OVER (
            PARTITION BY Category
            ORDER BY Price DESC
        ) AS RowNumber
    FROM Products
) AS RankedProducts
WHERE RowNumber <= 3;


-- ===========================================
-- 2. RANK()
-- Same prices receive the same rank.
-- The next rank is skipped.
-- ===========================================

SELECT *
FROM (
    SELECT
        ProductID,
        ProductName,
        Category,
        Price,
        RANK() OVER (
            PARTITION BY Category
            ORDER BY Price DESC
        ) AS RankNumber
    FROM Products
) AS RankedProducts
WHERE RankNumber <= 3;


-- ===========================================
-- 3. DENSE_RANK()
-- Same prices receive the same rank.
-- No ranks are skipped.
-- ===========================================

SELECT *
FROM (
    SELECT
        ProductID,
        ProductName,
        Category,
        Price,
        DENSE_RANK() OVER (
            PARTITION BY Category
            ORDER BY Price DESC
        ) AS DenseRank
    FROM Products
) AS RankedProducts
WHERE DenseRank <= 3;


-- ===========================================
-- Difference Between Ranking Functions
-- ===========================================

/*
ROW_NUMBER()
------------
80000 -> 1
75000 -> 2
75000 -> 3
70000 -> 4

RANK()
------
80000 -> 1
75000 -> 2
75000 -> 2
70000 -> 4

DENSE_RANK()
------------
80000 -> 1
75000 -> 2
75000 -> 2
70000 -> 3
*/



