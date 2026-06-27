-- INGESTING DATA INTO BRONZE LAYER 

CREATE OR ALTER PROCEDURE bronze.load_bronze AS 
BEGIN 
	DECLARE @start_time DATETIME, @end_time DATETIME , @batch_start_time DATETIME , @batch_end_time DATETIME,@row_count INT;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '===================================='
		PRINT 'LOADING BRONZE LAYER'
		PRINT '===================================='

		SET @start_time = GETDATE();
		PRINT 'TRUNCATING TABLE bronze.customers'
		TRUNCATE TABLE bronze.customers;
		PRINT 'INSERTING DATA INTO bronze.customers'
		BULK INSERT bronze.customers
		FROM 'D:\Banking SQL Project\dataset\customers.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0A',
			TABLOCK
		);
		PRINT 'DATA INSERTION COMPLETED'
		SET @end_time = GETDATE();
		PRINT 'LOAD DURATION : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR)+ ' seconds.'
		select 
			@row_count = count(*)
		from bronze.customers;
		PRINT 'Rows Loaded : ' + CAST(@row_count as NVARCHAR)
		PRINT '-----------------------------------------------------------'

		SET @start_time = GETDATE();
		PRINT 'TRUNCATING TABLE bronze.accounts'
		TRUNCATE TABLE bronze.accounts;
		PRINT 'INSERTING DATA INTO bronze.accounts'
		BULK INSERT bronze.accounts
		FROM 'D:\Banking SQL Project\dataset\accounts.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0A',
			TABLOCK
		);
		PRINT 'DATA INSERTION COMPLETED'
		SET @end_time = GETDATE();
		PRINT 'LOAD DURATION : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR)+ ' seconds.'
		select 
			@row_count = count(*)
		from bronze.accounts;
		PRINT 'Rows Loaded : ' + CAST(@row_count as NVARCHAR)
		PRINT '-----------------------------------------------------------'

		SET @start_time = GETDATE();
		PRINT 'TRUNCATING TABLE bronze.transactions'
		TRUNCATE TABLE bronze.transactions;
		PRINT 'INSERTING DATA INTO bronze.transactions'
		BULK INSERT bronze.transactions
		FROM 'D:\Banking SQL Project\dataset\transactions.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0A',
			TABLOCK
		);
		PRINT 'DATA INSERTION COMPLETED'
		SET @end_time = GETDATE();
		PRINT 'LOAD DURATION : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR)+ ' seconds.'
		select 
			@row_count = count(*)
		from bronze.transactions;
		PRINT 'Rows Loaded : ' + CAST(@row_count as NVARCHAR)
		PRINT '-----------------------------------------------------------'

		SET @start_time = GETDATE();
		PRINT 'TRUNCATING TABLE bronze.customer_service_tickets'
		TRUNCATE TABLE bronze.customer_service_tickets;
		PRINT 'INSERTING DATA INTO bronze.customer_service_tickets'
		BULK INSERT bronze.customer_service_tickets
		FROM 'D:\Banking SQL Project\dataset\customer_service_tickets.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0A',
			TABLOCK
		);
		PRINT 'DATA INSERTION COMPLETED'
		SET @end_time = GETDATE();
		PRINT 'LOAD DURATION : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR)+ ' seconds.'
		select 
			@row_count = count(*)
		from bronze.customer_service_tickets;
		PRINT 'Rows Loaded : ' + CAST(@row_count as NVARCHAR)
		PRINT '-----------------------------------------------------------'

		SET @start_time = GETDATE();
		PRINT 'TRUNCATING TABLE bronze.loans'
		TRUNCATE TABLE bronze.loans;
		PRINT 'INSERTING DATA INTO bronze.loans'
		BULK INSERT bronze.loans
		FROM 'D:\Banking SQL Project\dataset\loans.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0A',
			TABLOCK
		);
		PRINT 'DATA INSERTION COMPLETED'
		SET @end_time = GETDATE();
		PRINT 'LOAD DURATION : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR)+ ' seconds.'
		select 
			@row_count = count(*)
		from bronze.loans;
		PRINT 'Rows Loaded : ' + CAST(@row_count as NVARCHAR)
		PRINT '-----------------------------------------------------------'

		SET @batch_end_time = GETDATE();
		PRINT '===================================='
		PRINT 'BRONZE LOAD COMPLETED'
		PRINT '===================================='

		PRINT 'TOTAL LOAD DURATION : '+ CAST(DATEDIFF(SECOND,@batch_start_time,@batch_end_time) AS NVARCHAR) + ' seconds';
	END TRY
	BEGIN CATCH
		PRINT 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
		PRINT 'Error Message : ' + ERROR_MESSAGE();
		PRINT 'Error Line : ' + CAST(ERROR_LINE() AS NVARCHAR);
		PRINT 'Error Number : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Procedure : ' + ISNULL(ERROR_PROCEDURE(),'N/A');
	END CATCH
END;

GO 

EXEC bronze.load_bronze;





