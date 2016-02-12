/* 
	Description: This file creates the database and tables for the customer churn template.
    Notes:       The following entities in this file are replaced with their values when this file is parsed by the PowerShell script:
				 ChurnMSRTemplate
				 ChurnPeriodVal
				 ChurnThresholdVal
	Author: farhad.ghassemi@microsoft.com
*/

create database ChurnMSRTemplate
go

use [ChurnMSRTemplate]
create table Users
(
       UserId varchar(50) primary key,
       Age varchar(50),
       Address varchar(50),
       Gender varchar(50),
       UserType varchar(50)
)

create table Activities
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

create table ChurnModelR
(
	model varbinary(max) not null
)

create table ChurnModelRx
(
	model varbinary(max) not null
)

create table ChurnVars
(
	ChurnPeriod int,
	ChurnThreshold int
)
insert into ChurnVars (ChurnPeriod,ChurnThreshold) values (ChurnPeriodVal,ChurnThresholdVal)

create table ChurnPredictR
(
       UserId varchar(50), 
       Tag varchar(10),    
       Score float,
	   Auc float
)

create table ChurnPredictRx
(
       UserId varchar(50), 
       Tag varchar(10),    
       Score float,
	   Auc float
)
go