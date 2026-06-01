
USE kainen_ecommerce;


-- VISUAL 1: Current Inventory Levels

SELECT
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    i.QuantityInStock,
    i.ReorderLevel,
    CASE
        WHEN i.QuantityInStock = 0                        THEN 'Out of Stock'
        WHEN i.QuantityInStock <= i.ReorderLevel          THEN 'Low Stock'
        ELSE                                                   'OK'
    END AS StockStatus
FROM   Product    p
JOIN   Inventory  i ON i.ProductID  = p.ProductID
JOIN   Category   c ON c.CategoryID = p.CategoryID
WHERE  p.IsActive = 1
ORDER  BY i.QuantityInStock ASC;


-- VISUAL 2: Products With Low Stock  (threshold highlight table)

SELECT
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    i.QuantityInStock,
    i.ReorderLevel,
    i.LastUpdated
FROM   Product    p
JOIN   Inventory  i ON i.ProductID  = p.ProductID
JOIN   Category   c ON c.CategoryID = p.CategoryID
WHERE  p.IsActive = 1
  AND  i.QuantityInStock <= i.ReorderLevel
ORDER  BY i.QuantityInStock ASC;


-- VISUAL 3: Most Popular Products (by units sold, date range)

SELECT
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    SUM(oi.Quantity)                                AS TotalUnitsSold,
    COUNT(DISTINCT o.OrderID)                       AS OrderCount,
    SUM(oi.Quantity * oi.UnitPriceAtPurchase)       AS Revenue
FROM   Order_Item  oi
JOIN   `Order`     o  ON o.OrderID   = oi.OrderID
JOIN   Product     p  ON p.ProductID = oi.ProductID
JOIN   Category    c  ON c.CategoryID = p.CategoryID
WHERE  o.Status    <> 'Cancelled'
  AND  o.OrderDate BETWEEN '2025-01-01' AND '2025-12-31'  -- match your Tableau filter
GROUP  BY p.ProductID, p.ProductName, c.CategoryName
ORDER  BY TotalUnitsSold DESC
LIMIT  10;


-- VISUAL 4: Least Popular Products (same date range)

SELECT
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    COALESCE(SUM(oi.Quantity), 0)                   AS TotalUnitsSold,
    COALESCE(COUNT(DISTINCT o.OrderID), 0)          AS OrderCount
FROM   Product     p
JOIN   Category    c  ON c.CategoryID = p.CategoryID
LEFT   JOIN Order_Item oi ON oi.ProductID = p.ProductID
LEFT   JOIN `Order`    o  ON o.OrderID    = oi.OrderID
                         AND o.Status <> 'Cancelled'
                         AND o.OrderDate BETWEEN '2025-01-01' AND '2025-12-31'
WHERE  p.IsActive = 1
GROUP  BY p.ProductID, p.ProductName, c.CategoryName
ORDER  BY TotalUnitsSold ASC
LIMIT  10;


-- VISUAL 5: Inactive Customers (no purchase in last X months)

SELECT
    u.UserID,
    CONCAT(u.FirstName, ' ', u.LastName)  AS CustomerName,
    u.Email,
    MAX(o.OrderDate)                       AS LastOrderDate,
    DATEDIFF(CURDATE(), MAX(o.OrderDate))  AS MonthsSinceLastOrder
FROM   User       u
JOIN   Customer   c  ON c.UserID = u.UserID
LEFT   JOIN `Order` o ON o.CustomerID = c.UserID
                     AND o.Status <> 'Cancelled'
GROUP  BY u.UserID, u.FirstName, u.LastName, u.Email
HAVING LastOrderDate < DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
    OR LastOrderDate IS NULL
ORDER  BY LastOrderDate ASC;


-- VISUAL 6: What Lapsed Customers Typically Buy

WITH LapsedCustomers AS (
    SELECT
        u.UserID,
        CONCAT(u.FirstName, ' ', u.LastName) AS CustomerName,
        u.Email,
        MAX(o.OrderDate)                      AS LastOrderDate
    FROM   User       u
    JOIN   Customer   c  ON c.UserID = u.UserID
    LEFT   JOIN `Order` o ON o.CustomerID = c.UserID
                         AND o.Status <> 'Cancelled'
    GROUP  BY u.UserID, u.FirstName, u.LastName, u.Email
    HAVING LastOrderDate < DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
        OR LastOrderDate IS NULL
)
SELECT
    lc.CustomerName,
    lc.Email,
    lc.LastOrderDate,
    p.ProductName,
    c.CategoryName,
    SUM(oi.Quantity) AS TotalUnitsBought
FROM   LapsedCustomers     lc
JOIN   `Order`             o   ON o.CustomerID  = lc.UserID
                              AND o.Status <> 'Cancelled'
JOIN   Order_Item          oi  ON oi.OrderID    = o.OrderID
JOIN   Product             p   ON p.ProductID   = oi.ProductID
JOIN   Category            c   ON c.CategoryID  = p.CategoryID
GROUP  BY lc.CustomerName, lc.Email, lc.LastOrderDate,
          p.ProductName, c.CategoryName
ORDER  BY lc.CustomerName, TotalUnitsBought DESC;


-- VISUAL 7: Newest Products

SELECT
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    s.BusinessName  AS SellerName,
    p.Price,
    p.CreatedAt,
    i.QuantityInStock
FROM   Product    p
JOIN   Category   c ON c.CategoryID = p.CategoryID
JOIN   Seller     s ON s.UserID     = p.SellerID
JOIN   Inventory  i ON i.ProductID  = p.ProductID
WHERE  p.IsActive  = 1
ORDER  BY p.CreatedAt DESC
LIMIT  20;


-- VISUAL 8: Best-Performing Categories

SELECT
    c.CategoryID,
    c.CategoryName,
    COUNT(DISTINCT o.OrderID)                        AS OrderCount,
    SUM(oi.Quantity)                                 AS UnitsSold,
    ROUND(SUM(oi.Quantity * oi.UnitPriceAtPurchase),2) AS Revenue,
    ROUND(AVG(r.Rating),2)                           AS AvgRating
FROM   Category   c
JOIN   Product    p  ON p.CategoryID  = c.CategoryID
JOIN   Order_Item oi ON oi.ProductID  = p.ProductID
JOIN   `Order`    o  ON o.OrderID     = oi.OrderID
LEFT   JOIN Review r ON r.ProductID   = p.ProductID
WHERE  o.Status    <> 'Cancelled'
  AND  o.OrderDate BETWEEN '2024-01-01' AND '2024-12-31'
GROUP  BY c.CategoryID, c.CategoryName
ORDER  BY Revenue DESC;
