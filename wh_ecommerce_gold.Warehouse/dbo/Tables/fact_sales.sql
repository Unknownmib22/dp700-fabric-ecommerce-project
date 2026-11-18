CREATE TABLE [dbo].[fact_sales] (
    [CustomerKey]     INT          NULL,
    [DateKey]         DATE         NULL,
    [VendorID]        INT          NULL,
    [PaymentType]     VARCHAR (20) NULL,
    [TotalTrips]      INT          NULL,
    [TotalPassengers] INT          NULL,
    [TotalDistance]   FLOAT (53)   NULL,
    [TotalFareAmount] FLOAT (53)   NULL,
    [TotalTipAmount]  FLOAT (53)   NULL,
    [TotalRevenue]    FLOAT (53)   NULL
);


GO

ALTER TABLE [dbo].[fact_sales]
    ADD CONSTRAINT [FK_fact_sales_customer] FOREIGN KEY ([CustomerKey]) REFERENCES [dbo].[dim_customer] ([CustomerKey]) NOT ENFORCED;


GO

ALTER TABLE [dbo].[fact_sales]
    ADD CONSTRAINT [FK_fact_sales_date] FOREIGN KEY ([DateKey]) REFERENCES [dbo].[dim_date] ([DateKey]) NOT ENFORCED;


GO