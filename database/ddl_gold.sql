-- CREATING DDL FOR GOLD LAYER 

DROP TABLE IF EXISTS gold.customer_activity_summary;

CREATE TABLE gold.customer_activity_summary (
    customer_id INT PRIMARY KEY,
    transaction_count INT,
    total_transaction_amount DECIMAL(18,2),
    avg_transaction_amount DECIMAL(18,2),
    join_date DATETIME,
    first_transaction_date DATETIME,
    last_transaction_date DATETIME,
    days_since_last_transaction INT,
    active_flag VARCHAR(20)
);

DROP TABLE IF EXISTS gold.customer_value_segmentation;

CREATE TABLE gold.customer_value_segmentation (
    customer_id INT PRIMARY KEY,
    total_transaction_amount DECIMAL(18,2),
    transaction_count INT,
    total_balance DECIMAL(18,2),
    customer_contribution_pct DECIMAL(10,4),
    customer_rank INT,
    value_segment VARCHAR(50)
);

DROP TABLE IF EXISTS gold.customer_service_summary;

CREATE TABLE gold.customer_service_summary (
    customer_id INT PRIMARY KEY,
    ticket_count INT,
    avg_satisfaction_score DECIMAL(5,2),
    last_ticket_date DATETIME,
    customer_satisfaction VARCHAR(20)
);

DROP TABLE IF EXISTS gold.transaction_risk_flags;

CREATE TABLE gold.transaction_risk_flags (
    transaction_id BIGINT PRIMARY KEY,
    customer_id INT,
    transaction_date DATETIME,
    transaction_amount DECIMAL(18,2),
    days_since_last_transaction INT,
    transaction_count_last_hour INT,
    risk_type VARCHAR(100),
    risk_reason VARCHAR(255)
);
DROP TABLE IF EXISTS gold.customer_loan_summary;

CREATE TABLE gold.customer_loan_summary (
    customer_id INT PRIMARY KEY,
    loan_count INT,
    total_loan_amount DECIMAL(18,2),
    avg_loan_amount DECIMAL(18,2),
    largest_loan_amount DECIMAL(18,2),
    active_loan_count INT,
    defaulted_loan_count INT,
    closed_loan_count INT,
    is_defaulted BIT
);

