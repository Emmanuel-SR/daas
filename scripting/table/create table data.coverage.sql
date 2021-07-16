CREATE TABLE DATA.COVERAGE_1 (
  DATE_KEY INTEGER NOT NULL,
  PRODUCT_KEY INTEGER NOT NULL,
  NEGOTIATOR_KEY INTEGER NOT NULL,
  COVERAGE INTEGER NOT NULL,
  CONTACTED INTEGER NOT NULL,
  ASSIGMENTS INTEGER NOT NULL,
  CONSTRAINT FK_COVG1_DIMDATE_DATEKEY FOREIGN KEY (DATE_KEY)
    REFERENCES DATA.DIM_DATE(DATE_KEY),
  CONSTRAINT FK_COVG1_PRODUCT_KEY FOREIGN KEY (PRODUCT_KEY)
    REFERENCES DATA.DIM_PRODUCT(PRODUCT_KEY),
  CONSTRAINT FK_COVG1_NEGOTIATOR_KEY FOREIGN KEY (NEGOTIATOR_KEY)
    REFERENCES DATA.DIM_NEGOTIATOR(NEGOTIATOR_KEY)
);