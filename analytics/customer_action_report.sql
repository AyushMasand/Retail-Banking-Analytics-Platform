
----------------------------------------------------------
-- EXECUTIVE CUSTOMER ACTION REPORT
----------------------------------------------------------

/*
Objective:
Provide management with a unified customer view by
combining customer engagement, customer value,
customer experience, loan portfolio, and transaction
risk to identify customers requiring immediate action.
*/

WITH risk_summary AS (
    SELECT
        customer_id,
        COUNT(transaction_id) AS flagged_transactions,
        SUM(transaction_amount) AS suspicious_transaction_amount,
        STRING_AGG(risk_type, ', ') AS risk_types
    FROM gold.transaction_risk_flags
    GROUP BY customer_id
)

SELECT
    a.customer_id,
    a.active_flag,
    a.days_since_last_transaction,
    v.value_segment,
    v.total_balance,
    v.total_transaction_amount,
    COALESCE(s.ticket_count,0) AS ticket_count,
    s.customer_satisfaction,
    CASE
        WHEN COALESCE(l.active_loan_count,0) > 0 THEN 'Yes'
        ELSE 'No'
    END AS active_loan,
    CASE
        WHEN COALESCE(l.defaulted_loan_count,0) > 0 THEN 'Yes'
        ELSE 'No'
    END AS default_history,
    COALESCE(l.total_loan_amount,0) AS total_loan_amount,
    CASE
        WHEN COALESCE(r.flagged_transactions,0) > 0 THEN 'Yes'
        ELSE 'No'
    END AS flagged_transactions,
    COALESCE(r.flagged_transactions,0) AS total_flagged_transactions,
    COALESCE(r.suspicious_transaction_amount,0) AS suspicious_transaction_amount,
    COALESCE(r.risk_types,'None') AS risk_types,
    CASE
        WHEN COALESCE(r.flagged_transactions,0) > 0 AND COALESCE(l.defaulted_loan_count,0) > 0 AND a.active_flag='Inactive'
        THEN 'Immediate Executive Review'
        WHEN s.customer_satisfaction IN ('Poor','Dissatisfied') AND a.active_flag='Inactive' AND v.value_segment IN ('Platinum','Gold')
        THEN 'Relationship Manager Follow-up'
        WHEN COALESCE(l.active_loan_count,0) = 0 AND v.total_balance > ( SELECT AVG(total_balance) FROM gold.customer_value_segmentation)
        THEN 'Cross-Sell Loan Products'
        WHEN v.total_transaction_amount > (SELECT AVG(total_transaction_amount) FROM gold.customer_value_segmentation)
        AND v.total_balance < (SELECT AVG(total_balance) FROM gold.customer_value_segmentation)
        THEN 'Promote Savings Products'
        WHEN a.active_flag = 'Inactive' THEN 'Retention Campaign'
        ELSE 'Routine Monitoring'
    END AS recommended_action
FROM gold.customer_activity_summary a
LEFT JOIN gold.customer_value_segmentation v
ON a.customer_id=v.customer_id
LEFT JOIN gold.customer_service_summary s
ON a.customer_id=s.customer_id
LEFT JOIN gold.customer_loan_summary l
ON a.customer_id=l.customer_id
LEFT JOIN risk_summary r
ON a.customer_id=r.customer_id

