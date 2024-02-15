USE [3-Energy Plant]
GO



/*
Energy Sales Transaction’ table has no primary key.
we can use the row number SQL window function to create a synthetic primary key
Each row of data will be given a unique row number, so it solves our issue
*/

SELECT ROW_NUMBER() OVER (ORDER BY [Customer ID]) AS [PK - Sales Transactions]
,*
INTO [dbo].[Energy Sales Transactions (PK)]
FROM [dbo].[Energy Sales Transactions]


/*
multiple columns will beused for the respective primary and foreign keys.
‘NOT NULL’constraint applied to them
*/

ALTER TABLE [dbo].[Customers]
ALTER COLUMN [Customer ID] NVARCHAR(50) NOT NULL;
ALTER TABLE [dbo].[Energy Plants]
ALTER COLUMN [Plant ID] NVARCHAR(50) NOT NULL;
ALTER TABLE [dbo].[Energy Plants]
ALTER COLUMN [Fuel ID] NVARCHAR(50) NOT NULL;
ALTER TABLE [dbo].[Energy Sales Transactions (PK)]
ALTER COLUMN [Customer ID] NVARCHAR(50) NOT NULL;
ALTER TABLE [dbo].[Energy Sales Transactions (PK)]
ALTER COLUMN [Plant ID] NVARCHAR(50) NOT NULL;
ALTER TABLE [dbo].[Energy Sales Transactions (PK)]
ALTER COLUMN [Fuel ID] NVARCHAR(50) NOT NULL;
ALTER TABLE [dbo].[Energy Sales Transactions (PK)]
ALTER COLUMN [PK - Sales Transactions] NVARCHAR(50) NOT NULL;
ALTER TABLE [dbo].[Fuel]
ALTER COLUMN [Fuel ID] NVARCHAR(50) NOT NULL;


--there is more than one table which has a foreign key which is not the primary key

--PK
ALTER TABLE[dbo].[Customers]
ADD PRIMARY KEY ([Customer ID]);
ALTER TABLE [dbo].[Energy Plants]
ADD PRIMARY KEY ([Plant ID]);
ALTER TABLE [dbo].[Energy Sales Transactions (PK)]
ADD PRIMARY KEY ([PK - Sales Transactions]);
ALTER TABLE [dbo].[Fuel]
ADD PRIMARY KEY ([Fuel ID]);

--FK
ALTER TABLE [dbo].[Energy Sales Transactions (PK)]
ADD FOREIGN KEY ([Customer ID])
REFERENCES [dbo].[Customers]([Customer ID]);
ALTER TABLE [dbo].[Energy Sales Transactions (PK)]
ADD FOREIGN KEY ([Plant ID])
REFERENCES [dbo].[Energy Plants]([Plant ID]);
ALTER TABLE [dbo].[Energy Sales Transactions (PK)]
ADD FOREIGN KEY ([Fuel ID])
REFERENCES [dbo].[Fuel]([Fuel ID]);
ALTER TABLE [dbo].[Energy Plants]
ADD FOREIGN KEY ([Fuel ID])
REFERENCES [dbo].[Fuel]([Fuel ID]);

--Multiple joins being carried out in the same statement
SELECT A.[PK - Sales Transactions]
,A.[Customer ID]
,B.[Customer Name]
,B.[Green Rating]
,B.[Customer Satisfaction]
,B.[Sanctions]
,A.[Plant ID]
,C.[Plant Name]
,C.[Commission Year]
,A.[Fuel ID]
,D.[Fuel Name]
,D.[Fuel Type]
,D.[Pollution Index]
,D.[Price Per Unit ($ kW-hr)]
,A.[Quantity of Fuel Units (Millions)]
INTO [Energy Plant - Master]
FROM [dbo].[Energy Sales Transactions (PK)] AS A
LEFT JOIN [dbo].[Customers] AS B
ON A.[Customer ID] = B.[Customer ID]
LEFT JOIN [dbo].[Energy Plants] AS C
ON A.[Plant ID] = C.[Plant ID]
LEFT JOIN [dbo].[Fuel] AS D
ON A.[Fuel ID] = D.[Fuel ID]/*Following Matrics To Be Analyzed1.The transaction summary for each fuel type
2.A general summary report for the plants
3.An advanced summary report on the customers
*/

--Total Cost
SELECT A.[Fuel Type]
,A.[Fuel Name]
,A.[Total Cost]
,A.[Number of Transactions]
,CAST( AVG([Total Cost]) AS DECIMAL(18,2)) AS [Cost Average]
FROM
(SELECT [Fuel Type]
,[Fuel Name]
,SUM( CAST([Quantity of Fuel Units (Millions)] AS INT) *
CAST([Price Per Unit ($ kW-hr)] AS DECIMAL(18,3)) ) AS [Total Cost]
,COUNT(*) AS [Number of Transactions]
FROM [dbo].[Energy Plant - Master]
GROUP BY [Fuel Type]
,[Fuel Name])A
GROUP BY A.[Fuel Type]
,A.[Fuel Name]
,A.[Total Cost]
,A.[Number of Transactions]


--The plants and the fuel used can be analysed for the transactions that took place.

SELECT [Plant ID]
,[Plant Name]
,[Fuel ID]
,[Fuel Name]
,[Commission Year]
,[Pollution Index]
,COUNT(*) AS [No. Transactions]
FROM [dbo].[Energy Plant - Master]
GROUP BY [Plant ID]
,[Plant Name]
,[Fuel ID]
,[Fuel Name]
,[Commission Year]
,[Pollution Index]


--This query is the core part of the query which will in turn be used as the foundation for the advanced customer summary
SELECT [Customer ID]
,[Customer Name]
,[Green Rating]
,[Customer Satisfaction]
,[Sanctions]
,[Fuel Type]
,COUNT(*) AS [No. Transactions]
,SUM( CAST([Quantity of Fuel Units (Millions)] AS INT) *
CAST([Price Per Unit ($ kW-hr)] AS DECIMAL(18,3)) ) AS [Total Cost]
FROM [dbo].[Energy Plant - Master]
GROUP BY [Customer ID]
,[Customer Name]
,[Green Rating]
,[Customer Satisfaction]
,[Sanctions]
,[Fuel Type]
ORDER BY [Customer ID]


/*
A calculated field ‘Total Cost’ is created and from this we can create the following fields which enhance our analytics:
a.Running total
b.Percentage of the total transaction cost for each customer split by ‘Renewable’ and ‘Non-renewable’ energy sources
*/

SELECT *
,SUM([Total Cost]) OVER (PARTITION BY [Customer ID] ORDER BY [Fuel Type]) AS [Running Total]
,SUM([Total Cost]) OVER (PARTITION BY [Customer ID]) AS [Customer Total]
,CAST( ([Total Cost] / SUM([Total Cost]) OVER (PARTITION BY [Customer ID]) ) AS DECIMAL(18,2)) AS [Percentage]
FROM
(SELECT [Customer ID]
,[Customer Name]
,[Green Rating]
,[Customer Satisfaction]
,[Sanctions]
,[Fuel Type]
,COUNT(*) AS [No. of Transactions]
,SUM( CAST([Quantity of Fuel Units (Millions)] AS INT) *
CAST([Price Per Unit ($ kW-hr)] AS DECIMAL(18,3)) ) AS [Total Cost]
FROM [dbo].[Energy Plant - Master]
GROUP BY [Customer ID]
,[Customer Name]
,[Green Rating]
,[Customer Satisfaction]
,[Sanctions]
,[Fuel Type])A
ORDER BY [Customer ID]
