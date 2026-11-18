CREATE TABLE [dbo].[dim_date] (
    [DateKey]      DATE         NOT NULL,
    [SalesYear]    INT          NULL,
    [SalesMonth]   INT          NULL,
    [SalesQuarter] INT          NULL,
    [MonthName]    VARCHAR (20) NULL
);


GO

ALTER TABLE [dbo].[dim_date]
    ADD CONSTRAINT [PK_dim_date] PRIMARY KEY NONCLUSTERED ([DateKey] ASC) NOT ENFORCED;


GO