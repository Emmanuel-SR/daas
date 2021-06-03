CREATE PROCEDURE DATA.SP_INSERT_DIM_DATE (@CURRENT_DATE AS DATE) AS

BEGIN

  BEGIN TRY

    INSERT INTO DATA.DIM_DATE
      (
        DATE_KEY,
        [DATE],
        CALENDAR_YEAR,
        CALENDAR_SEMESTER_OF_YEAR,
        CALENDAR_QUARTER_OF_YEAR,
        MONTH_NUMBER_OF_YEAR,
        DAY_NUMBER_OF_WEEK,
        DAY_NUMBER_OF_MONTH
      )
   VALUES
     (
        (DATEPART(YEAR , @CURRENT_DATE) * 10000) + (DATEPART(MONTH , @CURRENT_DATE) * 100) + DATEPART(DAY , @CURRENT_DATE),
        @CURRENT_DATE,
        DATEPART(YEAR , @CURRENT_DATE),
        CASE WHEN DATEPART(QUARTER, @CURRENT_DATE) < 3 THEN 1 ELSE 2 END,
        DATEPART(QUARTER, @CURRENT_DATE),
        DATEPART(MONTH, @CURRENT_DATE),
        DATEPART(WEEK, @CURRENT_DATE),
        DATEPART(DAY, @CURRENT_DATE)
     );

  END TRY

  BEGIN CATCH

    DECLARE @ERROR_MESSAGE NVARCHAR(4000);
    DECLARE @ERROR_SEVERITY INT;
    DECLARE @ERROR_STATE INT;

    SELECT
      @ERROR_MESSAGE = ERROR_MESSAGE(),
      @ERROR_SEVERITY = ERROR_SEVERITY(),
      @ERROR_STATE = ERROR_STATE();

    RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);

  END CATCH

END;