DROP TABLE [DATA].[DEBT_RECOVERY_1];
DROP TABLE [DATA].[FACT_NEGOTATION_1];
DROP TABLE [DATA].[HIST_ASSIGNMENT_1];
DROP TABLE [DATA].[FACT_PAYMENT_1];

DROP TABLE [DATA].[DIM_NEGOTIATOR];
DROP TABLE [DATA].[DIM_CREDIT];
DROP TABLE [DATA].[DIM_PRODUCT];

DROP SEQUENCE [DATA].[SQ_I1_KEY_DIM_CREDIT];
DROP SEQUENCE [DATA].[SQ_I1_KEY_DIM_NEGOTIATOR];
DROP SEQUENCE [DATA].[SQ_I1_KEY_DIM_PRODUCT];

CREATE SEQUENCE DATA.SQ_I1_KEY_DIM_CREDIT AS INTEGER START WITH 1 INCREMENT BY 1 MINVALUE 1 MAXVALUE 999999999 NO CYCLE NO CACHE;
CREATE SEQUENCE DATA.SQ_I1_KEY_DIM_NEGOTIATOR AS INTEGER START WITH 1 INCREMENT BY 1 MINVALUE 1 MAXVALUE 999999999 NO CYCLE NO CACHE;
CREATE SEQUENCE DATA.SQ_I1_KEY_DIM_PRODUCT AS INTEGER START WITH 1 INCREMENT BY 1 MINVALUE 1 MAXVALUE 999999999 NO CYCLE NO CACHE;

CREATE TABLE DATA.DIM_PRODUCT (
  PRODUCT_KEY INTEGER NOT NULL CONSTRAINT DF_DIMPRODUCT_PRODUCTKEY DEFAULT (NEXT VALUE FOR DATA.SQ_I1_KEY_DIM_PRODUCT),
  PRODUCT_NAME NVARCHAR(255),
  CREATION_USER VARCHAR(100) NOT NULL CONSTRAINT DF_DIMPRODUCT_CREATIONUSER DEFAULT CAST(SERVERPROPERTY('ServerName') AS NVARCHAR) + '-' + CAST(SERVERPROPERTY('MachineName') AS NVARCHAR),
  CREATION_DATE DATETIME NOT NULL CONSTRAINT DF_DIMPRODUCT_CREATIONDATE DEFAULT GETDATE(),
  CREATION_IP VARCHAR(50) NOT NULL CONSTRAINT DF_DIMPRODUCT_CREATIONIP DEFAULT DBO.FN_GET_CURRENT_IP(),
  MODIFICATION_USER VARCHAR(100) NULL,
  MODIFICATION_DATE DATETIME NULL,
  MODIFICATION_IP VARCHAR(50) NULL,
  CONSTRAINT PK_DIM_PRODUCT PRIMARY KEY (PRODUCT_KEY),
  CONSTRAINT UQ_DIMPRODUCT_PRODUCTNAME UNIQUE (PRODUCT_NAME)
);

CREATE TABLE DATA.DIM_CREDIT (
  CREDIT_KEY INTEGER NOT NULL CONSTRAINT DF_DIMCREDIT_CREDITKEY DEFAULT (NEXT VALUE FOR DATA.SQ_I1_KEY_DIM_CREDIT),
  PRODUCT_KEY INTEGER NOT NULL,
  CREDIT_CODE VARCHAR(100),
  CLIENT_CODE VARCHAR(100),
  CLIENT_DOCN VARCHAR(50),
  CLIENT_NAME NVARCHAR(255),
  PORTFOLIO_NAME NVARCHAR(255),
  CREATION_USER VARCHAR(100) NOT NULL CONSTRAINT DF_DIMCREDIT_CREATIONUSER DEFAULT CAST(SERVERPROPERTY('ServerName') AS NVARCHAR) + '-' + CAST(SERVERPROPERTY('MachineName') AS NVARCHAR),
  CREATION_DATE DATETIME NOT NULL CONSTRAINT DF_DIMCREDIT_CREATIONDATE DEFAULT GETDATE(),
  CREATION_IP VARCHAR(50) NOT NULL CONSTRAINT DF_DIMCREDIT_CREATIONIP DEFAULT DBO.FN_GET_CURRENT_IP(),
  MODIFICATION_USER VARCHAR(100) NULL,
  MODIFICATION_DATE DATETIME NULL,
  MODIFICATION_IP VARCHAR(50) NULL,
  CONSTRAINT PK_DIM_CREDIT PRIMARY KEY (CREDIT_KEY),
  CONSTRAINT FK_DIMCREDIT_DIMPRODUCT_PRODUCTKEY FOREIGN KEY (PRODUCT_KEY)
    REFERENCES DATA.DIM_PRODUCT(PRODUCT_KEY),
  CONSTRAINT UQ_DIMCREDIT_CREDITCODE UNIQUE (CREDIT_CODE)
);
CREATE TABLE DATA.DIM_NEGOTIATOR (
  NEGOTIATOR_KEY INTEGER NOT NULL CONSTRAINT DF_DIMNEGOTIATOR_NEGOTIATORKEY DEFAULT (NEXT VALUE FOR DATA.SQ_I1_KEY_DIM_NEGOTIATOR),
  NEGOTIATOR_CODE VARCHAR(100),
  NEGOTIATOR_NAME NVARCHAR(255),
  CREATION_USER VARCHAR(100) NOT NULL CONSTRAINT DF_DIMNEGOTIATOR_CREATIONUSER DEFAULT CAST(SERVERPROPERTY('ServerName') AS NVARCHAR) + '-' + CAST(SERVERPROPERTY('MachineName') AS NVARCHAR),
  CREATION_DATE DATETIME NOT NULL CONSTRAINT DF_DIMNEGOTIATOR_CREATIONDATE DEFAULT GETDATE(),
  CREATION_IP VARCHAR(50) NOT NULL CONSTRAINT DF_DIMNEGOTIATOR_CREATIONIP DEFAULT DBO.FN_GET_CURRENT_IP(),
  MODIFICATION_USER VARCHAR(100) NULL,
  MODIFICATION_DATE DATETIME NULL,
  MODIFICATION_IP VARCHAR(50) NULL,
  CONSTRAINT PK_DIM_NEGOTIATOR PRIMARY KEY (NEGOTIATOR_KEY),
  CONSTRAINT UQ_DIMNEGOTIATOR_NEGOTIATORCODE UNIQUE (NEGOTIATOR_CODE)
);

-- CREATE TABLE
CREATE TABLE DATA.FACT_NEGOTATION_1 (
  CREDIT_KEY INTEGER NOT NULL,
  ACTION_KEY INTEGER NOT NULL,
  RESPONSE_KEY INTEGER NOT NULL,
  CONTACT_KEY INTEGER NOT NULL,
  NEGOTIATOR_KEY INTEGER NOT NULL,
  CARRIER_NAME VARCHAR(255),
  HISTORY_DATE INTEGER NOT NULL,
  OBSERVATION NVARCHAR(1500),
  TELEPHONE_NUMBER VARCHAR(255),
  TELEPHONE_STATUS VARCHAR(255),
  PROMISE_AMNT DECIMAL(18,2),
  PROMISE_NEXT_DATE INTEGER NOT NULL,
  FLAG CHAR(1),
  CREATION_USER VARCHAR(100) NOT NULL CONSTRAINT DF_FACTNEGOTATION1_CREATIONUSER DEFAULT CAST(SERVERPROPERTY('ServerName') AS NVARCHAR) + '-' + CAST(SERVERPROPERTY('MachineName') AS NVARCHAR),
  CREATION_DATE DATETIME NOT NULL CONSTRAINT DF_FACTNEGOTATION1_CREATIONDATE DEFAULT GETDATE(),
  CREATION_IP VARCHAR(50) NOT NULL CONSTRAINT DF_FACTNEGOTATION1_CREATIONIP DEFAULT DBO.FN_GET_CURRENT_IP(),
  MODIFICATION_USER VARCHAR(100) NULL,
  MODIFICATION_DATE DATETIME NULL,
  MODIFICATION_IP VARCHAR(50) NULL,
  CONSTRAINT FK_FACTNEG1_DIMCRED_CREDITKEY FOREIGN KEY (CREDIT_KEY)
    REFERENCES DATA.DIM_CREDIT(CREDIT_KEY),
  CONSTRAINT FK_FACTNEG1_DIMACT_ACTIONKEY FOREIGN KEY (ACTION_KEY)
    REFERENCES DATA.DIM_ACTION(ACTION_KEY),
  CONSTRAINT FK_FACTNEG1_DIMRESP_RESPONSEKEY FOREIGN KEY (RESPONSE_KEY)
    REFERENCES DATA.DIM_RESPONSE(RESPONSE_KEY),
  CONSTRAINT FK_FACTNEG1_DIMCON_CONTACTKEY FOREIGN KEY (CONTACT_KEY)
    REFERENCES DATA.DIM_CONTACT(CONTACT_KEY),
  CONSTRAINT FK_FACTNEG1_DIMNEG_NEGOTIATORKEY FOREIGN KEY (NEGOTIATOR_KEY)
    REFERENCES DATA.DIM_NEGOTIATOR(NEGOTIATOR_KEY),
  CONSTRAINT FK_FACTNEG1_DIMDATE_HISTORYDATE FOREIGN KEY (HISTORY_DATE)
    REFERENCES DATA.DIM_DATE(DATE_KEY)
);

CREATE TABLE DATA.FACT_PAYMENT_1 (
  CREDIT_KEY INTEGER NOT NULL,
  PAYMENT_DATE INTEGER NOT NULL,
  CURRENCY_KEY CHAR(3) NOT NULL,
  AMOUNT DECIMAL(18,2) NOT NULL,
  CREATION_USER VARCHAR(100) NOT NULL CONSTRAINT DF_FACTPAYMENT1_CREATIONUSER DEFAULT CAST(SERVERPROPERTY('ServerName') AS NVARCHAR) + '-' + CAST(SERVERPROPERTY('MachineName') AS NVARCHAR),
  CREATION_DATE DATETIME NOT NULL CONSTRAINT DF_FACTPAYMENT1_CREATIONDATE DEFAULT GETDATE(),
  CREATION_IP VARCHAR(50) NOT NULL CONSTRAINT DF_FACTPAYMENT1_CREATIONIP DEFAULT DBO.FN_GET_CURRENT_IP(),
  MODIFICATION_USER VARCHAR(100) NULL,
  MODIFICATION_DATE DATETIME NULL,
  MODIFICATION_IP VARCHAR(50) NULL,
  CONSTRAINT FK_FACTPAY1_DIMCRED_CREDITKEY FOREIGN KEY (CREDIT_KEY)
    REFERENCES DATA.DIM_CREDIT(CREDIT_KEY),
  CONSTRAINT FK_FACTPAY1_DIMDATE_PYMNTDATE FOREIGN KEY (PAYMENT_DATE)
    REFERENCES DATA.DIM_DATE(DATE_KEY),
  CONSTRAINT FK_FACTPAY1_DIMCUR_CURRENCYKEY FOREIGN KEY (CURRENCY_KEY)
    REFERENCES DATA.DIM_CURRENCY(CURRENCY_KEY)
);



CREATE TABLE DATA.HIST_ASSIGNMENT_1 (
  PERIOD_CODE INTEGER NOT NULL, /* FORMAT YYYYMM */
  CREDIT_KEY INTEGER NOT NULL,
  NEGOTIATOR_KEY INTEGER NOT NULL,
  PRINCIPAL_AMNT DECIMAL(18,2),
  NET_DEBT_AMNT DECIMAL(18,2),
  CREATION_USER VARCHAR(100) NOT NULL CONSTRAINT DF_HISTASSIGNMENT1_CREATIONUSER DEFAULT CAST(SERVERPROPERTY('ServerName') AS NVARCHAR) + '-' + CAST(SERVERPROPERTY('MachineName') AS NVARCHAR),
  CREATION_DATE DATETIME NOT NULL CONSTRAINT DF_HISTASSIGNMENT1_CREATIONDATE DEFAULT GETDATE(),
  CREATION_IP VARCHAR(50) NOT NULL CONSTRAINT DF_HISTASSIGNMENT1_CREATIONIP DEFAULT DBO.FN_GET_CURRENT_IP(),
  MODIFICATION_USER VARCHAR(100) NULL,
  MODIFICATION_DATE DATETIME NULL,
  MODIFICATION_IP VARCHAR(50) NULL,
  CONSTRAINT FK_HISTASGMT1_DIMCREDIT_CREDITKEY FOREIGN KEY (CREDIT_KEY)
    REFERENCES DATA.DIM_CREDIT(CREDIT_KEY),
  CONSTRAINT FK_HISTASGMT1_DIMNEGOT_NEGOTIATORKEY FOREIGN KEY (NEGOTIATOR_KEY)
    REFERENCES DATA.DIM_NEGOTIATOR(NEGOTIATOR_KEY),
  CONSTRAINT UQ_HISTASGMT1_PERIODCODE_CREDITKEY UNIQUE (PERIOD_CODE, CREDIT_KEY)
);

CREATE TABLE DATA.DEBT_RECOVERY_1 (
  PAYMENT_DATE INTEGER NOT NULL,
  PRODUCT_KEY INTEGER NOT NULL,
  NEGOTIATOR_KEY INTEGER NOT NULL,
  CURRENCY_KEY CHAR(3) NOT NULL,
  PAYMENTS INTEGER NOT NULL,
  AMOUNT_RECOVERED DECIMAL(18,2) NOT NULL
  CONSTRAINT FK_DEBTRECOVERY1_DATE FOREIGN KEY (PAYMENT_DATE)
    REFERENCES DATA.DIM_DATE(DATE_KEY),
  CONSTRAINT FK_DEBTRECOVERY1_PRODUCT FOREIGN KEY (PRODUCT_KEY)
    REFERENCES DATA.DIM_PRODUCT(PRODUCT_KEY),
  CONSTRAINT FK_DEBTRECOVERY1_NEGOTIATOR FOREIGN KEY (NEGOTIATOR_KEY)
    REFERENCES DATA.DIM_NEGOTIATOR(NEGOTIATOR_KEY),
  CONSTRAINT FK_DEBTRECOVERY1_CURRENCY FOREIGN KEY (CURRENCY_KEY)
    REFERENCES DATA.DIM_CURRENCY(CURRENCY_KEY)
);