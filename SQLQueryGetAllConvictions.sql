USE [Aktienmodell]
GO
/****** Object:  UserDefinedFunction [misc].[tvfGetConstituentsConvictions]    Script Date: 17.12.2019 09:21:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Panko Aliaksandr (PAA)
-- Create date: 17.12.19
-- Description:	The function delivers the latest convictions for all tickers
-- in a portfolio and the corresponding benchmark. In case there is no any conviction for a ticker,
-- the conviction is set to 0, the corresponding date is set to NULL to indicate this fact
-- There is an assumptions: if a ticker has a conviction value for a date, 
-- the value is the same in all portfolios. The assumption must be always valid, 
-- since otherwise the sistem is inconsistent
-- =============================================
ALTER FUNCTION [misc].[tvfGetConstituentsConvictions]
(
   @PortfolioID     AS NVARCHAR (200) = NULL,
   @Date			AS DATE = NULL
)
RETURNS TABLE 
AS
RETURN 
WITH ConvictionsTempTable AS
(
	-- Here there are duplicates, since one stock is 
	-- in several portfolios. Important assumption is that 
	-- convictions are filled consistently: 
	-- a stock has the same conviction in all portfolios

	-- still it is not clear if different dates are possible
	-- (not met, but I assume that it is possible)
	SELECT DISTINCT TS_type AS ticker,
				    ts.[Var] AS conviction,
				    ts.Dates AS [date]
	FROM tara.dbo.simtslookup lu
	INNER JOIN tara.dbo.simts ts ON ts.ts_id = lu.ts_id
	WHERE lu.simid = 4388
		AND lu.indicatorid = 'conviction'
		AND ts.[Var] IS NOT NULL
		AND TS_type IN (SELECT TS_type FROM [misc].[tvfDistinctAPandBMConstituents] (@PortfolioID, @Date))
),
dateFilter AS
(
    SELECT ticker, conviction, max([date]) as MaxDate
    FROM ConvictionsTempTable
    GROUP BY ticker,conviction
),
lastConvictions AS
(
	-- since Distinct already used there are no duplicates
	SELECT  ConvictionsTempTable.ticker,
			ConvictionsTempTable.conviction,
			ConvictionsTempTable.[date] 
	FROM ConvictionsTempTable INNER JOIN dateFilter
	ON ConvictionsTempTable.ticker = dateFilter.ticker
	AND  ConvictionsTempTable.[date] = dateFilter.MaxDate
),
allJoined AS
(
	-- For each ticker in a portfolio and the corresponding bm
	-- set conviction to 0  if not found.
	--  Date remains NULL to indicate that the conviction was not found
	SELECT l.TS_type AS ticker,
		   CASE 
		   WHEN r.conviction IS NULL THEN 0
		   ELSE r.conviction
		   END conviction,
		   r.[date]
	FROM (SELECT TS_type FROM [misc].[tvfDistinctAPandBMConstituents] (@PortfolioID, @Date)) AS l LEFT JOIN lastConvictions AS r
	ON l.TS_type = r.ticker
)
SELECT ticker, conviction, [date] FROM allJoined