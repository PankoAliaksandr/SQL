WITH main as
(
	SELECT tsl.MarketID AS [MarketID],
		   LEFT (MarketID, LEN(MarketID) - 3) AS [Category],
		   ts.[Dates] AS [Date],
		   ts.[Var] AS [Return]
	FROM [tara].[dbo].[SimTS] AS ts
		 INNER JOIN [tara].[dbo].[SimTSLookup] AS tsl
		 ON ts.TS_ID = tsl.TS_ID
	WHERE tsl.IndicatorID = 'HIST_TWR_PFCCY_YTD'
		  AND tsl.SimID = '4301'
		  AND NOT (LEFT(tsl.MarketID, 5) IN ('S-Ass', 'S-TBM', 'S-WER')
				   OR LEFT(tsl.MarketID, 1) IN ('V')
				   OR tsl.MarketID IN ('S-TAASoll-PF'))
),
Portfolio AS
(
	SELECT [Category],
		   [Date],
		   [Return] AS PortfRet
	FROM main
	WHERE RIGHT (MarketID, 3) = '-PF'
),
Benchmark AS
(
	SELECT [Category],
		   [Date],
		   [Return] AS BMRet
	FROM main
	WHERE RIGHT (MarketID, 3) = '-BM'
),
Outperformance AS
(
	SELECT LEFT (MarketID, LEN(MarketID) - 5) AS [Category],
		   [Date],
		   [Return] AS [Outperformance]
	FROM main
	WHERE RIGHT (MarketID, 5) = '-ACTV'
),
FAPuniverse AS
(
SELECT p.[Category], p.[Date], p.PortfRet, b.BMRet, o.Outperformance
FROM Portfolio AS p LEFT JOIN Benchmark AS b 
	 ON (p.[Category] = b.Category AND p.[Date] = b.[Date])
	 LEFT JOIN Outperformance AS o
	 ON (p.[Category] = o.Category AND p.[Date] = o.[Date]) 
WHERE p.[Category] IN (
'S-FI_EM_USD',
'S-FI_EM_CO', 
'S-FI CH IN', 
'S-FI EMU', 
'S-FI NOEMU',
'S-FI DBLOK',
'S-AKT CH',
'S-AKT SMC',
'S-AKT EMU',
'S-AKT EMSC',
'S-IMMO',
'S-IMMOEU',
'S-AKT UK',
'S-AKT USA',
'S-AKT USSC',
'S-AKT ASIA',
'S-EQ_APXJ',
'S-EQ_CHINA',
'S-EQ_CHINN',
'S-EQ_CHINS',
'S-EQ_CHINF',
'S-AKT EMMA',
'S-EQ_EM_ASIA',
'S-EQ_EM_EMEA',
'S-EQ_EM_LATA',
'S-GELDM',
'S-CUR')
),
orig AS
(  
--Gewichte:
SELECT 
       [MarketID]
      ,[IndicatorID]
      ,[TS_type]
      ,[CRNCY]
	  , mpl.[MODEL_PORTFOLIO_NAME]
	  ,ts.Dates,
	  ts.[Var]
FROM [TARA].[dbo].[SimTSLookup] tsl left join [AIM].[scd].[ModelPortfolioLookup] mpl on tsl.MarketID=mpl.oldPOR inner join [TARA].[dbo].[SimTS] ts on tsl.TS_ID=ts.TS_ID
WHERE [IndicatorID] = 'ExpActual' and [MarketID] IN (
'S-FI_EM_USD',
'S-FI_EM_CO', 
'S-FI CH IN', 
'S-FI EMU', 
'S-FI NOEMU',
'S-FI DBLOK',
'S-AKT CH',
'S-AKT SMC',
'S-AKT EMU',
'S-AKT EMSC',
'S-IMMO',
'S-IMMOEU',
'S-AKT UK',
'S-AKT USA',
'S-AKT USSC',
'S-AKT ASIA',
'S-EQ_APXJ',
'S-EQ_CHINA',
'S-EQ_CHINN',
'S-EQ_CHINS',
'S-EQ_CHINF',
'S-AKT EMMA',
'S-EQ_EM_ASIA',
'S-EQ_EM_EMEA',
'S-EQ_EM_LATA',
'S-GELDM',
'S-CUR')
),
withSum AS
(
	SELECT *, SUM(orig.[Var]) OVER(PARTITION BY [Dates]) AS [sum] FROM orig
),
newWeights AS
(
	SELECT [MarketID]
      ,[IndicatorID]
      ,[TS_type]
      ,[CRNCY]
	  ,[MODEL_PORTFOLIO_NAME]
	  ,[Dates]
	  , withSum.[Var] / withSum.[sum] AS [newWeight] FROM withSum
)
SELECT f.Category,
       n.MODEL_PORTFOLIO_NAME,
	   f.[Date],
	   n.[Dates],
	   f.PortfRet,
       f.BMRet,
       f.Outperformance,
	   n.newWeight	   
FROM FAPuniverse AS f FULL OUTER JOIN newWeights AS n 
ON (f.Category = n.MarketID AND f.[Date] = n.[Dates]) ORDER BY n.Dates, f.[Date]





