CREATE   PROCEDURE dbo.sp_build_gold_star_schema
AS
BEGIN
    -- 1. Drop fact_sales FIRST so Foreign Keys on dim_customer & dim_date don't block DROP TABLE!
    DROP TABLE IF EXISTS dbo.fact_sales;

    -- 2. Rebuild dim_customer with NOT NULL + Primary Key
    DROP TABLE IF EXISTS dbo.dim_customer;
    CREATE TABLE dbo.dim_customer (
        CustomerKey INT NOT NULL,
        CustomerID INT NOT NULL,
        CustomerName VARCHAR(100),
        City VARCHAR(100),
        LoyaltyTier VARCHAR(50)
    );

    INSERT INTO dbo.dim_customer
    SELECT 
        CAST(CustomerID AS INT),
        CAST(CustomerID AS INT),
        CAST(CustomerName AS VARCHAR(100)),
        CAST(City AS VARCHAR(100)),
        CAST(LoyaltyTier AS VARCHAR(50))
    FROM [lh_ecommerce_bronze].[dbo].[silver_customers];

    ALTER TABLE dbo.dim_customer ADD CONSTRAINT PK_dim_customer PRIMARY KEY NONCLUSTERED (CustomerKey) NOT ENFORCED;

    -- 3. Rebuild dim_date with NOT NULL + Primary Key
    DROP TABLE IF EXISTS dbo.dim_date;
    CREATE TABLE dbo.dim_date (
        DateKey DATE NOT NULL,
        SalesYear INT,
        SalesMonth INT,
        SalesQuarter INT,
        MonthName VARCHAR(20)
    );

    INSERT INTO dbo.dim_date
    SELECT DISTINCT
        pickup_date,
        pickup_year,
        pickup_month,
        DATEPART(QUARTER, pickup_date),
        CAST(DATENAME(MONTH, pickup_date) AS VARCHAR(20))
    FROM [lh_ecommerce_bronze].[dbo].[silver_sales]
    WHERE pickup_date IS NOT NULL;

    ALTER TABLE dbo.dim_date ADD CONSTRAINT PK_dim_date PRIMARY KEY NONCLUSTERED (DateKey) NOT ENFORCED;

    -- 4. Rebuild fact_sales + Foreign Keys
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

    ALTER TABLE dbo.fact_sales ADD CONSTRAINT FK_fact_sales_customer FOREIGN KEY (CustomerKey) REFERENCES dbo.dim_customer(CustomerKey) NOT ENFORCED;
    ALTER TABLE dbo.fact_sales ADD CONSTRAINT FK_fact_sales_date FOREIGN KEY (DateKey) REFERENCES dbo.dim_date(DateKey) NOT ENFORCED;
END;

GO