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
)
SELECT p.[Category], p.[Date], p.PortfRet, b.BMRet, o.Outperformance FROM Portfolio AS p LEFT JOIN Benchmark AS b 
ON (p.[Category] = b.Category AND p.[Date] = b.[Date]) LEFT JOIN Outperformance AS o
ON (p.[Category] = o.Category AND p.[Date] = o.[Date]) order by [Category], [Date]

