SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Aliaksandr Panko (PAA)
-- Create date: 15.01.2020
-- Description:	The function compares 2 tickers to find out if they are identical.
--              The problem is that ABBN SW Equity = ABBN SE Equity = ABBN SE = ABBN SW. 
--				So: 1) 'Equity' is optional
--					2) Some exchanges belong to the same group (ex. SW = SE = VX)
-- =============================================
ALTER FUNCTION [misc].[Compare2TickersPAA]
(
	@ticker1 AS NVARCHAR (200),
	@ticker2 AS NVARCHAR (200)
)
RETURNS BIT
AS
BEGIN

declare @ret as bit = 0;

declare @space_index1 as int = (SELECT CHARINDEX(' ', @ticker1) AS [SpaceIndex]);
declare @space_index2 as int = (SELECT CHARINDEX(' ', @ticker2) AS [SpaceIndex]);

WITH
stock_name1 as
(
	SELECT SUBSTRING(@ticker1, 1, @space_index1 - 1) as [name]
),
stock_name2 as
(
	SELECT SUBSTRING(@ticker2, 1, @space_index2 - 1) as [name]
),
exchange_name1 as
(
	SELECT SUBSTRING(@ticker1, @space_index1+ 1, 2) as [name]
),
exchange_name2 as
(
	SELECT SUBSTRING(@ticker2, @space_index2 + 1, 2) as [name]
),
t1p1_VS_t2p1 as
(
	SELECT CASE
				WHEN (SELECT [name] FROM stock_name1 ) =
				     (SELECT [name] FROM stock_name2)
				THEN 'true'
				ELSE 'false'
		   END [t1p1EQt2p1]
),
t1_exchange_mapping_group as
(
	SELECT ExchangeMappingGroup FROM config.ExchangeMappings
	  WHERE Exchange = (SELECT [name] FROM exchange_name1)
),
t2_exchange_mapping_group as
(
	SELECT ExchangeMappingGroup FROM config.ExchangeMappings
	  WHERE Exchange = (SELECT [name] FROM exchange_name2)
),
t1p2_VS_t2p2 as
(
	SELECT CASE
				WHEN (SELECT ExchangeMappingGroup FROM t1_exchange_mapping_group) = 
				     (SELECT ExchangeMappingGroup FROM t2_exchange_mapping_group)
				THEN 'true'
				ELSE 'false'
		   END [t1p2EQt2p2]
),
res as
(
SELECT CASE
			WHEN (SELECT [t1p1EQt2p1] FROM t1p1_VS_t2p1 ) =  'false' THEN 'false'
			WHEN (SELECT [t1p2EQt2p2] FROM t1p2_VS_t2p2 ) =  'false' THEN 'false'
	   ELSE 'true'
	   END [isEqual]
)

select @ret = res.isEqual from res;
return @ret
END
GO