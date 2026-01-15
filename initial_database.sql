/*
================================
Create Database and schemas
================================
Script Purpose:
	For creating new database name 'DataAnalytics', if exist, it will drop and recreate.
	The script will setup gold table in this database: 'bronze', 'silver', and 'gold'
Warning:
	Proceed with caution as the script will drop the entire 'DataAnalytics' database if it exits.
	All data in the database will be permanently deleted.
*/

USE master;
Go

-- Drop and recreate the 'DataAnalytics' database
If EXISTS (Select 1 from sys.databases Where name = 'DataAnalytics')
Begin
	Alter DATABASE DataAnalytics SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DataAnalytics;
END;
Go

-- Create the 'DataAnalytics' database
Create Database DataAnalytics;
Go

Use DataAnalytics;
Go
/*
-- Create Schemas
Create Schema bronze;
Go

Create Schema silver;
Go

Create Schema gold;
Go
*/
