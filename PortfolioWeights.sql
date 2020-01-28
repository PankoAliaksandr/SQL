WITH orig AS
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
'S-FI_EM_USD',--FI_EM_USD	Fixed Income Emerging Markets USD	Obligationen in Fremdwährung (150230)
'S-FI_EM_CO', --FI_EM_CO	Fixed Income Corporate Emerging Markets USD	Obligationen in Fremdwährung (150230)
'S-FI CH IN', --FI_CHF Obligationen Schweiz (150220),
'S-FI EMU', --FI_EUR	Fixed Income EUR	Obligationen in Fremdwährung (150230)
'S-FI NOEMU', -- FI_GBP	Fixed Income GBP	Obligationen in Fremdwährung (150230)
'S-FI DBLOK', -- FI_USD	Fixed Income USD	Obligationen in Fremdwährung (150230)
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
--'S-DERIV',?? Currency Hadging and many others
'S-GELDM',
'S-CUR')

),
withSum AS
(
	SELECT *, SUM(orig.[Var]) OVER(PARTITION BY [Dates]) AS [sum] FROM orig
),
newWeights AS
(
	SELECT *, withSum.[Var] / withSum.[sum] AS [newWeight] FROM withSum
)
SELECT [MarketID]
      ,[IndicatorID]
      ,[TS_type]
      ,[CRNCY]
	  ,[MODEL_PORTFOLIO_NAME]
	  ,[Dates]
	  ,[newWeight]  FROM newWeights