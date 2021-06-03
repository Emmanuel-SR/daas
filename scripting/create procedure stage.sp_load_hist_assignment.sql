CREATE PROCEDURE STAGE.SP_LOAD_HIST_ASSIGNMENT (@LOAD_DATE AS DATE) AS

BEGIN

  DECLARE @CREATION_USER AS VARCHAR(100);
  DECLARE @CREATION_DATE AS DATETIME;
  DECLARE @CREATION_IP AS VARCHAR(50);
  DECLARE @PERIOD AS CHAR(6);

  BEGIN TRY

  SELECT @CREATION_USER = CAST(SERVERPROPERTY('ServerName') AS NVARCHAR) + '-' + CAST(SERVERPROPERTY('MachineName') AS NVARCHAR);
  SELECT @CREATION_DATE = GETDATE();
  SELECT @CREATION_IP = DBO.FN_GET_CURRENT_IP();

  SELECT @PERIOD = LEFT(CONVERT(CHAR, @LOAD_DATE, 112), 6);  /* YYYYMM */

  -- STEP 01: CREATE TABLE STAGE.TMP_HIST_ASSIGNMENT_01
  IF OBJECT_ID(N'[CIP_DM].[STAGE].[TMP_HIST_ASSIGNMENT_01]',N'U') IS NOT NULL DROP TABLE CIP_DM.STAGE.TMP_HIST_ASSIGNMENT_01;

    SELECT
      H1.PERIOD_CODE,
      H1.CREDIT_KEY,
      H1.NEGOTIATOR_KEY,
      H1.PRINCIPAL_AMNT,
      H1.NET_DEBT_AMNT,
      H1.CREATION_USER,
      H1.CREATION_DATE,
      H1.CREATION_IP,
      H1.MODIFICATION_USER,
      H1.MODIFICATION_DATE,
      H1.MODIFICATION_IP
    INTO STAGE.TMP_HIST_ASSIGNMENT_01
    FROM DATA.HIST_ASSIGNMENT_1 H1
    WHERE H1.PERIOD_CODE <> @PERIOD;

  -- STEP 02: CREATE TABLE STAGE.TMP_HIST_ASSIGNMENT_02
  IF OBJECT_ID(N'[CIP_DM].[STAGE].[TMP_HIST_ASSIGNMENT_02]',N'U') IS NOT NULL DROP TABLE CIP_DM.STAGE.TMP_HIST_ASSIGNMENT_02;

    SELECT
      @PERIOD AS PERIOD_CODE,
      C.CREDIT_KEY,
      G.NEGOTIATOR_KEY,
      CAST(H.PRINCIPAL_AMNT AS DECIMAL(18,2)) AS PRINCIPAL_AMNT,
      CAST(H.NET_DEBT_AMNT AS DECIMAL(18,2)) AS NET_DEBT_AMNT,
      @CREATION_USER AS CREATION_USER,
      @CREATION_DATE AS CREATION_DATE,
      @CREATION_IP AS CREATION_IP,
      CAST(NULL AS VARCHAR(100)) AS MODIFICATION_USER,
      CAST(NULL AS DATETIME) AS MODIFICATION_DATE,
      CAST(NULL AS VARCHAR(50)) AS MODIFICATION_IP
    INTO STAGE.TMP_HIST_ASSIGNMENT_02
    FROM STAGE.HIST_ASSIGNMENT H
    LEFT JOIN DATA.DIM_CREDIT C ON C.CREDIT_CODE = H.CREDIT_CODE
    LEFT JOIN DATA.DIM_NEGOTIATOR G ON G.NEGOTIATOR_CODE = H.NEGOTIATOR_CODE;

  -- STEP 03: CREATE TABLE DATA.HIST_ASSIGNMENT_1_PREV
  IF OBJECT_ID(N'[CIP_DM].[DATA].[HIST_ASSIGNMENT_1_PREV]',N'U') IS NOT NULL DROP TABLE CIP_DM.DATA.HIST_ASSIGNMENT_1_PREV;

  SELECT
    PREV.PERIOD_CODE,
    PREV.CREDIT_KEY,
    PREV.NEGOTIATOR_KEY,
    PREV.PRINCIPAL_AMNT,
    PREV.NET_DEBT_AMNT,
    PREV.CREATION_USER,
    PREV.CREATION_DATE,
    PREV.CREATION_IP,
    PREV.MODIFICATION_USER,
    PREV.MODIFICATION_DATE,
    PREV.MODIFICATION_IP
  INTO DATA.HIST_ASSIGNMENT_1_PREV FROM
  (SELECT
    H1.PERIOD_CODE,
    H1.CREDIT_KEY,
    H1.NEGOTIATOR_KEY,
    H1.PRINCIPAL_AMNT,
    H1.NET_DEBT_AMNT,
    H1.CREATION_USER,
    H1.CREATION_DATE,
    H1.CREATION_IP,
    H1.MODIFICATION_USER,
    H1.MODIFICATION_DATE,
    H1.MODIFICATION_IP
  FROM STAGE.TMP_HIST_ASSIGNMENT_01 H1
  UNION
  SELECT
    H2.PERIOD_CODE,
    H2.CREDIT_KEY,
    H2.NEGOTIATOR_KEY,
    H2.PRINCIPAL_AMNT,
    H2.NET_DEBT_AMNT,
    H2.CREATION_USER,
    H2.CREATION_DATE,
    H2.CREATION_IP,
    H2.MODIFICATION_USER,
    H2.MODIFICATION_DATE,
    H2.MODIFICATION_IP
  FROM STAGE.TMP_HIST_ASSIGNMENT_02 H2) PREV;

  -- STEP 04: DROP TMP TABLAS
  IF OBJECT_ID(N'[CIP_DM].[STAGE].[TMP_HIST_ASSIGNMENT_01]',N'U') IS NOT NULL DROP TABLE CIP_DM.STAGE.TMP_HIST_ASSIGNMENT_01;
  IF OBJECT_ID(N'[CIP_DM].[STAGE].[TMP_HIST_ASSIGNMENT_02]',N'U') IS NOT NULL DROP TABLE CIP_DM.STAGE.TMP_HIST_ASSIGNMENT_02;

  -- STEP 05: CREATE INDEXES AND CONSTRAINTS DATA.HIST_ASSIGNMENT_1_PREV
  ALTER TABLE DATA.HIST_ASSIGNMENT_1_PREV ALTER COLUMN PERIOD_CODE INTEGER NOT NULL;
  ALTER TABLE DATA.HIST_ASSIGNMENT_1_PREV ALTER COLUMN CREDIT_KEY INTEGER NOT NULL;
  ALTER TABLE DATA.HIST_ASSIGNMENT_1_PREV ALTER COLUMN NEGOTIATOR_KEY INTEGER NOT NULL;
  ALTER TABLE DATA.HIST_ASSIGNMENT_1_PREV ADD CONSTRAINT FK_ASSIGNMENT1_CREDIT_PREV FOREIGN KEY (CREDIT_KEY)
    REFERENCES DATA.DIM_CREDIT(CREDIT_KEY);
  ALTER TABLE DATA.HIST_ASSIGNMENT_1_PREV ADD CONSTRAINT FK_ASSIGNMENT1_NEGOTIATOR_PREV FOREIGN KEY (NEGOTIATOR_KEY)
    REFERENCES DATA.DIM_NEGOTIATOR(NEGOTIATOR_KEY);
  ALTER TABLE DATA.HIST_ASSIGNMENT_1_PREV ADD CONSTRAINT PK_HIST_ASSIGNMENT_1_PREV UNIQUE (PERIOD_CODE, CREDIT_KEY);

  -- STEP 06: REPLACE SYNONYM DATA.HIST_ASSIGNMENT TO DATA.HIST_ASSIGNMENT_1_PREV
  DROP SYNONYM DATA.HIST_ASSIGNMENT;
  CREATE SYNONYM DATA.HIST_ASSIGNMENT FOR DATA.HIST_ASSIGNMENT_1_PREV;

  -- STEP 07: RENAME TABLE DATA.HIST_ASSIGNMENT_1 TO DATA.HIST_ASSIGNMENT_1_OLD
  EXEC sp_rename 'DATA.HIST_ASSIGNMENT_1', 'HIST_ASSIGNMENT_1_OLD';

  -- STEP 08: RENAME INDEXES AND CONSTRAINTS DATA.HIST_ASSIGNMENT_1_OLD
  EXEC sp_rename 'DATA.FK_ASSIGNMENT1_CREDIT', 'FK_ASSIGNMENT1_CREDIT_OLD';
  EXEC sp_rename 'DATA.FK_ASSIGNMENT1_NEGOTIATOR', 'FK_ASSIGNMENT1_NEGOTIATOR_OLD';
  EXEC sp_rename 'DATA.PK_HIST_ASSIGNMENT_1', 'PK_HIST_ASSIGNMENT_1_OLD';

  -- STEP 09: REPLACE SYNONYM DATA.HIST_ASSIGNMENT TO DATA.HIST_ASSIGNMENT_1_OLD
  DROP SYNONYM DATA.HIST_ASSIGNMENT;
  CREATE SYNONYM DATA.HIST_ASSIGNMENT FOR DATA.HIST_ASSIGNMENT_1_OLD;

  -- STEP 10: RENAME TABLE DATA.HIST_ASSIGNMENT_1_PREV TO DATA.HIST_ASSIGNMENT_1
  EXEC sp_rename 'DATA.HIST_ASSIGNMENT_1_PREV', 'HIST_ASSIGNMENT_1';

  -- STEP 11: RENAME INDEXES AND CONSTRAINTS DATA.HIST_ASSIGNMENT_1_PREV 
  EXEC sp_rename 'DATA.FK_ASSIGNMENT1_CREDIT_PREV', 'FK_ASSIGNMENT1_CREDIT';
  EXEC sp_rename 'DATA.FK_ASSIGNMENT1_NEGOTIATOR_PREV', 'FK_ASSIGNMENT1_NEGOTIATOR';
  EXEC sp_rename 'DATA.PK_HIST_ASSIGNMENT_1_PREV', 'PK_HIST_ASSIGNMENT_1';

  -- STEP 12: REPLACE SYNONYM DATA.HIST_ASSIGNMENT TO DATA.HIST_ASSIGNMENT_1
  DROP SYNONYM DATA.HIST_ASSIGNMENT;
  CREATE SYNONYM DATA.HIST_ASSIGNMENT FOR DATA.HIST_ASSIGNMENT_1;

  -- STEP 10: DROP OLD TABLE
  IF OBJECT_ID(N'[CIP_DM].[DATA].[HIST_ASSIGNMENT_1_OLD]',N'U') IS NOT NULL DROP TABLE CIP_DM.DATA.HIST_ASSIGNMENT_1_OLD;

  -- STEP 11: ADD DEFAULT CONSTRAINTS
  ALTER TABLE DATA.HIST_ASSIGNMENT_1 ADD CONSTRAINT DF_HISTASSIGNMENT1_CREATIONUSER
    DEFAULT CAST(SERVERPROPERTY('ServerName') AS NVARCHAR) + '-' + CAST(SERVERPROPERTY('MachineName') AS NVARCHAR)
      FOR CREATION_USER;
  ALTER TABLE DATA.HIST_ASSIGNMENT_1 ADD CONSTRAINT DF_HISTASSIGNMENT1_CREATIONDATE DEFAULT GETDATE()
      FOR CREATION_DATE;
  ALTER TABLE DATA.HIST_ASSIGNMENT_1 ADD CONSTRAINT DF_HISTASSIGNMENT1_CREATIONIP DEFAULT DBO.FN_GET_CURRENT_IP()
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