USE master;

-- CHECK IF DATABASE EXISTS OR NOT 

IF EXISTS( SELECT 1 FROM sys.databases where name = 'BankingAnalyticsDB')
BEGIN 
	ALTER DATABASE BankingAnalyticsDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE BankingAnalyticsDB
END;

GO

-- CREATE DATABSE 

CREATE DATABASE BankingAnalyticsDB;

GO

USE BankingAnalyticsDB;
GO

-- CREATE SCHEMAS 

CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;