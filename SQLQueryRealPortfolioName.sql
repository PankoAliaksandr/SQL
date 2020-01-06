SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Panko Aliaksandr	
-- Create date: 17.12.19
-- Description:	The function parses Analyst Portfolio name
-- and derives real trading portfolio name. 
-- There are 3 additional parameters to set up AP name pattern
-- ex. APSFBEQCHSM -> [AP], [SFB] these 2 are clear
-- [EQ] is part 1, supposed to start at position 6
-- [CH] is part 2, supposed to start at position 8
-- [SM] is part 3, supposed to start at position 10
-- =============================================
ALTER FUNCTION misc.GetRealNameFromAPname
(
	@APname NVARCHAR(50),
	@p1start int = 6,
	@p2start int = 8,
	@p3start int = 10
)
RETURNS NVARCHAR(20)
AS
BEGIN
RETURN
(
	SELECT RTRIM
	(
		CONCAT
		(
			(SELECT SUBSTRING(@APname, @p1start,(@p2start-@p1start))),
			'_',
			(SELECT SUBSTRING(@APname, @p2start,(@p3start-@p2start))),
			'_',
			(SELECT SUBSTRING(@APname, @p3start,5))
		)
	)
)
END
















