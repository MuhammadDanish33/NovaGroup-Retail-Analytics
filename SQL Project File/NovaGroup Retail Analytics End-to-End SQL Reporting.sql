/* ============================================================
   NovaGroup Retail Analytics — SQL Portfolio Project
   Author: Muhammad Danish
   Purpose: End-to-end retail analytics covering sales, inventory,
            supply chain, and executive KPIs, built on a star-schema
            data warehouse (Retail + Common schemas).
   ============================================================ */

USE NovaGroup;

-- ------------------------------------------------------------
-- 1. Monthly Sales Performance
-- Business question: How are units sold, revenue, and profit
-- trending month over month?
-- ------------------------------------------------------------
SELECT 
    Common.DateDim.Year,
    Common.DateDim.Month,
    SUM(Quantity)        AS TotalUnitsSold,
    SUM(NetSalesAmount)  AS TotalNetSales,
    SUM(GrossProfit)     AS TotalGrossProfit
FROM Retail.FactSalesLine
JOIN Common.DateDim
    ON Retail.FactSalesLine.DateKey = Common.DateDim.DateKey
GROUP BY Common.DateDim.Year, Common.DateDim.Month
ORDER BY Common.DateDim.Year, Common.DateDim.Month;
-- ------------------------------------------------------------
-- 2. Category Sales Performance
-- Business question: Which product categories drive the most revenue?
-- ------------------------------------------------------------
SELECT 
    Retail.DimProduct.Category,
    SUM(NetSalesAmount) AS Total_Sales_Category
FROM Retail.FactSalesLine
JOIN Retail.DimProduct
    ON Retail.FactSalesLine.ProductKey = Retail.DimProduct.ProductKey
GROUP BY Retail.DimProduct.Category
ORDER BY Total_Sales_Category DESC;


-- ------------------------------------------------------------
-- 3. Category Profit Performance
-- Business question: High revenue doesn't always mean high profit —
-- which categories are actually the most profitable?
-- ------------------------------------------------------------
SELECT 
    Retail.DimProduct.Category,
    SUM(GrossProfit) AS Total_GrossProfit_Category
FROM Retail.FactSalesLine
JOIN Retail.DimProduct
    ON Retail.FactSalesLine.ProductKey = Retail.DimProduct.ProductKey
GROUP BY Retail.DimProduct.Category
ORDER BY Total_GrossProfit_Category DESC;

-- ------------------------------------------------------------
-- 4. Product Margin Analysis
-- Business question: Which individual products have the healthiest
-- margins? NULLIF guards against divide-by-zero on products with $0 sales.
-- ------------------------------------------------------------
SELECT 
    Retail.DimProduct.ProductName,
    SUM(NetSalesAmount) AS TotalNetSales,
    SUM(GrossProfit)    AS TotalGrossProfit,
    ROUND(SUM(GrossProfit) / NULLIF(SUM(NetSalesAmount), 0) * 100, 2) AS GrossMargin_Percentage
FROM Retail.FactSalesLine
JOIN Retail.DimProduct
    ON Retail.FactSalesLine.ProductKey = Retail.DimProduct.ProductKey
GROUP BY Retail.DimProduct.ProductName
ORDER BY GrossMargin_Percentage DESC;

-- ------------------------------------------------------------
-- 5. Store Performance
-- Business question: Which physical/online locations are winning?
-- ------------------------------------------------------------
SELECT 
    LocationName,
    LocationType,
    Region,
    SUM(Quantity)       AS Total_Units_Sold,
    SUM(NetSalesAmount) AS TotalNetSales,
    SUM(GrossProfit)    AS TotalGrossProfit
FROM Retail.FactSalesLine
JOIN Retail.DimLocation
    ON Retail.FactSalesLine.LocationKey = Retail.DimLocation.LocationKey
GROUP BY LocationName, LocationType, Region
ORDER BY TotalNetSales DESC;

-- ------------------------------------------------------------
-- 6. Channel Performance
-- Business question: Online vs. in-store vs. marketplace — where's
-- the revenue actually coming from?
-- ------------------------------------------------------------
SELECT 
    ChannelName,
    SUM(Quantity)       AS Total_Units_Sold,
    SUM(NetSalesAmount) AS TotalNetSales,
    SUM(GrossProfit)    AS TotalGrossProfit
FROM Retail.FactSalesLine
JOIN Retail.DimChannel
    ON Retail.FactSalesLine.ChannelKey = Retail.DimChannel.ChannelKey
GROUP BY ChannelName
ORDER BY TotalNetSales DESC;

-- ------------------------------------------------------------
-- 7. Slow Moving Products
-- Business question: Which products haven't sold in 30+ days?
-- NOTE: uses a CTE instead of repeating the "latest date" subquery
-- twice — cleaner and easier to maintain.
-- ------------------------------------------------------------
WITH LatestSaleDate AS (
    SELECT MAX(D2.FullDate) AS MaxDate
    FROM Retail.FactSalesLine AS S2
    JOIN Common.DateDim AS D2 ON S2.DateKey = D2.DateKey
)
SELECT 
    ProductName,
    SKU,
    Category,
    MAX(FullDate) AS LastSaleDate,
    DATEDIFF(DAY, MAX(FullDate), (SELECT MaxDate FROM LatestSaleDate)) AS DaysSinceLastSale
FROM Retail.FactSalesLine
JOIN Retail.DimProduct
    ON Retail.FactSalesLine.ProductKey = Retail.DimProduct.ProductKey
JOIN Common.DateDim
    ON Retail.FactSalesLine.DateKey = Common.DateDim.DateKey
GROUP BY ProductName, SKU, Category
HAVING DATEDIFF(DAY, MAX(FullDate), (SELECT MaxDate FROM LatestSaleDate)) > 30
ORDER BY DaysSinceLastSale DESC;

-- ------------------------------------------------------------
-- 8. Inventory Value by Location
-- Business question: Where is capital tied up in stock right now?
-- ------------------------------------------------------------
SELECT 
    LocationName, 
    LocationType,
    Region,
    SUM(InventoryValue) AS TotalInventoryValue
FROM Retail.FactInventorySnapshot
JOIN Retail.DimLocation
    ON Retail.FactInventorySnapshot.LocationKey = Retail.DimLocation.LocationKey
WHERE Retail.FactInventorySnapshot.DateKey = (SELECT MAX(DateKey) FROM Retail.FactInventorySnapshot)
GROUP BY LocationName, LocationType, Region
ORDER BY TotalInventoryValue DESC;
-- ------------------------------------------------------------
-- 9. Discount Analysis
-- Business question: Which products are being discounted most heavily,
-- and is that discount actually being offset by volume/profit?
-- ------------------------------------------------------------
SELECT
    ProductName,
    Category,
    SKU,
    SUM(NetSalesAmount)  AS TotalNetSales,
    SUM(GrossProfit)     AS TotalGrossProfit,
    SUM(Quantity)        AS Total_Quantity_Sold,
    SUM(DiscountAmount)  AS Total_Discount_Amount
FROM Retail.FactSalesLine
JOIN Retail.DimProduct
    ON Retail.FactSalesLine.ProductKey = Retail.DimProduct.ProductKey
GROUP BY ProductName, Category, SKU
ORDER BY Total_Discount_Amount DESC;
-- ------------------------------------------------------------
-- 10. Open Purchase Orders
-- Business question: What have we ordered from suppliers that
-- hasn't fully arrived yet, and what's that worth?
-- ------------------------------------------------------------
SELECT
    Retail.FactPurchaseOrderLine.PurchaseOrderLineID,
    Retail.FactPurchaseOrderLine.ProductKey,
    Retail.FactPurchaseOrderLine.SupplierKey,
    Retail.FactPurchaseOrderLine.OrderedQty,
    COALESCE(ReceiptSummary.TotalReceivedQty, 0) AS Total_Received_Quantity,
    OrderedQty - COALESCE(ReceiptSummary.TotalReceivedQty, 0) AS OutstandingQuantity,
    (OrderedQty - COALESCE(ReceiptSummary.TotalReceivedQty, 0)) * UnitCost AS OutstandingPOValue
FROM Retail.FactPurchaseOrderLine
LEFT JOIN (
    SELECT 
        PurchaseOrderLineID,
        SUM(ReceivedQty) AS TotalReceivedQty
    FROM Retail.FactGoodsReceipt
    GROUP BY PurchaseOrderLineID
) AS ReceiptSummary
    ON Retail.FactPurchaseOrderLine.PurchaseOrderLineID = ReceiptSummary.PurchaseOrderLineID
WHERE OrderedQty - COALESCE(ReceiptSummary.TotalReceivedQty, 0) > 0
ORDER BY OutstandingPOValue DESC;

-- ------------------------------------------------------------
-- 11. Zero-Availability Products
-- Business question: Which product/location combos are fully out
-- of stock as of the latest snapshot?
-- ------------------------------------------------------------
SELECT
    ProductName,
    LocationName,
    AvailableQty,
    SKU,
    Category,
    ReservedQty
FROM Retail.FactInventorySnapshot
JOIN Retail.DimProduct
    ON Retail.FactInventorySnapshot.ProductKey = Retail.DimProduct.ProductKey
JOIN Retail.DimLocation
    ON Retail.FactInventorySnapshot.LocationKey = Retail.DimLocation.LocationKey
WHERE DateKey = (SELECT MAX(DateKey) FROM Retail.FactInventorySnapshot)
    AND AvailableQty = 0;
-- ------------------------------------------------------------
-- 12. Return Rate Analysis
-- Business question: Which categories have the highest return rates
-- relative to units sold?
-- ------------------------------------------------------------
SELECT
    DP.Category,
    SUM(FS.Quantity) AS TotalUnitsSold,
    SUM(COALESCE(RS.TotalReturnedQty, 0)) AS TotalUnitsReturned,
    ROUND(SUM(COALESCE(RS.TotalReturnedQty, 0)) * 100.0 / NULLIF(SUM(FS.Quantity), 0), 2) AS ReturnRatePercentage
FROM Retail.FactSalesLine FS
JOIN Retail.DimProduct DP
    ON FS.ProductKey = DP.ProductKey
LEFT JOIN (
    SELECT 
        SalesLineID,
        SUM(ReturnedQty) AS TotalReturnedQty
    FROM Retail.FactReturnLine
    GROUP BY SalesLineID
) RS
    ON FS.SalesLineID = RS.SalesLineID
GROUP BY DP.Category
ORDER BY ReturnRatePercentage DESC;
-- ------------------------------------------------------------
-- 13. Stockout Days
-- Business question: Which product/location combos have spent the
-- most snapshot-days at zero availability? (Assumes one snapshot
-- row per calendar day — confirm this assumption against your data.)
-- ------------------------------------------------------------
SELECT
    DP.ProductName,
    DP.SKU,
    DL.LocationName,
    COUNT(FI.DateKey) AS StockoutDays
FROM Retail.FactInventorySnapshot FI
JOIN Retail.DimProduct DP
    ON FI.ProductKey = DP.ProductKey
JOIN Retail.DimLocation DL
    ON FI.LocationKey = DL.LocationKey
WHERE FI.AvailableQty = 0
GROUP BY DP.ProductName, DP.SKU, DL.LocationName
ORDER BY StockoutDays DESC;
-- ------------------------------------------------------------
-- 14. Replenishment Status 
-- Business question: Which fast-selling products are at risk of
-- running out and need reordering?
-- ------------------------------------------------------------
WITH LatestInventory AS (
    SELECT *
    FROM Retail.FactInventorySnapshot
    WHERE DateKey = (SELECT MAX(DateKey) FROM Retail.FactInventorySnapshot)
),
SalesTotals AS (
    SELECT ProductKey, SUM(Quantity) AS TotalUnitsSold
    FROM Retail.FactSalesLine
    GROUP BY ProductKey
)
SELECT
    DP.ProductName,
    DP.SKU,
    DP.Category,
    ST.TotalUnitsSold,
    FI.AvailableQty,
    FI.ReservedQty,
    FI.InventoryValue,
    CASE
        WHEN ST.TotalUnitsSold > 100 AND FI.AvailableQty < 5  THEN 'Re-order Now'
        WHEN ST.TotalUnitsSold > 10  AND FI.AvailableQty < 30 THEN 'Monitor Closely'
        ELSE 'No Immediate Action'
    END AS ReplenishmentStatus
FROM SalesTotals ST
JOIN Retail.DimProduct DP
    ON ST.ProductKey = DP.ProductKey
JOIN LatestInventory FI
    ON ST.ProductKey = FI.ProductKey
WHERE ST.TotalUnitsSold > 100
    AND FI.AvailableQty < 30
ORDER BY ST.TotalUnitsSold DESC;

-- ------------------------------------------------------------
-- 15. Overstock Detection 
-- Business question: Which products have high stock but almost
-- no sales — tying up capital unnecessarily?
-- ------------------------------------------------------------
WITH LatestInventory AS (
    SELECT *
    FROM Retail.FactInventorySnapshot
    WHERE DateKey = (SELECT MAX(DateKey) FROM Retail.FactInventorySnapshot)
),
SalesTotals AS (
    SELECT ProductKey, SUM(Quantity) AS TotalUnitsSold
    FROM Retail.FactSalesLine
    GROUP BY ProductKey
)
SELECT
    DP.ProductName,
    DP.SKU,
    DP.Category,
    COALESCE(ST.TotalUnitsSold, 0) AS TotalUnitsSold,
    FI.AvailableQty,
    FI.InventoryValue,
    'Possible Overstock' AS InventoryStatus
FROM LatestInventory FI
JOIN Retail.DimProduct DP
    ON FI.ProductKey = DP.ProductKey
LEFT JOIN SalesTotals ST
    ON FI.ProductKey = ST.ProductKey
WHERE COALESCE(ST.TotalUnitsSold, 0) < 5
    AND FI.AvailableQty > 1
ORDER BY FI.AvailableQty DESC;


-- ------------------------------------------------------------
-- 16. Supplier Fulfilment Performance
-- Business question: Which suppliers are reliably delivering what
-- was ordered, and which are lagging?
-- ------------------------------------------------------------
SELECT
    POL.SupplierKey,
    SUM(POL.OrderedQty) AS TotalOrderedQty,
    SUM(COALESCE(RS.TotalReceivedQty, 0)) AS TotalReceivedQty,
    SUM(POL.OrderedQty) - SUM(COALESCE(RS.TotalReceivedQty, 0)) AS TotalOutstandingQty,
    ROUND(SUM(COALESCE(RS.TotalReceivedQty, 0)) * 100.0 / NULLIF(SUM(POL.OrderedQty), 0), 2) AS FulfilmentPercentage
FROM Retail.FactPurchaseOrderLine POL
LEFT JOIN (
    SELECT 
        PurchaseOrderLineID,
        SUM(ReceivedQty) AS TotalReceivedQty
    FROM Retail.FactGoodsReceipt
    GROUP BY PurchaseOrderLineID
) RS
    ON POL.PurchaseOrderLineID = RS.PurchaseOrderLineID
GROUP BY POL.SupplierKey
ORDER BY FulfilmentPercentage ASC;

-- ------------------------------------------------------------
-- 17. Top 10 Revenue Products
-- ------------------------------------------------------------
SELECT TOP 10
    DP.ProductName,
    DP.SKU,
    DP.Category,
    SUM(FS.Quantity)       AS TotalUnitsSold,
    SUM(FS.NetSalesAmount) AS TotalNetSales,
    SUM(FS.GrossProfit)    AS TotalGrossProfit
FROM Retail.FactSalesLine FS
JOIN Retail.DimProduct DP
    ON FS.ProductKey = DP.ProductKey
GROUP BY DP.ProductName, DP.SKU, DP.Category
ORDER BY TotalNetSales DESC;
-- ------------------------------------------------------------
-- 18. Bottom 10 Revenue Products
-- ------------------------------------------------------------
SELECT TOP 10
    DP.ProductName,
    DP.SKU,
    DP.Category,
    SUM(FS.Quantity)       AS TotalUnitsSold,
    SUM(FS.NetSalesAmount) AS TotalNetSales,
    SUM(FS.GrossProfit)    AS TotalGrossProfit
FROM Retail.FactSalesLine FS
JOIN Retail.DimProduct DP
    ON FS.ProductKey = DP.ProductKey
GROUP BY DP.ProductName, DP.SKU, DP.Category
ORDER BY TotalNetSales ASC;

-- ------------------------------------------------------------
-- 19. Inventory Health Classification
-- Business question: At a glance, what's the health status of
-- every product/location combination right now?
-- ------------------------------------------------------------
SELECT
    DP.ProductName,
    DP.SKU,
    DP.Category,
    DL.LocationName,
    DL.Region,
    FI.AvailableQty,
    FI.InventoryValue,
    CASE
        WHEN FI.AvailableQty = 0   THEN 'Stockout'
        WHEN FI.AvailableQty < 50  THEN 'Stockout Risk'
        WHEN FI.AvailableQty > 500 THEN 'Overstock'
        ELSE 'Healthy'
    END AS InventoryHealthStatus
FROM Retail.FactInventorySnapshot FI
JOIN Retail.DimProduct DP
    ON FI.ProductKey = DP.ProductKey
JOIN Retail.DimLocation DL
    ON FI.LocationKey = DL.LocationKey
WHERE FI.DateKey = (SELECT MAX(DateKey) FROM Retail.FactInventorySnapshot)
ORDER BY InventoryHealthStatus, FI.AvailableQty;
-- ------------------------------------------------------------
-- 20. Executive KPI Summary
-- Business question: What's the one-row, board-meeting-ready
-- snapshot of the whole business right now?
-- ------------------------------------------------------------
SELECT
    (SELECT SUM(Quantity) FROM Retail.FactSalesLine) AS TotalUnitsSold,
    (SELECT SUM(NetSalesAmount) FROM Retail.FactSalesLine) AS TotalNetSales,
    (SELECT SUM(GrossProfit) FROM Retail.FactSalesLine) AS TotalGrossProfit,

    (SELECT SUM(InventoryValue)
     FROM Retail.FactInventorySnapshot
     WHERE DateKey = (SELECT MAX(DateKey) FROM Retail.FactInventorySnapshot)
    ) AS CurrentInventoryValue,

    (SELECT COUNT(*)
     FROM Retail.FactInventorySnapshot
     WHERE DateKey = (SELECT MAX(DateKey) FROM Retail.FactInventorySnapshot)
       AND AvailableQty = 0
    ) AS CurrentStockoutCount,

    (SELECT SUM((POL.OrderedQty - COALESCE(RS.TotalReceivedQty, 0)) * POL.UnitCost)
     FROM Retail.FactPurchaseOrderLine POL
     LEFT JOIN (
         SELECT PurchaseOrderLineID, SUM(ReceivedQty) AS TotalReceivedQty
         FROM Retail.FactGoodsReceipt
         GROUP BY PurchaseOrderLineID
     ) RS
         ON POL.PurchaseOrderLineID = RS.PurchaseOrderLineID
     WHERE POL.OrderedQty - COALESCE(RS.TotalReceivedQty, 0) > 0
    ) AS OpenPurchaseOrderValue;
