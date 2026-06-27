-- LOAD GOLD LAYER 

USE BankingAnalyticsDB;

GO

CREATE OR ALTER PROCEDURE gold.load_gold AS 
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME,@row_count INT;
    BEGIN TRY
        
        SET @batch_start_time = GETDATE();

        PRINT '=============================================================================================='
        PRINT '=========================== LOADING GOLD LAYER ==============================================='
        PRINT '=============================================================================================='

        PRINT '=============================================================================================='
        SET @start_time = GETDATE();
        PRINT 'TRUNCATING TABLE gold.customer_activity_summary';
        TRUNCATE TABLE gold.customer_activity_summary;

        PRINT 'LOADING DATA INTO gold.customer_activity_summary';

        WITH max_date AS (
            SELECT MAX(transaction_date) AS max_transaction_date
            FROM silver.transactions
        ),
        customer_summary AS (
            SELECT
                a.customer_id,
                COUNT(t.transaction_id) AS transaction_count,
                SUM(t.amount) AS total_transaction_amount,
                AVG(t.amount) AS avg_transaction_amount,
                MAX(c.join_date) as join_date,
                MIN(t.transaction_date) AS first_transaction_date,
                MAX(t.transaction_date) AS last_transaction_date,
                DATEDIFF(
                    DAY,
                    MAX(t.transaction_date),
                    m.max_transaction_date
                ) AS days_since_last_transaction
            FROM silver.accounts a
            LEFT JOIN silver.customers c 
                ON c.customer_id = a.customer_id
            LEFT JOIN silver.transactions t
                ON t.account_id = a.account_id
            CROSS JOIN max_date m
            GROUP BY
                a.customer_id,
                m.max_transaction_date 
        )
        INSERT INTO gold.customer_activity_summary (
            customer_id,
            transaction_count,
            total_transaction_amount,
            avg_transaction_amount,
            join_date,
            first_transaction_date,
            last_transaction_date,
            days_since_last_transaction,
            active_flag
        )
        SELECT
            customer_id,
            transaction_count,
            total_transaction_amount,
            avg_transaction_amount,
            join_date,
            first_transaction_date,
            last_transaction_date,
            days_since_last_transaction,
            CASE
                WHEN last_transaction_date is Null THEN 'Inactive'
                WHEN days_since_last_transaction <= 45 THEN 'Active'
                ELSE 'Inactive'
            END AS active_flag
        FROM customer_summary;
        SET @end_time = GETDATE();

        PRINT 'LOADING COMPLETED @gold.customer_activity_summary IN '+ CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR)+ ' seconds.';

        SELECT
            @row_count = COUNT(*)
        FROM gold.customer_activity_summary;

        PRINT 'Rows Loaded : ' + CAST(@row_count AS NVARCHAR);

        PRINT '----------------------------------------------------------------------------------------------';

        SET @start_time = GETDATE();

        PRINT '=============================================================================================='
        PRINT 'TRUNCATING TABLE gold.customer_value_segmentation';
        TRUNCATE TABLE gold.customer_value_segmentation;

        PRINT 'LOADING DATA INTO gold.customer_value_segmentation';

        WITH customer_balance as (
            SELECT 
                customer_id,
                SUM(current_balance) as total_balance
            FROM silver.accounts
            GROUP BY customer_id
        ),
        customer_value AS (
            SELECT
                a.customer_id,
                c.total_balance,
                COALESCE(SUM(t.amount),0) AS total_transaction_amount,
                COUNT(t.transaction_id) AS transaction_count
            FROM silver.accounts a
            LEFT JOIN silver.transactions t
                ON a.account_id = t.account_id
            JOIN customer_balance c 
            on c.customer_id = a.customer_id
            GROUP BY a.customer_id,c.total_balance
        )
        INSERT INTO gold.customer_value_segmentation (
            customer_id,
            total_transaction_amount,
            transaction_count,
            total_balance,
            customer_contribution_pct,
            customer_rank,
            value_segment
        )
        SELECT
            customer_id,
            total_transaction_amount,
            transaction_count,
            total_balance,
            CAST(total_transaction_amount * 100.0 /SUM(total_transaction_amount) OVER () AS decimal(20,2)) AS customer_contribution_pct,
            DENSE_RANK() OVER (ORDER BY total_transaction_amount DESC) AS customer_rank,
            CASE
                WHEN total_transaction_amount >= 500000 THEN 'Platinum'
                WHEN total_transaction_amount >= 200000 THEN 'Gold'
                WHEN total_transaction_amount >= 50000 THEN 'Silver'
                ELSE 'Bronze'
            END AS value_segment
        FROM customer_value;
        SET @end_time = GETDATE();

        PRINT 'LOADING COMPLETED @gold.customer_value_segmentation IN ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds.';

        SELECT
            @row_count = COUNT(*)
        FROM gold.customer_value_segmentation;

        PRINT 'Rows Loaded : ' + CAST(@row_count AS NVARCHAR);

        PRINT '----------------------------------------------------------------------------------------------';
        
        SET @start_time = GETDATE();

        PRINT '=============================================================================================='
        PRINT 'TRUNCATING TABLE gold.customer_service_summary';
        TRUNCATE TABLE gold.customer_service_summary;

        PRINT 'LOADING DATA INTO gold.customer_service_summary';

        INSERT INTO gold.customer_service_summary (
            customer_id ,
            ticket_count ,
            avg_satisfaction_score ,
            last_ticket_date,
            customer_satisfaction
        )
        select 
            customer_id,
            ticket_count,
            avg_satisfaction_score,
            last_ticket_date,
            CASE 
                WHEN avg_satisfaction_score = 5 THEN 'Excellent'
                WHEN avg_satisfaction_score >= 4 THEN 'Good'
                WHEN avg_satisfaction_score >= 3 THEN 'Average'
                WHEN avg_satisfaction_score >= 2 THEN 'Dissatisfied'
                ELSE 'Poor'
            END as customer_satisfaction
        from(
        select 
            customer_id,
            count(*) as ticket_count,
            CAST(AVG(satisfaction_score) AS decimal(5,2))  as avg_satisfaction_score,
            MAX(created_at) as last_ticket_date
        from silver.customer_service_tickets
        group by customer_id)t;

        SET @end_time = GETDATE();

        PRINT 'LOADING COMPLETED @gold.customer_service_summary IN ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds.';

        SELECT
            @row_count = COUNT(*)
        FROM gold.customer_service_summary;

        PRINT 'Rows Loaded : ' + CAST(@row_count AS NVARCHAR);

        PRINT '----------------------------------------------------------------------------------------------';

        SET @start_time = GETDATE();

        PRINT '=============================================================================================='
        PRINT 'TRUNCATING TABLE gold.customer_loan_summary';
        TRUNCATE TABLE gold.customer_loan_summary;

        PRINT 'LOADING DATA INTO gold.customer_loan_summary';


        WITH loan_details as (
        SELECT
            customer_id,
            count(loan_id) as loan_count,
            SUM(loan_amount) as total_loan_amount,
            AVG(loan_amount) as avg_loan_amount,
            MAX(loan_amount) as largest_loan_amount,
            SUM(CASE 
                WHEN loan_status = 'Active' THEN 1
                ELSE 0
            END) as active_loan_count,
            SUM(CASE 
                WHEN loan_status = 'Defaulted' THEN 1
                ELSE 0
            END) as defaulted_loan_count,
            SUM(CASE 
                WHEN loan_status = 'Closed' THEN 1
                ELSE 0
            END) as closed_loan_count
        FROM silver.loans
        GROUP BY customer_id)
        INSERT INTO gold.customer_loan_summary (
            customer_id ,
            loan_count,
            total_loan_amount,
            avg_loan_amount,
            largest_loan_amount,
            active_loan_count,
            defaulted_loan_count,
            closed_loan_count,
            is_defaulted 
        )
        SELECT 
            customer_id,
            loan_count,
            total_loan_amount,
            avg_loan_amount,
            largest_loan_amount,
            active_loan_count,
            defaulted_loan_count,
            closed_loan_count,
            CASE 
                WHEN defaulted_loan_count >=1 THEN 1 
                ELSE 0
            END AS is_defaulted
        FROM loan_details;
        SET @end_time = GETDATE();

        PRINT 'LOADING COMPLETED @gold.customer_loan_summary IN ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds.';

        SELECT
            @row_count = COUNT(*)
        FROM gold.customer_loan_summary;

        PRINT 'Rows Loaded : ' + CAST(@row_count AS NVARCHAR);

        PRINT '----------------------------------------------------------------------------------------------';
        
        SET @start_time = GETDATE();

        PRINT '=============================================================================================='
        PRINT 'TRUNCATING TABLE gold.transaction_risk_flags';
        TRUNCATE TABLE gold.transaction_risk_flags;

        PRINT 'LOADING DATA INTO gold.transaction_risk_flags';

        WITH transaction_details as (
            SELECT 
                t.transaction_id,
                a.customer_id,
                t.transaction_date,
                LAG(t.transaction_date) OVER(PARTITION BY a.customer_id ORDER BY t.transaction_date) as prev_transaction_date,
                t.amount as transaction_amount
            FROM silver.transactions t 
            JOIN silver.accounts a 
            on a.account_id = t.account_id
        ),
        final_tranx as (
        SELECT 
            transaction_id,
            customer_id,
            transaction_date,
            transaction_amount,
            DATEDIFF(DAY,prev_transaction_date,transaction_date) as days_since_last_transaction
        FROM transaction_details),
        transaction_count as (
        SELECT 
            d.transaction_id,
            d.transaction_date,
            x.transaction_count_last_hour
        FROM transaction_details d
        CROSS APPLY (
            SELECT 
              count(*) as transaction_count_last_hour  
            FROM transaction_details t
            WHERE t.customer_id = d.customer_id and t.transaction_date between DATEADD(HOUR,-1,d.transaction_date) and d.transaction_date)x
        ),
        final as (
        SELECT
            t.transaction_id,
            t.customer_id,
            t.transaction_date,
            t.transaction_amount,
            t.days_since_last_transaction,
            c.transaction_count_last_hour
        FROM final_tranx t 
        JOIN transaction_count c
        on c.transaction_id = t.transaction_id 
        )
        INSERT INTO gold.transaction_risk_flags
        (
            transaction_id,
            customer_id,
            transaction_date,
            transaction_amount,
            days_since_last_transaction,
            transaction_count_last_hour,
            risk_type,
            risk_reason
        )
        SELECT
            transaction_id,
            customer_id,
            transaction_date,
            transaction_amount,
            days_since_last_transaction,
            transaction_count_last_hour,
            CASE
                WHEN days_since_last_transaction >= 90 AND transaction_count_last_hour >= 4 THEN 'POST_INACTIVITY_TRANSACTION,TRANSACTION_BURST'
                WHEN days_since_last_transaction >= 90 THEN 'POST_INACTIVITY_TRANSACTION'
                WHEN transaction_count_last_hour >= 4 THEN 'TRANSACTION_BURST'
            END AS risk_type,
            CASE
                WHEN days_since_last_transaction >= 90 AND transaction_count_last_hour >= 4 THEN CAST(days_since_last_transaction AS VARCHAR(10)) + ' days inactive before transaction and '
                + CAST(transaction_count_last_hour AS VARCHAR(10))+ ' transactions performed within the previous rolling one-hour window.'
                WHEN days_since_last_transaction >= 90 THEN CAST(days_since_last_transaction AS VARCHAR(10)) + ' days inactive before transaction.'
                WHEN transaction_count_last_hour >= 4 THEN CAST(transaction_count_last_hour AS VARCHAR(10)) + ' transactions performed within the previous rolling one-hour window.'
            END AS risk_reason
        FROM final
        WHERE
            days_since_last_transaction >= 90
            OR transaction_count_last_hour >= 4;

        SET @end_time = GETDATE();

        PRINT 'LOADING COMPLETED @gold.transaction_risk_flags IN ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds.';

        SELECT
            @row_count = COUNT(*)
        FROM gold.transaction_risk_flags;

        PRINT 'Rows Loaded : ' + CAST(@row_count AS NVARCHAR);

        PRINT '----------------------------------------------------------------------------------------------';
        PRINT '======================================'
        PRINT 'Gold Layer Load Completed Successfully'
        PRINT '======================================'

        SET @batch_end_time = GETDATE();

        PRINT 'Total Duration : ' + CAST(DATEDIFF(SECOND,@batch_start_time,@batch_end_time) AS NVARCHAR) + ' seconds.';
    END TRY
    BEGIN CATCH 
		PRINT 'ERROR OCCURRED DURING LOADING GOLD LAYER';
		PRINT 'Error Message : ' + ERROR_MESSAGE();
		PRINT 'Error Line : ' + CAST(ERROR_LINE() AS NVARCHAR);
		PRINT 'Error Number : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Procedure : ' + ISNULL(ERROR_PROCEDURE(),'N/A');
	END CATCH
END;

GO 

EXEC gold.load_gold;


