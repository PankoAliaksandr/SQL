USE [Aktienmodell]
GO
/****** Object:  UserDefinedFunction [calc].[tvfBloombergReturnsTimeseriesNew]    Script Date: 18.12.2019 14:51:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:  Panko Aliaksandr (paa)
-- Create date: 13.12.2019
-- Description: the output is a table, which contains the Relative (stock - benchmark) Returns (normal or log-returns) for a cash-adjusted timeseries. 
-- 
--  @ts_type: the ticker name like 'DTE GY Equity'
--  @indicatorid: the mnemonic, usually 'px_last'. The function calc.tvfBloombergAdjustedTimeseries uses this mnemonic to adjust the prices
--  @minDate: the first date we calculate the timeseries for (this date will not be returned)
--  @maxDate: the last date to be returned (this date will not be returned)
--  @useLogReturns: specifies which type of returns should be used (normal or log-returns)
--  @relativeTo: the benchmark name such as 'SMI Index' 
-- =============================================

ALTER FUNCTION [calc].[tvfBloombergReturnsTimeseriesNew]
(
   @ts_type        AS NVARCHAR (200) = 'DTE GY Equity',
   @indicatorId    AS NVARCHAR (80) = NULL,
   @minDate        AS DATE = NULL,
   @maxDate        AS DATE = NULL,
   @useLogReturns  AS BIT = 'false',
   @relativeTo nvarchar(50) = null
)
RETURNS TABLE
AS
RETURN 
/*
select * FROM tara.dbo.simtslookup lu inner join tara.dbo.SimTS ts
on lu.TS_ID=ts.ts_id where lu.simid=4413 and lu.ts_type = @relativeTo
*/
WITH stockAdjPrice AS
(
SELECT Datie,
	   DaysSinceMinDate,
	   RowNumber,
	   varAdjusted
FROM calc.tvfBloombergAdjustedTimeseries (@ts_type,
										  @indicatorId,
										  @minDate,
										  @maxDate,
										  0)
),
indexAdjValue AS
(
SELECT Datie,
	   DaysSinceMinDate,
	   RowNumber,
	   varAdjusted
FROM calc.tvfBloombergAdjustedTimeseries (@relativeTo,
										  @indicatorId,
										  @minDate,
										  @maxDate,
										  0)
),
joinedAdjPrice AS
(
SELECT ts1.Datie,
	   ts1.DaysSinceMinDate,
	   ts1.RowNumber,
	   ts1.varAdjusted AS priceTs,
	   ts2.varAdjusted AS priceTsLag1
FROM stockAdjPrice AS  ts1 INNER JOIN stockAdjPrice AS ts2 
ON ts1.RowNumber = ts2.RowNumber + 1
),
joinedAdjValue AS
(
SELECT ts1.Datie,
	   ts1.DaysSinceMinDate,
	   ts1.RowNumber,
	   ts1.varAdjusted AS priceTs,
	   ts2.varAdjusted AS priceTsLag1
FROM indexAdjValue AS  ts1 INNER JOIN indexAdjValue AS ts2 
ON ts1.RowNumber = ts2.RowNumber + 1
),
stockReturnsTable AS
(
SELECT Datie,
	   RowNumber,
	   DaysSinceMinDate,
	    CASE
		  WHEN @useLogReturns = 'false' THEN
			([priceTs] / [priceTsLag1]) - 1
		  ELSE
		    -- use log returns:  r = ln(R + 1)
			-- LOG() calculates natural logarithm 
			LOG (([priceTs] / [priceTsLag1]) + 1)
		  END [Return]

FROM joinedAdjPrice
),
indexReturnsTable AS
(
SELECT Datie,
	   RowNumber,
	   DaysSinceMinDate,
	    CASE
		  WHEN @useLogReturns = 'false' THEN
			([priceTs] / [priceTsLag1]) - 1
		  ELSE
		    -- use log returns:  r = ln(R + 1)
			-- LOG() calculates natural logarithm 
			LOG (([priceTs] / [priceTsLag1]) + 1)
		  END [Return]

FROM joinedAdjValue
),
joinedReturnsTable as
(
SELECT st.Datie,
	   st.RowNumber,
	   st.DaysSinceMinDate,
	   [StockReturn] = st.[Return],
	   [IndexReturn] = ind.[Return]
FROM stockReturnsTable AS  st INNER JOIN indexReturnsTable AS ind
ON st.Datie = ind.Datie
)
SELECT Datie,
	   RowNumber,
	   DaysSinceMinDate,
	   [StockRelativeReturn] = [StockReturn] - [IndexReturn]
FROM joinedReturnsTable