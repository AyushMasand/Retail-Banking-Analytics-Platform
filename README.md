# Retail-Banking-Analytics-Platform
Built an end-to-end Retail Banking Analytics Platform using SQL Server and a Medallion Architecture (Bronze, Silver, Gold). Automated ETL pipelines transform raw banking data into business-ready data marts, enabling customer engagement analysis, relationship banking, credit exposure monitoring, fraud detection, and executive decision support.

# 🏦 Retail Banking Analytics Platform

### End-to-End SQL Server Data Warehouse & Decision Support System

![SQL Server](https://img.shields.io/badge/SQL%20Server-2019-red)
![T-SQL](https://img.shields.io/badge/T--SQL-Advanced-blue)
![Data Warehouse](https://img.shields.io/badge/Data-Warehouse-success)
![ETL](https://img.shields.io/badge/ETL-Medallion%20Architecture-orange)
![Status](https://img.shields.io/badge/Project-Completed-brightgreen)

---

# 📖 Project Overview

Retail banks process millions of customer interactions every day, including account activities, financial transactions, loan management, and customer service requests. These operational datasets are typically optimized for transaction processing rather than analytical reporting, making it difficult to generate business insights directly.

This project demonstrates how a modern SQL Server data warehouse can transform raw operational banking data into business-ready analytical datasets using the **Medallion Architecture (Bronze → Silver → Gold)**.

The platform automates data ingestion, standardization, business modeling, and analytical reporting to support customer engagement, relationship banking, credit exposure analysis, customer experience monitoring, and transaction risk detection.

The final output is an **Executive Customer Action Report**, providing a unified customer view to support operational and strategic decision-making.

---

# ❗ Business Problem

Retail banks continuously generate data across multiple operational systems, including customer accounts, transactions, lending, and customer support.

Although these systems efficiently process daily operations, they often make it difficult to answer important business questions such as:

* Which customers are becoming inactive?
* Which customers contribute the highest business value?
* Which high-value customers require proactive relationship management?
* Which customers represent significant credit exposure?
* Which transaction patterns should be investigated?
* Which customers require immediate business attention?

To address these challenges, this project builds a centralized analytics platform that converts raw banking data into reusable business data marts capable of supporting operational reporting and executive decision-making.

---

# 🎯 Project Objectives

The primary objectives of this project are:

* Design a scalable SQL Server data warehouse using the Medallion Architecture.
* Develop automated ETL pipelines for data ingestion and transformation.
* Standardize operational banking datasets for analytical use.
* Build business-oriented Gold Layer data marts.
* Generate actionable business insights using advanced SQL.
* Support customer retention, relationship banking, lending, and transaction risk analysis.
* Produce an Executive Customer Action Report integrating insights from multiple business domains.

---

# 📂 Dataset

The project uses five operational banking datasets representing core retail banking processes.

| Dataset                  | Description                                           |
| ------------------------ | ----------------------------------------------------- |
| Customers                | Customer demographic and registration information     |
| Accounts                 | Banking account details and balances                  |
| Transactions             | Customer financial transactions                       |
| Loans                    | Loan portfolio and repayment status                   |
| Customer Service Tickets | Customer support interactions and satisfaction scores |

These datasets simulate operational data commonly found within retail banking environments.

---

# 🏗️ Data Warehouse Architecture

The solution follows the Medallion Architecture to progressively improve data quality and business usability.

```text
                        CSV Files
                            │
                            ▼
                    Bronze Layer
              (Raw Data Ingestion)
                            │
                            ▼
                    Silver Layer
        (Cleaning & Standardization)
                            │
                            ▼
                     Gold Layer
           (Business Data Marts)
                            │
                            ▼
                 Business Insights
                            │
                            ▼
          Executive Customer Action Report
```

---

# 🥉 Bronze Layer

The Bronze Layer stores raw data exactly as received from the source files without applying business transformations.

### Responsibilities

* Raw data ingestion
* Preserve source records
* Enable data traceability
* Support repeatable ETL processing

---

# 🥈 Silver Layer

The Silver Layer standardizes operational data and prepares it for business analysis.

### Responsibilities

* Data cleansing
* Data validation
* Data standardization
* Duplicate handling
* Missing value handling
* Consistent data types
* Referential integrity

---

# 🥇 Gold Layer

The Gold Layer contains business-ready analytical data marts designed around business questions instead of operational systems.

### Gold Data Marts

| Data Mart                   | Business Purpose                           |
| --------------------------- | ------------------------------------------ |
| Customer Activity Summary   | Customer engagement and retention analysis |
| Customer Value Segmentation | Customer value and relationship banking    |
| Customer Service Summary    | Customer experience analysis               |
| Customer Loan Summary       | Credit exposure monitoring                 |
| Transaction Risk Flags      | Transaction risk monitoring                |


## 📊 Business Problems Solved

The analytics platform addresses key business challenges commonly faced by retail banks.

### 1. Customer Engagement & Retention
**Objective:** Monitor customer activity and identify customers requiring retention efforts.

**Analysis Includes:**
- Active vs Inactive customers
- Long-term inactive customers
- Customers who never transacted
- Inactive customers with active loans

---

### 2. Customer Value & Relationship Banking
**Objective:** Identify valuable customers and support relationship banking strategies.

**Analysis Includes:**
- Customer value segmentation
- Revenue contribution analysis
- Pareto (80/20) analysis
- Cross-selling opportunities
- Customer relationship recommendations

---

### 3. Customer Experience
**Objective:** Evaluate customer satisfaction and identify customers requiring proactive engagement.

**Analysis Includes:**
- High-support customers
- High-value customers with poor satisfaction
- Customer satisfaction by engagement level
- Relationship manager follow-up

---

### 4. Loan Portfolio & Credit Exposure
**Objective:** Monitor lending exposure and identify customers requiring credit review.

**Analysis Includes:**
- Loan exposure by customer segment
- Default analysis
- Inactive borrowers
- Credit review recommendations

---

### 5. Fraud & Risk Monitoring
**Objective:** Detect suspicious transaction patterns and prioritize fraud investigations.

**Analysis Includes:**
- Suspicious transaction monitoring
- Repeated risk events
- High-value customers with flagged transactions
- Fraud investigation recommendations

---

### 6. Executive Customer Action Report
**Objective:** Provide a unified customer view by combining engagement, value, customer experience, lending, and transaction risk to support business decision-making.

## 📋 Executive Customer Action Report

The final report combines all Gold Layer data marts into a unified customer view.

Each customer is evaluated across:

* Customer Engagement
* Customer Value
* Customer Experience
* Loan Portfolio
* Transaction Risk

The report generates business recommendations such as:

* Immediate Executive Review
* Relationship Manager Follow-up
* Credit Review
* Cross-Sell Loan Products
* Retention Campaign
* Routine Monitoring



# 🛠️ Technologies Used

* SQL Server
* T-SQL
* Stored Procedures
* Common Table Expressions (CTEs)
* Window Functions
* Aggregate Functions
* CASE Expressions
* Data Warehousing
* ETL Development
* Medallion Architecture

---

# 📁 Repository Structure

```text
Retail-Banking-Analytics-Platform
│
├── datasets
│   ├── customers.csv
│   ├── accounts.csv
│   ├── transactions.csv
│   ├── loans.csv
│   └── customer_service_tickets.csv
│
├── sql
│   ├── 01_database_setup.sql
│   ├── 02_bronze_layer.sql
│   ├── 03_silver_layer.sql
│   ├── 04_gold_layer.sql
│   ├── 05_business_insights.sql
│   └── 06_executive_customer_action_report.sql
│
├── dashboard
│   └── Banking_Analytics_Dashboard.xlsx
│
├── images
│   ├── architecture.png
│   ├── dashboard.png
│   └── executive_report.png
│
├── README.md
└── LICENSE
```
