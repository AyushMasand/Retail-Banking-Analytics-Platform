USE BankingAnalyticsDB;

/*==========================================================
Business Problem 1 : Customer Engagement & Retention

Objective:
Understand customer engagement, identify inactive
customers, and discover retention opportunities.

Business Questions:
1. Active vs inactive customers
2. Longest inactive customers
3. High-balance inactive customers
4. Customers with no transactions
5. Inactive customers with active loans
6. Engagement by customer value segment
==========================================================*/

-- 1. WHAT PERCENTAGE OF CUSTOMERS ARE ACTIVE AND INACTIVE ?

SELECT
    active_flag,
    COUNT(*) AS customers,
    CAST(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()
        AS DECIMAL(10,2)
    ) AS pct
FROM gold.customer_activity_summary
GROUP BY active_flag

-- 2. Which Customers have been inactive for the longest period?

SELECT 
	c.customer_id,
	c.days_since_last_transaction,
	v.total_balance as bank_balnce
FROM gold.customer_activity_summary c
JOIN gold.customer_value_segmentation v 
ON v.customer_id = c.customer_id
WHERE active_flag = 'Inactive' 

-- 3. Which inactive customers still maintain significant balances?

SELECT 
	c.customer_id,
	c.days_since_last_transaction,
	v.total_balance as bank_balnce,
	v.value_segment
FROM gold.customer_activity_summary c
JOIN gold.customer_value_segmentation v 
ON v.customer_id = c.customer_id
WHERE active_flag = 'Inactive' and v.total_balance > 100000

-- 4. Which customers opened an account but never transacted?

SELECT 
	c.customer_id,
	c.join_date,
	v.total_balance as balance
FROM gold.customer_activity_summary c
LEFT JOIN gold.customer_value_segmentation v 
ON c.customer_id = v.customer_id
where c.first_transaction_date is Null and c.last_transaction_date is Null

-- 5. Which inactive customers still have loans?

SELECT 
	c.customer_id,
	l.active_loan_count as active_loan,
	c.days_since_last_transaction as days_inactive
FROM gold.customer_activity_summary c 
JOIN gold.customer_loan_summary l
on c.customer_id = l.customer_id
where c.active_flag = 'Inactive' and l.active_loan_count > 0

-- 6. Does engagement differs accross value segments?
WITH segment_details as (
SELECT 
	v.value_segment,
	COUNT(CASE 
		WHEN c.active_flag = 'Active' THEN c.customer_id
	END) as active,
	COUNT(CASE 
		WHEN c.active_flag = 'Inactive' THEN c.customer_id
	END) as inactive
FROM gold.customer_activity_summary c
LEFT JOIN gold.customer_value_segmentation v 
ON c.customer_id = v.customer_id
GROUP BY v.value_segment)

SELECT 
	*,
	CAST(active * 100.0 / (active + inactive) AS decimal(10,2)) as	active_pct
FROM segment_details


USE BankingAnalyticsDB;

----------------------------------------------------------
-- BUSINESS PROBLEM 2 : CUSTOMER VALUE & RELATIONSHIP BANKING
----------------------------------------------------------

/*
Objective:
Identify the bank's most valuable customers, understand
revenue concentration, and discover opportunities to
improve customer value.
*/

----------------------------------------------------------
-- 1. How are customers distributed across value segments?
----------------------------------------------------------

SELECT
    value_segment,
    COUNT(*) AS total_customers,
    CAST(COUNT(*) * 100.0 /SUM(COUNT(*)) OVER () AS DECIMAL(10,2)) AS customer_percentage
FROM gold.customer_value_segmentation
GROUP BY value_segment;

----------------------------------------------------------
-- 2. How much transaction value is contributed by each
--    customer segment?
----------------------------------------------------------

SELECT
    value_segment,
    SUM(total_transaction_amount) AS segment_transaction_amount,
    CAST(SUM(total_transaction_amount) * 100.0 /SUM(SUM(total_transaction_amount)) OVER () AS DECIMAL(10,2)) AS contribution_percentage
FROM gold.customer_value_segmentation
GROUP BY value_segment
ORDER BY total_transaction_amount DESC;

----------------------------------------------------------
-- 3. Does the bank follow the Pareto (80/20) Principle?
----------------------------------------------------------

WITH customer_contribution AS
(
    SELECT
        customer_rank,
        customer_id,
        value_segment,
        total_transaction_amount,
        SUM(total_transaction_amount) OVER(ORDER BY total_transaction_amount DESC) AS running_transaction_amount
    FROM gold.customer_value_segmentation
)

SELECT
    customer_rank,
    customer_id,
    value_segment,
    total_transaction_amount,
    CAST(running_transaction_amount * 100.0 /SUM(total_transaction_amount) OVER () AS DECIMAL(10,2)) AS cumulative_contribution_percentage
FROM customer_contribution
ORDER BY customer_rank;




----------------------------------------------------------
-- 4. Which highly engaged customers maintain below average account balances?
----------------------------------------------------------
SELECT
    customer_id,
    value_segment,
    total_balance,
    total_transaction_amount,
    transaction_count
FROM gold.customer_value_segmentation
WHERE total_balance < (SELECT AVG(total_balance) FROM gold.customer_value_segmentation)
    AND
    total_transaction_amount > (SELECT AVG(total_transaction_amount) FROM gold.customer_value_segmentation)
ORDER BY total_balance DESC;


----------------------------------------------------------
-- 5. Which customers have high balances but no loans?
----------------------------------------------------------

SELECT 
    v.customer_id,
    v.total_balance,
    v.value_segment
FROM gold.customer_value_segmentation v 
JOIN gold.customer_loan_summary l
ON v.customer_id = l.customer_id
WHERE v.total_balance > (SELECT AVG(total_balance) FROM gold.customer_value_segmentation)
    AND 
    l.active_loan_count = 0


----------------------------------------------------------
-- 6. Which customers should be prioritized for banking
--    relationship strategies?
----------------------------------------------------------

SELECT
    customer_id,
    value_segment,
    total_transaction_amount,
    total_balance,
    CASE
        WHEN total_balance > (SELECT AVG(total_balance) FROM gold.customer_value_segmentation)
        AND total_transaction_amount > (SELECT AVG(total_transaction_amount) FROM gold.customer_value_segmentation)
        THEN 'Priority Banking'
        WHEN total_balance > (SELECT AVG(total_balance) FROM gold.customer_value_segmentation)
        AND total_transaction_amount < (SELECT AVG(total_transaction_amount) FROM gold.customer_value_segmentation)
        THEN 'Cross Sell Investment Products'
        WHEN total_balance < (SELECT AVG(total_balance) FROM gold.customer_value_segmentation)
        AND total_transaction_amount > (SELECT AVG(total_transaction_amount) FROM gold.customer_value_segmentation)
        THEN 'Promote Savings & Deposit Products'
        ELSE 'Customer Retention Campaign'
    END AS recommendation
FROM gold.customer_value_segmentation;

----------------------------------------------------------
-- 7. Are Platinum customers actually spending more than Bronze customers?
----------------------------------------------------------

SELECT
    value_segment,
    AVG(total_transaction_amount) as avg_transaction,
    AVG(total_balance) as avg_balance
FROM gold.customer_value_segmentation
GROUP BY value_segment
ORDER BY 2 desc,3 desc

```sql
----------------------------------------------------------
-- BUSINESS PROBLEM 3 : CUSTOMER EXPERIENCE & CHURN RISK
----------------------------------------------------------

/*
Objective:
Evaluate customer satisfaction, identify customers
requiring proactive support, and detect customers
at risk of disengagement based on their service experience.
*/

---------------------------------------------------------- 
-- 1. What is the overall customer satisfaction score?
---------------------------------------------------------- 
SELECT 
    CAST(CAST(AVG(avg_satisfaction_score) AS DECIMAL(5,2)) AS nvarchar) + ' out of 5' AS average_customer_satisfaction 
FROM gold.customer_service_summary;


----------------------------------------------------------
-- 2. Which customers have raised an unusually high
--    number of service tickets?
----------------------------------------------------------

SELECT
    customer_id,
    ticket_count,
    avg_satisfaction_score,
    last_ticket_date
FROM gold.customer_service_summary
WHERE ticket_count >(SELECT AVG(ticket_count) FROM gold.customer_service_summary)
ORDER BY ticket_count DESC;


----------------------------------------------------------
-- 3. Which high-value customers have poor customer
--    satisfaction?
----------------------------------------------------------

SELECT
    v.customer_id,
    v.value_segment,
    v.total_balance,
    v.total_transaction_amount,
    s.ticket_count,
    s.avg_satisfaction_score
FROM gold.customer_value_segmentation v
JOIN gold.customer_service_summary s
ON v.customer_id = s.customer_id
WHERE (v.total_balance > (SELECT AVG(total_balance) FROM gold.customer_value_segmentation)
OR v.total_transaction_amount > (SELECT AVG(total_transaction_amount) FROM gold.customer_value_segmentation))
AND s.avg_satisfaction_score < 3
ORDER BY s.avg_satisfaction_score,v.total_transaction_amount DESC;


----------------------------------------------------------
-- 4. Does customer satisfaction differ between
--    active and inactive customers?
----------------------------------------------------------

SELECT
    a.active_flag,
    COUNT(*) AS total_customers,
    CAST(AVG(s.avg_satisfaction_score) AS DECIMAL(5,2)) AS average_satisfaction
FROM gold.customer_activity_summary a
JOIN gold.customer_service_summary s
    ON a.customer_id = s.customer_id
GROUP BY a.active_flag;


----------------------------------------------------------
-- 5. Which customers require immediate follow-up?
----------------------------------------------------------

SELECT
    a.customer_id,
    v.value_segment,
    s.ticket_count,
    s.avg_satisfaction_score,
    a.active_flag,
    v.total_balance,
    v.total_transaction_amount,
    'Immediate Relationship Manager Follow-up' AS recommendation
FROM gold.customer_activity_summary a
JOIN gold.customer_service_summary s
ON a.customer_id = s.customer_id
JOIN gold.customer_value_segmentation v
ON a.customer_id = v.customer_id
WHERE a.active_flag = 'Inactive'
AND s.avg_satisfaction_score < 3
AND s.ticket_count > (SELECT AVG(ticket_count) FROM gold.customer_service_summary)
AND (v.total_balance > (SELECT AVG(total_balance) FROM gold.customer_value_segmentation)
OR v.total_transaction_amount > (SELECT AVG(total_transaction_amount) FROM gold.customer_value_segmentation))
ORDER BY
    s.avg_satisfaction_score,
    s.ticket_count DESC;



----------------------------------------------------------
-- BUSINESS PROBLEM 4 : LOAN PORTFOLIO & CREDIT EXPOSURE
----------------------------------------------------------

/*
Objective:
Analyze the bank's loan portfolio to understand credit
exposure, identify high-risk borrowers, and discover
opportunities for loan portfolio management.
*/

----------------------------------------------------------
-- 1. Which customer segments hold the highest loan exposure?
----------------------------------------------------------

SELECT 
    value_segment,
    CASE 
        WHEN total_loan_exposure >= 1000000000 THEN '$' +CAST(CAST(total_loan_exposure / 1000000000.0  AS decimal(10,2)) AS nvarchar) + 'B'
        WHEN total_loan_exposure >= 1000000 THEN '$' +CAST(CAST(total_loan_exposure / 1000000.0  AS decimal(10,2)) AS nvarchar) + 'M'
        WHEN total_loan_exposure >= 1000 THEN '$' +CAST(CAST(total_loan_exposure / 1000.0 AS decimal(10,2)) AS nvarchar) + 'K'
        ELSE '$' + CAST(CAST(total_loan_exposure AS decimal(10,2)) AS nvarchar)
    END as loan_exposure,
    CASE 
        WHEN average_loan_amount >= 1000000000 THEN '$' +CAST(CAST(average_loan_amount / 1000000000.0  AS decimal(10,2)) AS nvarchar) + 'B'
        WHEN average_loan_amount >= 1000000 THEN '$' +CAST(CAST(average_loan_amount / 1000000.0  AS decimal(10,2)) AS nvarchar) + 'M'
        WHEN average_loan_amount >= 1000 THEN '$' +CAST(CAST(average_loan_amount / 1000.0 AS decimal(10,2)) AS nvarchar) + 'K'
        ELSE '$' + CAST(CAST(average_loan_amount AS decimal(10,2)) AS nvarchar)
    END as avg_loan_amount,
    total_borrowers
FROM(
SELECT
    v.value_segment,
    SUM(l.total_loan_amount) AS total_loan_exposure,
    AVG(l.total_loan_amount) AS average_loan_amount,
    COUNT(l.customer_id) AS total_borrowers
FROM gold.customer_loan_summary l
JOIN gold.customer_value_segmentation v
    ON l.customer_id = v.customer_id
GROUP BY v.value_segment)T



----------------------------------------------------------
-- 2. Which high-value customers have defaulted on their loans?
----------------------------------------------------------

SELECT
    v.customer_id,
    v.value_segment,
    v.total_transaction_amount,
    v.total_balance,
    l.total_loan_amount,
    l.defaulted_loan_count
FROM gold.customer_value_segmentation v
JOIN gold.customer_loan_summary l
    ON v.customer_id = l.customer_id
WHERE (v.total_transaction_amount > (SELECT AVG(total_transaction_amount) FROM gold.customer_value_segmentation)
OR v.total_balance > (SELECT AVG(total_balance) FROM gold.customer_value_segmentation))
AND l.is_defaulted = 1
ORDER BY l.total_loan_amount DESC;


----------------------------------------------------------
-- 3. Which inactive customers still have active loans?
----------------------------------------------------------

SELECT
    a.customer_id,
    a.days_since_last_transaction,
    l.active_loan_count,
    l.total_loan_amount
FROM gold.customer_activity_summary a
JOIN gold.customer_loan_summary l
    ON a.customer_id = l.customer_id
WHERE a.active_flag = 'Inactive' AND l.active_loan_count > 0
ORDER BY l.total_loan_amount DESC;


----------------------------------------------------------
-- 4. Which customers have the highest outstanding loan exposure?
----------------------------------------------------------

SELECT
    customer_id,
    loan_count,
    active_loan_count,
    total_loan_amount,
    largest_loan_amount
FROM gold.customer_loan_summary
WHERE total_loan_amount > (SELECT AVG(total_loan_amount) FROM gold.customer_loan_summary)
ORDER BY total_loan_amount DESC;


----------------------------------------------------------
-- 5. Which high-value customers have never taken a loan?
----------------------------------------------------------

SELECT
    v.customer_id,
    v.value_segment,
    v.total_balance,
    v.total_transaction_amount
FROM gold.customer_value_segmentation v
LEFT JOIN gold.customer_loan_summary l
ON v.customer_id = l.customer_id
WHERE (v.total_transaction_amount > (SELECT AVG(total_transaction_amount) FROM gold.customer_value_segmentation)
OR v.total_balance > (SELECT AVG(total_balance) FROM gold.customer_value_segmentation))
AND (l.customer_id IS NULL OR l.loan_count = 0)
ORDER BY v.total_balance DESC;


----------------------------------------------------------
-- 6. Which customers should be prioritized for credit review?
----------------------------------------------------------

SELECT
    a.customer_id,
    v.value_segment,
    l.total_loan_amount,
    l.active_loan_count,
    l.defaulted_loan_count,
    a.active_flag,
    CASE 
        WHEN l.is_defaulted = 1 AND l.active_loan_count > (SELECT AVG(active_loan_count) FROM gold.customer_loan_summary)
        AND a.active_flag = 'Inactive'
        THEN 'Immediate Credit Review'
        WHEN l.is_defaulted = 1 THEN 'Monitor Loan Account'
        WHEN l.total_loan_amount > (SELECT AVG(total_loan_amount) FROM gold.customer_loan_summary)
        THEN 'Periodic Credit Review'
        ELSE 'Low Credit Risk'
    END AS recommendation
FROM gold.customer_loan_summary l
JOIN gold.customer_activity_summary a
ON l.customer_id = a.customer_id
JOIN gold.customer_value_segmentation v
ON l.customer_id = v.customer_id
ORDER BY l.total_loan_amount DESC;


```sql
----------------------------------------------------------
-- BUSINESS PROBLEM 5 : FRAUD & RISK MONITORING
----------------------------------------------------------

/*
Objective:
Identify suspicious customer transactions, prioritize
fraud investigations, and monitor customers that pose
potential financial and credit risk.
*/

----------------------------------------------------------
-- 1. Fraud Monitoring KPI
-- How many suspicious transactions were detected and
-- what percentage of all transactions were flagged?
----------------------------------------------------------

SELECT
    COUNT(*) AS total_flagged_transactions,
    SUM(transaction_amount) AS total_suspicious_amount,
    CAST(AVG(transaction_amount) AS DECIMAL(18,2)) AS average_suspicious_transaction,
    CAST(COUNT(*) * 100.0 /(SELECT COUNT(*) FROM silver.transactions) AS DECIMAL(10,2)) AS transaction_flag_rate
FROM gold.transaction_risk_flags;


----------------------------------------------------------
-- 2. Which customers triggered multiple suspicious
--    transactions?
----------------------------------------------------------

SELECT
    customer_id,
    COUNT(transaction_id) AS flagged_transactions,
    SUM(transaction_amount) AS suspicious_transaction_amount
FROM gold.transaction_risk_flags
GROUP BY customer_id
HAVING COUNT(transaction_id) > 1
ORDER BY suspicious_transaction_amount DESC;


----------------------------------------------------------
-- 3. Which high-value customers generated suspicious
--    transactions?
----------------------------------------------------------

SELECT
    r.customer_id,
    v.value_segment,
    COUNT(r.transaction_id) AS flagged_transactions,
    SUM(r.transaction_amount) AS suspicious_transaction_amount,
    v.total_balance,
    v.total_transaction_amount
FROM gold.transaction_risk_flags r
JOIN gold.customer_value_segmentation v
ON r.customer_id = v.customer_id
WHERE v.total_transaction_amount > ( SELECT AVG(total_transaction_amount) FROM gold.customer_value_segmentation)
OR v.total_balance > ( SELECT AVG(total_balance) FROM gold.customer_value_segmentation)
GROUP BY
    r.customer_id,
    v.value_segment,
    v.total_balance,
    v.total_transaction_amount
ORDER BY suspicious_transaction_amount DESC;

----------------------------------------------------------
-- 4. Which customers represent the highest financial
--    risk exposure?
----------------------------------------------------------

SELECT
    r.customer_id,
    COUNT(r.transaction_id) AS flagged_transactions,
    SUM(r.transaction_amount) AS suspicious_transaction_amount,
    l.total_loan_amount,
    l.active_loan_count
FROM gold.transaction_risk_flags r
JOIN gold.customer_loan_summary l
ON r.customer_id = l.customer_id
WHERE l.active_loan_count > 0
GROUP BY
    r.customer_id,
    l.total_loan_amount,
    l.active_loan_count
ORDER BY suspicious_transaction_amount DESC,l.total_loan_amount DESC;


----------------------------------------------------------
-- 5. Executive Fraud Investigation Watchlist
----------------------------------------------------------

SELECT
    r.customer_id,
    v.value_segment,
    a.active_flag,
    l.total_loan_amount,
    l.defaulted_loan_count,
    COUNT(r.transaction_id) AS flagged_transactions,
    SUM(r.transaction_amount) AS suspicious_transaction_amount,
    CASE
        WHEN a.active_flag='Inactive' AND l.is_defaulted=1 AND l.active_loan_count > 0 THEN 'Immediate Fraud Investigation'
        WHEN l.active_loan_count > 0 THEN 'Fraud & Credit Review'
        WHEN l.is_defaulted=1 THEN 'Credit Risk Monitoring'
        ELSE 'Routine Fraud Monitoring'
    END AS recommendation
FROM gold.transaction_risk_flags r
JOIN gold.customer_activity_summary a
ON r.customer_id=a.customer_id
JOIN gold.customer_value_segmentation v
ON r.customer_id=v.customer_id
JOIN gold.customer_loan_summary l
ON r.customer_id=l.customer_id
GROUP BY r.customer_id,
v.value_segment,
a.active_flag,
l.total_loan_amount,
l.active_loan_count,
l.defaulted_loan_count,
l.is_defaulted
ORDER BY suspicious_transaction_amount DESC;

