/* 
	Description: This file creates the database and templates for the customer churn template.
	             The user can modify the variables in the set statements if needed. 
	Author: farhad.ghassemi@microsoft.com
*/
DECLARE @db_name varchar(255), @tb_name1 varchar(255), @tb_name2 varchar(255), @tb_name3 varchar(255), @tb_name4 varchar(255), @tb_name5 varchar(255), @tb_name6 varchar(255), @tb_name7 varchar(255)
DECLARE @create_db_template varchar(max), @create_tb_template1 varchar(max), @create_tb_template2 varchar(max), @create_tb_template3 varchar(max), @create_tb_template4 varchar(max), @create_tb_template5 varchar(max), @create_tb_template6 varchar(max), @create_tb_template7 varchar(max)
DECLARE @sql_script varchar(max)
DECLARE @ChurnPeriodVal int, @ChurnThresholdVal int

/* Internal Variables */
SET @db_name = 'Churn'
SET @tb_name1 = 'Users' 
SET @tb_name2 = 'Activities'
SET @tb_name3 = 'ChurnModelR'
SET @tb_name4 = 'ChurnModelRx'
SET @tb_name5 = 'ChurnVars'
SET @tb_name6 = 'ChurnPredictR'
SET @tb_name7 = 'ChurnPredictRx'
SET @ChurnPeriodVal = 21
SET @ChurnThresholdVal = 0

/* Set templates */
SET @create_db_template = 'create database {db_name}'
SET @create_tb_template1 = '
use {db_name}
CREATE TABLE {tb_name}
(
       UserId varchar(50) primary key,
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
       TransactionId bigint primary key,
       TransactionTime datetime,
       UserId varchar(50),
	   ItemId bigint,
	   Quantity bigint,
	   Val real,
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
INSERT INTO {tb_name} (ChurnPeriod,ChurnThreshold) values ({ChurnPeriodVal},{ChurnThresholdVal})
'

SET @create_tb_template6 = '
use {db_name}
CREATE TABLE {tb_name}
(
       UserId varchar(50), 
       Tag varchar(10),    
       Score float,
	   Auc float
)
'

SET @create_tb_template7 = '
use {db_name}
CREATE TABLE {tb_name}
(
       UserId varchar(50), 
       Tag varchar(10),    
       Score float,
	   Auc float
)
'

-- Create database
SET @sql_script = REPLACE(@create_db_template, '{db_name}', @db_name)
EXECUTE(@sql_script)

-- Create table 1
SET @sql_script = REPLACE(@create_tb_template1, '{db_name}', @db_name)
SET @sql_script = REPLACE(@sql_script, '{tb_name}', @tb_name1)
EXECUTE(@sql_script)

-- Create table 2
SET @sql_script = REPLACE(@create_tb_template2, '{db_name}', @db_name)
SET @sql_script = REPLACE(@sql_script, '{tb_name}', @tb_name2)
EXECUTE(@sql_script)

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

-- Create the table to persist the score
SET @sql_script = REPLACE(@create_tb_template6, '{db_name}', @db_name)
SET @sql_script = REPLACE(@sql_script, '{tb_name}', @tb_name6)
EXECUTE(@sql_script)

SET @sql_script = REPLACE(@create_tb_template7, '{db_name}', @db_name)
SET @sql_script = REPLACE(@sql_script, '{tb_name}', @tb_name7)
EXECUTE(@sql_script)
GO