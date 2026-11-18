CREATE   PROCEDURE dbo.sp_build_gold_star_schema
AS
BEGIN
    -- 1. Rebuild dim_customer
    DROP TABLE IF EXISTS dbo.dim_customer;
    CREATE TABLE dbo.dim_customer AS
    SELECT 
        CAST(CustomerID AS INT) AS CustomerKey,
        CAST(CustomerID AS INT) AS CustomerID,
        CAST(CustomerName AS VARCHAR(100)) AS CustomerName,
        CAST(City AS VARCHAR(100)) AS City,
        CAST(LoyaltyTier AS VARCHAR(50)) AS LoyaltyTier
    FROM [lh_ecommerce_bronze].[dbo].[silver_customers];

    -- 2. Rebuild dim_date
    DROP TABLE IF EXISTS dbo.dim_date;
    CREATE TABLE dbo.dim_date AS
    SELECT DISTINCT
        pickup_date AS DateKey,
        pickup_year AS SalesYear,
        pickup_month AS SalesMonth,
        DATEPART(QUARTER, pickup_date) AS SalesQuarter,
        CAST(DATENAME(MONTH, pickup_date) AS VARCHAR(20)) AS MonthName
    FROM [lh_ecommerce_bronze].[dbo].[silver_sales]
    WHERE pickup_date IS NOT NULL;

    -- 3. Rebuild fact_sales
    DROP TABLE IF EXISTS dbo.fact_sales;
    CREATE TABLE dbo.fact_sales AS
    SELECT 
        CAST(CustomerID AS INT) AS CustomerKey,
        pickup_date AS DateKey,
        VendorID,
        CAST(payment_type AS VARCHAR(20)) AS PaymentType,
        COUNT(*) AS TotalTrips,
        SUM(passenger_count) AS TotalPassengers,
        ROUND(SUM(trip_distance), 2) AS TotalDistance,
        ROUND(SUM(fare_amount), 2) AS TotalFareAmount,
        ROUND(SUM(tip_amount), 2) AS TotalTipAmount,
        ROUND(SUM(total_amount), 2) AS TotalRevenue
    FROM [lh_ecommerce_bronze].[dbo].[silver_sales]
    GROUP BY 
        CustomerID,
        pickup_date,
        VendorID,
        payment_type;
END;

GO