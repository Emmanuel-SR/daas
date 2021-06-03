CREATE PROCEDURE STAGE.SP_LOAD_FACT_PAYMENT (@LOAD_DATE AS DATE) AS

BEGIN

  DECLARE @CREATION_USER AS VARCHAR(100);
  DECLARE @CREATION_DATE AS DATETIME;
  DECLARE @CREATION_IP AS VARCHAR(50);
  DECLARE @PERIOD AS CHAR(6); /* FORMAT YYYYMM */
  DECLARE @ERROR AS INTEGER;

  BEGIN TRY

  SELECT @CREATION_USER = CAST(SERVERPROPERTY('ServerName') AS NVARCHAR) + '-' + CAST(SERVERPROPERTY('MachineName') AS NVARCHAR);
  SELECT @CREATION_DATE = GETDATE();
  SELECT @CREATION_IP = DBO.FN_GET_CURRENT_IP();
  SELECT @PERIOD = LEFT(CONVERT(CHAR, @LOAD_DATE, 112), 6);

  -- STEP 00: CREDIT EXISTS AND HAS AN VALID ASSIGNMENT

  SELECT @ERROR = COUNT(1)
  FROM STAGE.FACT_PAYMENT P
  LEFT JOIN DATA.DIM_CREDIT C 
    ON P.CREDIT_CODE = C.CREDIT_CODE
  LEFT JOIN DATA.HIST_ASSIGNMENT H
    ON H.PERIOD_CODE = @PERIOD AND C.CREDIT_KEY = H.CREDIT_KEY
  WHERE H.CREDIT_KEY IS NULL;

  IF @ERROR > 0
    BEGIN
     THROW 51000, 'There are credits that do not exist or are not in an assignment.', 1;
    END

  -- STEP 01: CREATE TABLE STAGE.TMP_FACT_PAYMENT_01
  IF OBJECT_ID(N'[CIP_DM].[STAGE].[TMP_FACT_PAYMENT_01]',N'U') IS NOT NULL DROP TABLE CIP_DM.STAGE.TMP_FACT_PAYMENT_01;

    SELECT
      P1.DATE_KEY,
      P1.CREDIT_KEY,
      P1.AMOUNT,
      P1.CURRENCY,
      P1.AGENCY,
      P1.CREATION_USER,
      P1.CREATION_DATE,
      P1.CREATION_IP,
      P1.MODIFICATION_USER,
      P1.MODIFICATION_DATE,
      P1.MODIFICATION_IP
    INTO STAGE.TMP_FACT_PAYMENT_01
    FROM DATA.FACT_PAYMENT_1 P1
    WHERE LEFT(P1.DATE_KEY,6) <> @PERIOD

  -- STEP 02: CREATE TABLE STAGE.TMP_FACT_PAYMENT_02
  IF OBJECT_ID(N'[CIP_DM].[STAGE].[TMP_FACT_PAYMENT_02]',N'U') IS NOT NULL DROP TABLE CIP_DM.STAGE.TMP_FACT_PAYMENT_02;

    SELECT
      F.DATE_KEY,
      C.CREDIT_KEY,
      CAST(P.AMOUNT AS DECIMAL(18,2)) AS AMOUNT,
      P.CURRENCY,
      P.AGENCY,
      @CREATION_USER AS CREATION_USER,
      @CREATION_DATE AS CREATION_DATE,
      @CREATION_IP AS CREATION_IP,
      CAST(NULL AS VARCHAR(100)) AS MODIFICATION_USER,
      CAST(NULL AS DATETIME) AS MODIFICATION_DATE,
      CAST(NULL AS VARCHAR(50)) AS MODIFICATION_IP
    INTO STAGE.TMP_FACT_PAYMENT_02
    FROM STAGE.FACT_PAYMENT P
    LEFT JOIN DATA.DIM_DATE F ON F.DATE_KEY = P.PAYMENT_DATE
    LEFT JOIN DATA.DIM_CREDIT C ON C.CREDIT_CODE = P.CREDIT_CODE;

  -- STEP 03: CREATE TABLE DATA.FACT_PAYMENT_1_PREV
  IF OBJECT_ID(N'[CIP_DM].[DATA].[FACT_PAYMENT_1_PREV]',N'U') IS NOT NULL DROP TABLE CIP_DM.DATA.FACT_PAYMENT_1_PREV;

  SELECT
    PREV.DATE_KEY,
    PREV.CREDIT_KEY,
    PREV.AMOUNT,
    PREV.CURRENCY,
    PREV.AGENCY,
    PREV.CREATION_USER,
    PREV.CREATION_DATE,
    PREV.CREATION_IP,
    PREV.MODIFICATION_USER,
    PREV.MODIFICATION_DATE,
    PREV.MODIFICATION_IP
  INTO DATA.FACT_PAYMENT_1_PREV FROM
  (SELECT
    F1.DATE_KEY,
    F1.CREDIT_KEY,
    F1.AMOUNT,
    F1.CURRENCY,
    F1.AGENCY,
    F1.CREATION_USER,
    F1.CREATION_DATE,
    F1.CREATION_IP,
    F1.MODIFICATION_USER,
    F1.MODIFICATION_DATE,
    F1.MODIFICATION_IP
  FROM STAGE.TMP_FACT_PAYMENT_01 F1
  UNION ALL
  SELECT
    F2.DATE_KEY,
    F2.CREDIT_KEY,
    F2.AMOUNT,
    F2.CURRENCY,
    F2.AGENCY,
    F2.CREATION_USER,
    F2.CREATION_DATE,
    F2.CREATION_IP,
    F2.MODIFICATION_USER,
    F2.MODIFICATION_DATE,
    F2.MODIFICATION_IP
  FROM STAGE.TMP_FACT_PAYMENT_02 F2) PREV;

  -- STEP 04: DROP TMP TABLAS
  IF OBJECT_ID(N'[CIP_DM].[STAGE].[TMP_FACT_PAYMENT_01]',N'U') IS NOT NULL DROP TABLE CIP_DM.STAGE.TMP_FACT_PAYMENT_01;
  IF OBJECT_ID(N'[CIP_DM].[STAGE].[TMP_FACT_PAYMENT_02]',N'U') IS NOT NULL DROP TABLE CIP_DM.STAGE.TMP_FACT_PAYMENT_02;

  -- STEP 05: CREATE INDEXES AND CONSTRAINTS DATA.FACT_PAYMENT_1_PREV
  ALTER TABLE DATA.FACT_PAYMENT_1_PREV ALTER COLUMN DATE_KEY INTEGER NOT NULL;
  ALTER TABLE DATA.FACT_PAYMENT_1_PREV ALTER COLUMN CREDIT_KEY INTEGER NOT NULL;
  ALTER TABLE DATA.FACT_PAYMENT_1_PREV ALTER COLUMN AMOUNT DECIMAL(18,2) NOT NULL;
  ALTER TABLE DATA.FACT_PAYMENT_1_PREV ALTER COLUMN CURRENCY CHAR(3) NOT NULL;
  ALTER TABLE DATA.FACT_PAYMENT_1_PREV ADD CONSTRAINT FK_PAYMENT1_DATE_PREV FOREIGN KEY (DATE_KEY)
    REFERENCES DATA.DIM_DATE(DATE_KEY);
  ALTER TABLE DATA.FACT_PAYMENT_1_PREV ADD CONSTRAINT FK_PAYMENT1_CREDIT_PREV FOREIGN KEY (CREDIT_KEY)
    REFERENCES DATA.DIM_CREDIT(CREDIT_KEY);

  -- STEP 06: REPLACE SYNONYM DATA.FACT_PAYMENT TO DATA.FACT_PAYMENT_1_PREV
  DROP SYNONYM DATA.FACT_PAYMENT;
  CREATE SYNONYM DATA.FACT_PAYMENT FOR DATA.FACT_PAYMENT_1_PREV;

  -- STEP 07: RENAME TABLE DATA.FACT_PAYMENT_1 TO DATA.FACT_PAYMENT_1_OLD
  EXEC sp_rename 'DATA.FACT_PAYMENT_1', 'FACT_PAYMENT_1_OLD';

  -- STEP 08: RENAME INDEXES AND CONSTRAINTS DATA.FACT_PAYMENT_1_OLD
  EXEC sp_rename 'DATA.FK_PAYMENT1_DATE', 'FK_PAYMENT1_DATE_OLD';
  EXEC sp_rename 'DATA.FK_PAYMENT1_CREDIT', 'FK_PAYMENT1_CREDIT_OLD';

  -- STEP 09: REPLACE SYNONYM DATA.FACT_PAYMENT TO DATA.FACT_PAYMENT_1_OLD
  DROP SYNONYM DATA.FACT_PAYMENT;
  CREATE SYNONYM DATA.FACT_PAYMENT FOR DATA.FACT_PAYMENT_1_OLD;

  -- STEP 10: RENAME TABLE DATA.FACT_PAYMENT_1_PREV TO DATA.FACT_PAYMENT_1
  EXEC sp_rename 'DATA.FACT_PAYMENT_1_PREV', 'FACT_PAYMENT_1';

  -- STEP 11: RENAME INDEXES AND CONSTRAINTS DATA.FACT_PAYMENT_1_PREV 
  EXEC sp_rename 'DATA.FK_PAYMENT1_DATE_PREV', 'FK_PAYMENT1_DATE';
  EXEC sp_rename 'DATA.FK_PAYMENT1_CREDIT_PREV', 'FK_PAYMENT1_CREDIT';

  -- STEP 12: REPLACE SYNONYM DATA.FACT_PAYMENT TO DATA.FACT_PAYMENT_1
  DROP SYNONYM DATA.FACT_PAYMENT;
  CREATE SYNONYM DATA.FACT_PAYMENT FOR DATA.FACT_PAYMENT_1;

  -- STEP 10: DROP OLD TABLE
  IF OBJECT_ID(N'[CIP_DM].[DATA].[FACT_PAYMENT_1_OLD]',N'U') IS NOT NULL DROP TABLE CIP_DM.DATA.FACT_PAYMENT_1_OLD;

  -- STEP 11: ADD DEFAULT CONSTRAINTS
  ALTER TABLE DATA.FACT_PAYMENT_1 ADD CONSTRAINT DF_FACTPAYMENT1_CREATIONUSER
    DEFAULT CAST(SERVERPROPERTY('ServerName') AS NVARCHAR) + '-' + CAST(SERVERPROPERTY('MachineName') AS NVARCHAR)
      FOR CREATION_USER;
  ALTER TABLE DATA.FACT_PAYMENT_1 ADD CONSTRAINT DF_FACTPAYMENT1_CREATIONDATE DEFAULT GETDATE()
      FOR CREATION_DATE;
  ALTER TABLE DATA.FACT_PAYMENT_1 ADD CONSTRAINT DF_FACTPAYMENT1_CREATIONIP DEFAULT DBO.FN_GET_CURRENT_IP()
      FOR CREATION_IP;

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