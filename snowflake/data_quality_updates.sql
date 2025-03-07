-- Data Quality Updates for Sales Data Warehouse

-- 1. Store Opening Dates Update
-- Ensure all stores have opening dates after January 1, 2014
UPDATE DimStores
SET StoreOpeningDate = DATEADD(DAY, UNIFORM(0, 3800, RANDOM()), '2014-01-01');

-- Verify the update
SELECT * FROM DimStores LIMIT 100;

COMMIT;

-- 2. Recent Store Updates
-- Update specific stores (91-100) to have opening dates in last 12 months of 2024
UPDATE DimStores 
SET StoreOpeningDate = DATEADD(DAY, UNIFORM(0, 360, RANDOM()), 
                               (SELECT MAX(StoreOpeningDate) FROM DimStores WHERE YEAR(StoreOpeningDate) = 2024) - INTERVAL '12 MONTHS')
WHERE StoreID BETWEEN 91 AND 100;

-- Verify the update
SELECT * FROM DimStores WHERE StoreID BETWEEN 91 AND 100;

COMMIT;

-- 3. Order Dates Validation
-- Update FactOrders DateID to ensure orders occur after store opening dates
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