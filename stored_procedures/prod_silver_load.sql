-- LOADING CLEAN DATA INTO SILVER LAYER

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME,@end_time DATETIME,@batch_start_time DATETIME ,@batch_end_time DATETIME, @row_count INT;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '============================================================================================='
		PRINT '==================================LOADING SILVER LAYER======================================='
		PRINT '=============================================================================================='

		PRINT '==============================================================================================='

		SET @start_time = GETDATE();
		PRINT 'TRUNCATING TABLE silver.customers'
		TRUNCATE TABLE silver.customers;
		PRINT 'LOADING CLEAN DATA INTO silver.customers'
		INSERT INTO silver.customers(
			customer_id,
			full_name,
			gender,
			date_of_birth,
			city,
			occupation,
			income_band,
			join_date
		)
		SELECT 
			customer_id,
			full_name,
			COALESCE(UPPER(LEFT(TRIM(gender),1))+TRIM(LOWER(SUBSTRING(gender,2,len(gender)))),'Unknown') as gender,
			date_of_birth,
			COALESCE(UPPER(LEFT(TRIM(city),1))+TRIM(LOWER(SUBSTRING(city,2,len(city)))),'Unknown') as city,
			COALESCE(UPPER(LEFT(TRIM(occupation),1))+TRIM(LOWER(SUBSTRING(occupation,2,len(occupation)))),'Unknown') as occupation,
			REPLACE(COALESCE(income_band,'N/A'),'-',' ') as income_band,
			join_date
		FROM bronze.customers;

		SET @end_time = GETDATE();
		PRINT 'LOADING COMPLETE @silver.customers in ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds.'
		select 
			@row_count = count(*)
		from silver.customers;
		PRINT 'Rows Loaded : ' + CAST(@row_count as NVARCHAR)
		PRINT '----------------------------------------------------------------------------------------------------------'

		SET @start_time = GETDATE();
		PRINT 'TRUNCATING TABLE silver.accounts'
		TRUNCATE TABLE silver.accounts;
		PRINT 'LOADING CLEAN DATA INTO silver.accounts'
		INSERT INTO silver.accounts(
			account_id,
			customer_id,
			account_type,
			account_status,
			open_date,
			current_balance
		)
		SELECT
			account_id,
			customer_id,
			UPPER(LEFT(TRIM(account_type),1))+TRIM(LOWER(SUBSTRING(account_type,2,len(account_type)))) AS account_type,
			UPPER(LEFT(TRIM(account_status),1))+TRIM(LOWER(SUBSTRING(account_status,2,len(account_status)))) AS account_status,
			open_date,
			current_balance
		FROM bronze.accounts;
		SET @end_time = GETDATE();
		PRINT 'LOADING COMPLETE @silver.accounts in ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds.'
		select 
			@row_count = count(*)
		from silver.accounts;
		PRINT 'Rows Loaded : ' + CAST(@row_count as NVARCHAR)
		PRINT '----------------------------------------------------------------------------------------------------------'


		SET @start_time = GETDATE();
		PRINT 'TRUNCATING TABLE silver.transactions'
		TRUNCATE TABLE silver.transactions;
		PRINT 'LOADING CLEAN DATA INTO silver.transactions'
		INSERT INTO silver.transactions(
			transaction_id,
			account_id,
			transaction_date,
			transaction_type,
			amount,
			merchant_category,
			channel,
			locations
		)
		select
			transaction_id,
			account_id,
			transaction_date,
			UPPER(TRIM(transaction_type)) AS transaction_type,
			amount,
			UPPER(LEFT(TRIM(merchant_category),1))+LOWER(TRIM(SUBSTRING(merchant_category,2,len(merchant_category)))) as merchant_category,
			UPPER(TRIM(channel)) AS channel,
			COALESCE(UPPER(LEFT(TRIM(locations),1))+TRIM(LOWER(SUBSTRING(locations,2,len(locations)))),'Unknown') as transaction_location
		from(
		select 
			*,
			ROW_NUMBER() OVER(PARTITION BY transaction_id ORDER BY transaction_date) as rn
		from bronze.transactions)t
		where rn = 1 and amount > 0 and transaction_date < GETDATE();
		SET @end_time = GETDATE();

		PRINT 'LOADING COMPLETE @silver.transactions in ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds.'
		select 
			@row_count = count(*)
		from silver.transactions;
		PRINT 'Rows Loaded : ' + CAST(@row_count as NVARCHAR)
		PRINT '---------------------------------------------------------------------------------------------------------'


		SET @start_time = GETDATE();
		PRINT 'TRUNCATING TABLE silver.customer_service_tickets'
		TRUNCATE TABLE silver.customer_service_tickets;
		PRINT 'LOADING CLEAN DATA INTO silver.customer_service_tickets'
		INSERT INTO silver.customer_service_tickets(
			ticket_id,
			customer_id,
			issue_type,
			created_at,
			resolved_at,
			satisfaction_score
		)
		select 
			ticket_id,
			customer_id,
			TRIM(issue_type) AS issue_type,
			created_at,
			resolved_at,
			COALESCE(satisfaction_score,0) as satisfaction_score
		from bronze.customer_service_tickets
		where resolved_at >= created_at;
		SET @end_time = GETDATE();

		PRINT 'LOADING COMPLETE @silver.customer_service_tickets in ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds.'
		select 
			@row_count = count(*)
		from silver.customer_service_tickets;
		PRINT 'Rows Loaded : ' + CAST(@row_count as NVARCHAR)
		PRINT '--------------------------------------------------------------------------------------------------------------'

		SET @start_time = GETDATE();
		PRINT 'TRUNCATING TABLE silver.loans'
		TRUNCATE TABLE silver.loans;
		PRINT 'LOADING CLEAN DATA INTO silver.loans'
		INSERT INTO silver.loans(
			loan_id,
			customer_id,
			loan_type,
			loan_amount,
			interest_rate,
			loan_status
		)
		select 
			loan_id,
			customer_id,
			loan_type,
			loan_amount,
			interest_rate,
			UPPER(LEFT(loan_status,1))+TRIM(SUBSTRING(loan_status,2,len(loan_status))) AS loan_status
		from bronze.loans
		SET @end_time = GETDATE();
		PRINT 'LOADING COMPLETE @silver.loans in ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds.'
		select 
			@row_count = count(*)
		from silver.loans;
		PRINT 'Rows Loaded : ' + CAST(@row_count as NVARCHAR)
		PRINT '--------------------------------------------------------------------------------------------------------------'

		PRINT '=========================================================================='
		PRINT '=======================SILVER LAYER LOAD COMPLETED========================='
		PRINT '==========================================================================='
		SET @batch_end_time = GETDATE();
		PRINT 'TOTAL LOAD DURATION : ' + CAST(DATEDIFF(SECOND,@batch_start_time,@batch_end_time) as NVARCHAR) + ' seconds.'
	END TRY
	BEGIN CATCH 
		PRINT 'ERROR OCCURRED DURING LOADING SILVER LAYER';
		PRINT 'Error Message : ' + ERROR_MESSAGE();
		PRINT 'Error Line : ' + CAST(ERROR_LINE() AS NVARCHAR);
		PRINT 'Error Number : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Procedure : ' + ISNULL(ERROR_PROCEDURE(),'N/A');
	END CATCH
END;

GO 

EXEC silver.load_silver;



