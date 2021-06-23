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