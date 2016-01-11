/* 
	Description: This file creates the database and templates for the customer churn template.
	             The user can modify the variables in the set statements if needed. 
	Author: farhad.ghassemi@microsoft.com
	Date: Jan 2016
*/
DECLARE @db_name varchar(255), @tb_name1 varchar(255), @path_to_data1 varchar(255), @tb_name2 varchar(255), @path_to_data2 varchar(255), @tb_name3 varchar(255), @tb_name4 varchar(255), @tb_name5 varchar(255)
DECLARE @create_db_template varchar(max), @create_tb_template1 varchar(max), @create_tb_template2 varchar(max), @create_tb_template3 varchar(max), @create_tb_template4 varchar(max), @create_tb_template5 varchar(max), @upload_data_template1 varchar(max), @upload_data_template2 varchar(max)
DECLARE @sql_script varchar(max)
DECLARE @ChurnPeriodVal int, @ChurnThresholdVal int
/* User defined variables */
SET @db_name = 'Churn'
SET @tb_name1 = 'Profiles' 
SET @path_to_data1= 'C:\ChurnData\Profiles.csv' --Please change the path to the data file based on where it is in your SQL Server
SET @tb_name2 = 'Transactions'
SET @tb_name3 = 'ChurnModelR'
SET @tb_name4 = 'ChurnModelRx'
SET @tb_name5 = 'ChurnVars'
SET @ChurnPeriodVal = 21
SET @ChurnThresholdVal = 0
SET @path_to_data2= 'C:\ChurnData\Transactions.csv' --Please change the path to the data file based on where it is in your SQL Server
/* User defined variables */
SET @create_db_template = 'create database {db_name}'
SET @create_tb_template1 = '
use {db_name}
CREATE TABLE {tb_name}
(
       UserId varchar(50),
       Age varchar(50),
       Address varchar(50),
       Gender varchar(50),
       UserType varchar(50)
)
'

SET @create_tb_template2 = '
use {db_name}
CREATE TABLE {tb_name}
(
       [Column 0] bigint,
       TransactionId bigint,
       Timestamp datetime,
       UserId bigint,
	   ItemId bigint,
	   Quantity bigint,
	   Value real,
	   Location varchar(50),
       ProductCategory varchar(50)
)
'

SET @create_tb_template3 = '
use {db_name}
CREATE TABLE {tb_name}
(
	model varbinary(max) not null
)
'

SET @create_tb_template4 = '
use {db_name}
CREATE TABLE {tb_name}
(
	model varbinary(max) not null
)
'

SET @create_tb_template5 = '
use {db_name}
CREATE TABLE {tb_name}
(
	ChurnPeriod int,
	ChurnThreshold int
)
INSERt INTO {tb_name} (ChurnPeriod,ChurnThreshold) values ({ChurnPeriodVal},{ChurnThresholdVal})
'

SET @upload_data_template1 = 'BULK INSERT {db_name}.dbo.{tb_name} 
   	FROM ''{path_to_data}''
   	WITH ( FIELDTERMINATOR ='','', FIRSTROW = 2, ROWTERMINATOR = ''\n'' )
'

SET @upload_data_template2 = 'BULK INSERT {db_name}.dbo.{tb_name} 
   	FROM ''{path_to_data}''
   	WITH ( FIELDTERMINATOR ='','', FIRSTROW = 2, ROWTERMINATOR = ''\n'' )
'

-- Create database
SET @sql_script = REPLACE(@create_db_template, '{db_name}', @db_name)
EXECUTE(@sql_script)

-- Create table 1
SET @sql_script = REPLACE(@create_tb_template1, '{db_name}', @db_name)
SET @sql_script = REPLACE(@sql_script, '{tb_name}', @tb_name1)
EXECUTE(@sql_script)

-- Upload data from a local file on the server to the table 1
SET @sql_script = REPLACE(@upload_data_template1, '{db_name}', @db_name)
SET @sql_script = REPLACE(@sql_script, '{tb_name}', @tb_name1)
SET @sql_script = REPLACE(@sql_script, '{path_to_data}', @path_to_data1)
EXECUTE(@sql_script)

-- Create table 2
SET @sql_script = REPLACE(@create_tb_template2, '{db_name}', @db_name)
SET @sql_script = REPLACE(@sql_script, '{tb_name}', @tb_name2)
--EXECUTE(@sql_script)

-- Upload data from a local file on the server to the table 2
SET @sql_script = REPLACE(@upload_data_template2, '{db_name}', @db_name)
SET @sql_script = REPLACE(@sql_script, '{tb_name}', @tb_name2)
SET @sql_script = REPLACE(@sql_script, '{path_to_data}', @path_to_data2)
--EXECUTE(@sql_script)

-- Create the table to persist the trained models
SET @sql_script = REPLACE(@create_tb_template3, '{db_name}', @db_name)
SET @sql_script = REPLACE(@sql_script, '{tb_name}', @tb_name3)
EXECUTE(@sql_script)

SET @sql_script = REPLACE(@create_tb_template4, '{db_name}', @db_name)
SET @sql_script = REPLACE(@sql_script, '{tb_name}', @tb_name4)
EXECUTE(@sql_script)

-- Create table 5
SET @sql_script = REPLACE(@create_tb_template5, '{db_name}', @db_name)
SET @sql_script = REPLACE(@sql_script, '{tb_name}', @tb_name5)
SET @sql_script = REPLACE(@sql_script, '{ChurnPeriodVal}', @ChurnPeriodVal)
SET @sql_script = REPLACE(@sql_script, '{ChurnThresholdVal}', @ChurnThresholdVal)
EXECUTE(@sql_script)

GO