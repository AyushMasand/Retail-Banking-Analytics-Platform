USE BankingAnalyticsDB;

DROP TABLE IF EXISTS silver.customers;

GO 

CREATE TABLE silver.customers
(
    customer_id INT,
    full_name VARCHAR(200),
    gender VARCHAR(20),
    date_of_birth DATE,
    city VARCHAR(100),
    occupation VARCHAR(100),
    income_band VARCHAR(50),
    join_date DATETIME
);

GO

DROP TABLE IF EXISTS silver.accounts;

GO

CREATE TABLE silver.accounts
(
    account_id INT,
    customer_id INT,
    account_type VARCHAR(50),
    account_status VARCHAR(50),
    open_date DATE,
    current_balance DECIMAL(18,2)
);

GO

DROP TABLE IF EXISTS silver.transactions;

GO

CREATE TABLE silver.transactions
(
    transaction_id BIGINT,
    account_id INT,
    transaction_date DATETIME,
    transaction_type VARCHAR(100),
    amount DECIMAL(18,2),
    merchant_category VARCHAR(100),
    channel VARCHAR(100),
    locations VARCHAR(100)
);

GO

DROP TABLE IF EXISTS silver.customer_service_tickets;

GO

CREATE TABLE silver.customer_service_tickets
(
    ticket_id INT,
    customer_id INT,
    issue_type VARCHAR(100),
    created_at DATETIME,
    resolved_at DATETIME,
    satisfaction_score INT
);

GO

DROP TABLE IF EXISTS silver.loans;

GO

CREATE TABLE silver.loans
(
    loan_id INT,
    customer_id INT,
    loan_type VARCHAR(100),
    loan_amount DECIMAL(18,2),
    interest_rate DECIMAL(5,2),
    loan_status VARCHAR(50)
);