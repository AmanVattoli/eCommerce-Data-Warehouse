-- Update store opening dates to be after January 1, 2014
UPDATE DimStores
SET StoreOpeningDate = DATEADD(DAY, UNIFORM(0, 3800, RANDOM()), '2014-01-01');

-- Verify the update
SELECT * FROM DimStores LIMIT 100;

COMMIT;

-- Update specific stores (91-100) to have opening dates in last 12 months of 2024
UPDATE DimStores 
SET StoreOpeningDate = DATEADD(DAY, UNIFORM(0, 360, RANDOM()), 
                               (SELECT MAX(StoreOpeningDate) FROM DimStores WHERE YEAR(StoreOpeningDate) = 2024) - INTERVAL '12 MONTHS')
WHERE StoreID BETWEEN 91 AND 100;

-- Verify the update
SELECT * FROM DimStores WHERE StoreID BETWEEN 91 AND 100;

COMMIT;

-- Update FactOrders DateID to be after StoreOpeningDate
UPDATE FactOrders f
SET DateID = r.new_DateID
FROM (
    SELECT f.OrderID, d.DateID AS new_DateID
    FROM FactOrders f
    JOIN DimStores s ON f.StoreID = s.StoreID
    JOIN DimDates d ON d.Date >= s.StoreOpeningDate
    WHERE f.DateID < TO_CHAR(s.StoreOpeningDate, 'YYYYMMDD')::NUMBER
    ORDER BY RANDOM()
) r
WHERE f.OrderID = r.OrderID;

-- Verify updates
SELECT f.*
FROM FactOrders f
JOIN DimStores s ON f.StoreID = s.StoreID
WHERE f.DateID < TO_CHAR(s.StoreOpeningDate, 'YYYYMMDD')::NUMBER;

COMMIT;

-- Customer Analysis Queries

-- 1. Inactive Customers (No orders in last 30 days)
SELECT * 
FROM DimCustomers 
WHERE CustomerID NOT IN (
    SELECT DISTINCT c.CustomerID 
    FROM DimCustomers c
    JOIN FactOrders f ON c.CustomerID = f.CustomerID
    JOIN DimDates d ON f.DateID = d.DateID
    WHERE d.Date >= DATEADD(DAY, -30, (SELECT MAX(Date) FROM DimDates WHERE Year = 2024))
);

-- 2. Most Recent Store Performance
WITH store_rank AS (
    SELECT 
        StoreID, 
        StoreOpeningDate, 
        ROW_NUMBER() OVER (ORDER BY StoreOpeningDate DESC) AS final_rank 
    FROM DimStores
),
most_recent_store AS (
    SELECT StoreID FROM store_rank WHERE final_rank = 1
),
store_sales AS (
    SELECT 
        o.StoreID, 
        SUM(o.TotalAmount) AS TotalSales 
    FROM FactOrders o 
    JOIN most_recent_store s ON o.StoreID = s.StoreID
    GROUP BY o.StoreID
)
SELECT 
    s.StoreID, 
    s.StoreName, 
    s.StoreOpeningDate, 
    COALESCE(sa.TotalSales, 0) AS TotalSalesSinceOpening
FROM DimStores s
JOIN most_recent_store m ON s.StoreID = m.StoreID
LEFT JOIN store_sales sa ON s.StoreID = sa.StoreID;

-- 3. Multi-Category Customers
WITH BASE_DATA AS (
    SELECT 
        o.CustomerID, 
        p.Category 
    FROM FactOrders o
    JOIN DimDates d ON o.DateID = d.DateID
    JOIN DimProducts p ON o.ProductID = p.ProductID
    WHERE d.Date >= DATEADD(MONTH, -6, (SELECT MAX(Date) FROM DimDates WHERE Year = 2024))
    GROUP BY o.CustomerID, p.Category
)
SELECT CustomerID
FROM BASE_DATA
GROUP BY CustomerID
HAVING COUNT(DISTINCT Category) > 3;

-- Sales Analysis Queries

-- 1. Monthly Sales 2024
SELECT 
    d.Month,
    SUM(o.TotalAmount) AS Monthly_Amount
FROM FactOrders o
JOIN DimDates d ON o.DateID = d.DateID
WHERE d.Year = 2024
GROUP BY d.Month
ORDER BY d.Month;

-- 2. Highest Discount Analysis
WITH base_data AS (
    SELECT 
        DiscountAmount, 
        ROW_NUMBER() OVER (ORDER BY DiscountAmount DESC) AS discount_rank 
    FROM FactOrders o 
    JOIN DimDates d ON o.DateID = d.DateID
    WHERE d.Date >= DATEADD(YEAR, -1, (SELECT MAX(Date) FROM DimDates WHERE Year = 2024))
)
SELECT * 
FROM base_data 
WHERE discount_rank = 1;

-- 3. Customer with Maximum Lifetime Discount
SELECT CustomerID 
FROM FactOrders 
GROUP BY CustomerID 
ORDER BY SUM(DiscountAmount) DESC 
LIMIT 1;

-- 4. Customer with Most Orders
WITH base_data AS (
    SELECT 
        CustomerID, 
        COUNT(OrderID) AS order_count 
    FROM FactOrders 
    GROUP BY CustomerID
),
order_rank_data AS (
    SELECT 
        b.*, 
        ROW_NUMBER() OVER (ORDER BY order_count DESC) AS order_rank 
    FROM base_data b
)
SELECT CustomerID 
FROM order_rank_data 
WHERE order_rank = 1;

-- Brand and Product Analysis

-- 1. Top 3 Brands by Sales
WITH BrandSales AS (
    SELECT 
        P.Brand, 
        SUM(F.TotalAmount) AS TotalSales
    FROM FactOrders F
    JOIN DimDates D ON F.DateID = D.DateID
    JOIN DimProducts P ON F.ProductID = P.ProductID
    WHERE D.Date >= DATEADD(YEAR, -1, '2024-12-31')
    GROUP BY P.Brand
),
BrandSalesRank AS (
    SELECT 
        S.*, 
        ROW_NUMBER() OVER (ORDER BY TotalSales DESC) AS SalesRank
    FROM BrandSales S
)
SELECT Brand, TotalSales 
FROM BrandSalesRank 
WHERE SalesRank <= 3;

-- Loyalty Program Analysis

-- 1. Customer Count by Loyalty Tier
SELECT 
    L.ProgramTier, 
    COUNT(D.CustomerID) AS CustomerCount 
FROM DimCustomers D 
JOIN DimLoyaltyInfo L ON D.LoyaltyProgramID = L.LoyaltyProgramID
GROUP BY L.ProgramTier;

-- Regional Analysis

-- 1. Region-Category Sales
SELECT 
    S.Region, 
    P.Category, 
    SUM(F.TotalAmount) AS TotalSales
FROM FactOrders F
JOIN DimDates D ON F.DateID = D.DateID
JOIN DimProducts P ON F.ProductID = P.ProductID
JOIN DimStores S ON F.StoreID = S.StoreID
WHERE D.Date >= DATEADD(MONTH, -6, '2024-12-31')
GROUP BY S.Region, P.Category;

-- Product Performance

-- 1. Top 5 Products by Quantity
WITH QuantityData AS (
    SELECT 
        F.ProductID, 
        SUM(F.QuantityOrdered) AS TotalQuantity 
    FROM FactOrders F 
    JOIN DimDates D ON F.DateID = D.DateID
    WHERE D.Date >= DATEADD(YEAR, -3, '2024-12-31')
    GROUP BY F.ProductID
), 
QuantityRankData AS (
    SELECT 
        Q.*, 
        ROW_NUMBER() OVER (ORDER BY Q.TotalQuantity DESC) AS QuantityWiseRank 
    FROM QuantityData Q
)
SELECT ProductID, TotalQuantity 
FROM QuantityRankData 
WHERE QuantityWiseRank <= 5;

-- Loyalty Program Sales Analysis

-- 1. Sales by Loyalty Tier
SELECT 
    P.ProgramName, 
    SUM(F.TotalAmount) AS TotalSales 
FROM FactOrders F
JOIN DimDates D ON F.DateID = D.DateID
JOIN DimCustomers C ON F.CustomerID = C.CustomerID
JOIN DimLoyaltyInfo P ON C.LoyaltyProgramID = P.LoyaltyProgramID
WHERE D.Year >= 2023
GROUP BY P.ProgramName;

-- Store Performance Analysis

-- 1. Manager Revenue (June 2024)
SELECT 
    s.ManagerName, 
    SUM(f.TotalAmount) AS Total_Sales
FROM FactOrders f
JOIN DimDates d ON f.DateID = d.DateID
JOIN DimStores s ON f.StoreID = s.StoreID
WHERE d.Year = 2024 AND d.Month = 6
GROUP BY s.ManagerName;

-- 2. Average Order Amount by Store (2024)
SELECT 
    S.StoreName, 
    S.StoreType, 
    AVG(O.TotalAmount) AS Average_Order_Amount
FROM FactOrders O
JOIN DimDates D ON O.DateID = D.DateID
JOIN DimStores S ON O.StoreID = S.StoreID
WHERE D.Year = 2024
GROUP BY S.StoreName, S.StoreType;

-- Stage Data Analysis

-- 1. Customer Data Preview
SELECT $1, $2, $3
FROM 
    @SALES.SALES_SCHEMA.SALES_STAGE/DimCustomers/DimCustomers.csv
    (FILE_FORMAT => 'CSV_SOURCE_FILE_FORMAT');

-- 2. Customer Count in Stage
SELECT COUNT($1) 
FROM 
    @SALES.SALES_SCHEMA.SALES_STAGE/DimCustomers/DimCustomers.csv
    (FILE_FORMAT => 'CSV_SOURCE_FILE_FORMAT');

-- 3. Customers Born After 2000
SELECT $1, $2, $3, $4, $5, $6 
FROM 
    @SALES.SALES_SCHEMA.SALES_STAGE/DimCustomers/DimCustomers.csv
    (FILE_FORMAT => 'CSV_SOURCE_FILE_FORMAT')
WHERE $4 > '2000-01-01';

-- 4. Customer Program Tier Analysis
WITH customer_data AS (
    SELECT 
        $1 AS First_Name, 
        $12 AS Loyalty_Program_ID 
    FROM 
        @SALES.SALES_SCHEMA.SALES_STAGE/DimCustomers/DimCustomers.csv
    (FILE_FORMAT => 'CSV_SOURCE_FILE_FORMAT')
), 
loyalty_data AS (
    SELECT 
        $1 AS Loyalty_Program_ID, 
        $3 AS Program_Tier 
    FROM 
        @SALES.SALES_SCHEMA.SALES_STAGE/DimLoyaltyInfo/DimLoyaltyInfo.csv
    (FILE_FORMAT => 'CSV_SOURCE_FILE_FORMAT')
) 
SELECT 
    c.First_Name, 
    l.Program_Tier 
FROM customer_data c 
JOIN loyalty_data l 
ON c.Loyalty_Program_ID = l.Loyalty_Program_ID;

-- 5. Customer Count by Program Tier
WITH customer_data AS (
    SELECT 
        $1 AS First_Name, 
        $12 AS Loyalty_Program_ID 
    FROM 
        @SALES.SALES_SCHEMA.SALES_STAGE/DimCustomers/DimCustomers.csv
    (FILE_FORMAT => 'CSV_SOURCE_FILE_FORMAT')
), 
loyalty_data AS (
    SELECT 
        $1 AS Loyalty_Program_ID, 
        $3 AS Program_Tier 
    FROM 
        @SALES.SALES_SCHEMA.SALES_STAGE/DimLoyaltyInfo/DimLoyaltyInfo.csv
    (FILE_FORMAT => 'CSV_SOURCE_FILE_FORMAT')
) 
SELECT 
    l.Program_Tier, 
    COUNT(1) AS TotalCount 
FROM customer_data c 
JOIN loyalty_data l 
ON c.Loyalty_Program_ID = l.Loyalty_Program_ID
GROUP BY l.Program_Tier; 