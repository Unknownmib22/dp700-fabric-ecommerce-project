CREATE TABLE [dbo].[dim_customer] (
    [CustomerKey]  INT           NOT NULL,
    [CustomerID]   INT           NOT NULL,
    [CustomerName] VARCHAR (100) NULL,
    [City]         VARCHAR (100) NULL,
    [LoyaltyTier]  VARCHAR (50)  NULL
);


GO

ALTER TABLE [dbo].[dim_customer]
    ADD CONSTRAINT [PK_dim_customer] PRIMARY KEY NONCLUSTERED ([CustomerKey] ASC) NOT ENFORCED;


GO