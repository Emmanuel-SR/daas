CREATE TABLE DATA.DIM_CREDIT (
  CREDIT_KEY INTEGER NOT NULL CONSTRAINT DF_DIMCREDIT_CREDITKEY DEFAULT (NEXT VALUE FOR DATA.SQ_I1_KEY_DIM_CREDIT),
  CREDIT_CODE VARCHAR(100),
  CLIENT_CODE VARCHAR(100),
  CLIENT_DOCN VARCHAR(50),
  CLIENT_NAME NVARCHAR(255),
  CREATION_USER VARCHAR(100) NOT NULL CONSTRAINT DF_DIMCREDIT_CREATIONUSER DEFAULT CAST(SERVERPROPERTY('ServerName') AS NVARCHAR) + '-' + CAST(SERVERPROPERTY('MachineName') AS NVARCHAR),
  CREATION_DATE DATETIME NOT NULL CONSTRAINT DF_DIMCREDIT_CREATIONDATE DEFAULT GETDATE(),
  CREATION_IP VARCHAR(50) NOT NULL CONSTRAINT DF_DIMCREDIT_CREATIONIP DEFAULT DBO.FN_GET_CURRENT_IP(),
  MODIFICATION_USER VARCHAR(100) NULL,
  MODIFICATION_DATE DATETIME NULL,
  MODIFICATION_IP VARCHAR(50) NULL,
  CONSTRAINT PK_DIM_CREDIT PRIMARY KEY (CREDIT_KEY)
);