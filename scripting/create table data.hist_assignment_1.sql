CREATE TABLE DATA.HIST_ASSIGNMENT_1 (
  PERIOD_CODE INTEGER NOT NULL, /* FORMAT YYYYMM */
  CREDIT_KEY INTEGER NOT NULL,
  NEGOTIATOR_KEY INTEGER NOT NULL,
  PRINCIPAL_AMNT DECIMAL(18,2),
  NET_DEBT_AMNT DECIMAL(18,2),
  CREATION_USER VARCHAR(100) NOT NULL CONSTRAINT DF_HISTASSIGNMENT1_CREATIONUSER DEFAULT CAST(SERVERPROPERTY('ServerName') AS NVARCHAR) + '-' + CAST(SERVERPROPERTY('MachineName') AS NVARCHAR),
  CREATION_DATE DATETIME  NOT NULL CONSTRAINT DF_HISTASSIGNMENT1_CREATIONDATE DEFAULT GETDATE(),
  CREATION_IP VARCHAR(50) NOT NULL CONSTRAINT DF_HISTASSIGNMENT1_CREATIONIP DEFAULT DBO.FN_GET_CURRENT_IP(),
  MODIFICATION_USER VARCHAR(100) NULL,
  MODIFICATION_DATE DATETIME NULL,
  MODIFICATION_IP VARCHAR(50) NULL,
  CONSTRAINT FK_ASSIGNMENT1_CREDIT FOREIGN KEY (CREDIT_KEY)
    REFERENCES DATA.DIM_CREDIT(CREDIT_KEY),
  CONSTRAINT FK_ASSIGNMENT1_NEGOTIATOR FOREIGN KEY (NEGOTIATOR_KEY)
    REFERENCES DATA.DIM_NEGOTIATOR(NEGOTIATOR_KEY),
  CONSTRAINT PK_HIST_ASSIGNMENT_1 PRIMARY KEY (PERIOD_CODE, CREDIT_KEY)
);