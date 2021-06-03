CREATE TABLE DATA.DIM_DATE (
  DATE_KEY INTEGER NOT NULL /* formato YYYYMMDD*/,
  [DATE] DATE NOT NULL,
  CALENDAR_YEAR INTEGER NOT NULL, /* YYYY */
  CALENDAR_SEMESTER_OF_YEAR TINYINT NOT NULL, /* 1 to 2 */
  CALENDAR_QUARTER_OF_YEAR TINYINT NOT NULL, /* 1 to 4 */
  MONTH_NUMBER_OF_YEAR TINYINT NOT NULL, /* 1 to 12 */
  DAY_NUMBER_OF_WEEK TINYINT NOT NULL, /* 1 to 7 */
  DAY_NUMBER_OF_MONTH INTEGER NOT NULL, /* 1 to 31 */
  CREATION_USER VARCHAR(100) NOT NULL CONSTRAINT DF_DIMFECHA_CREATIONUSER DEFAULT CAST(SERVERPROPERTY('ServerName') AS NVARCHAR) + '-' + CAST(SERVERPROPERTY('MachineName') AS NVARCHAR),
  CREATION_DATE DATETIME  NOT NULL CONSTRAINT DF_DIMFECHA_CREATIONDATE DEFAULT GETDATE(),
  CREATION_IP VARCHAR(50) NOT NULL CONSTRAINT DF_DIMFECHA_CREATIONIP DEFAULT DBO.FN_GET_CURRENT_IP(),
  MODIFICATION_USER VARCHAR(100) NULL,
  MODIFICATION_DATE DATETIME NULL,
  MODIFICATION_IP VARCHAR(50) NULL
  CONSTRAINT PK_DIM_DATE PRIMARY KEY (DATE_KEY)
);