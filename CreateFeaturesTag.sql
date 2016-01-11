/* 
	Description: This file creates the features and tag for the customer churn template.
	Author: farhad.ghassemi@microsoft.com
	Date: Jan 2016
*/

use [Churn]
go

set ansi_nulls on
go

set quoted_identifier on
go

if EXISTS (select * from sys.objects where type = 'P' AND name = 'CreateFeaturesTag')
  drop procedure CreateFeaturesTag
go

create procedure [dbo].[CreateFeaturesTag]
as
begin
	-- Dedupe
	select distinct * into #ActivitiesDedupe from Activities
	select distinct * into #ProfilesDedupe from Profiles

	-- Calculate overall purchased items by each customer
	select UserId, count(TransactionId) as OverallProductsPurchased into #OverallActivities from #ActivitiesDedupe group by UserId

	-- Calculate previous transaction time of a customer
	select UserId, TransactionId, LagTimestamp = lag(Timestamp) over (partition by UserId order by Timestamp) into #LagTimestamp from #ActivitiesDedupe
	alter table #ActivitiesDedupe add TransactionInterval real
	update #ActivitiesDedupe 
		set #ActivitiesDedupe.TransactionInterval = isnull(datediff(day, #LagTimestamp.LagTimestamp,  #ActivitiesDedupe.Timestamp),0)
		from #ActivitiesDedupe 
		inner join #LagTimestamp
		on #ActivitiesDedupe.UserId = #LagTimestamp.UserId and #ActivitiesDedupe.TransactionId = #LagTimestamp.TransactionId

	-- Feature engineering in pre churn period
	select UserId, count(TransactionId) as PrechurnProductsPurchased, 
				   sum(Quantity) as TotalQuantity, 
				   sum(Value) as TotalValue, 
				   isnull(stdev(Quantity),0) as StDevQuantity, 
				   isnull(stdev(Value),0) as StDevValue,
				   avg(TransactionInterval) as AvgTimeDelta,
				   datediff(day,max(Timestamp),(select max(Timestamp) from #ActivitiesDedupe))-(select ChurnPeriod from ChurnVars)  as Recency,
				   count(distinct(TransactionId)) as UniqueTransactionId,
				   count(distinct(ItemId)) as UniqueItemId,
				   count(distinct(Location)) as UniqueLocation,
				   count(distinct(ProductCategory)) as UniqueProductCategory
			into FeaturesTag
			from  #ActivitiesDedupe
			where Timestamp<=dateAdd(day, -1*(select ChurnPeriod from ChurnVars), (select max(Timestamp) from  #ActivitiesDedupe)) 
			group by UserId

	alter table FeaturesTag 
	add TotalQuantityperUniqueTransactionId real,
		TotalQuantityperUniqueItemId real,
		TotalQuantityperUniqueLocation real,
		TotalQuantityperUniqueProductCategory real,
		TotalValueperUniqueTransactionId real,
		TotalValueperUniqueItemId real,
		TotalValueperUniqueLocation real,
		TotalValueperUniqueProductCategory real
	-- '+1' is added to follow the Azure ML template. Not sure if it is necessary.
	update FeaturesTag
		set FeaturesTag.TotalQuantityperUniqueTransactionId = cast(TotalQuantity as float)/(UniqueTransactionId+1),
			FeaturesTag.TotalQuantityperUniqueItemId = cast(TotalQuantity as float)/(UniqueItemId+1),
			FeaturesTag.TotalQuantityperUniqueLocation = cast(TotalQuantity as float)/(UniqueLocation+1),
			FeaturesTag.TotalQuantityperUniqueProductCategory = cast(TotalQuantity as float)/(UniqueProductCategory+1),
			FeaturesTag.TotalValueperUniqueTransactionId = TotalValue/(UniqueTransactionId+1),
			FeaturesTag.TotalValueperUniqueItemId = TotalValue/(UniqueItemId+1),
			FeaturesTag.TotalValueperUniqueLocation = TotalValue/(UniqueLocation+1),
			FeaturesTag.TotalValueperUniqueProductCategory = TotalValue/(UniqueProductCategory+1)
		from FeaturesTag

	-- Add tags to the feature table
	alter table FeaturesTag add Tag varchar(10)
	update FeaturesTag 
		set FeaturesTag.Tag = case 
										when ((OverallProductsPurchased-PrechurnProductsPurchased)<=(select ChurnThreshold from ChurnVars))  then 'Churner'
										else 'Nonchurner'
								   end
		from FeaturesTag 
		full join #OverallActivities
		on FeaturesTag.UserId = #OverallActivities.UserId

	-- Remove total item purchased and add profile variables
	alter table FeaturesTag 
	drop column PrechurnProductsPurchased

	alter table FeaturesTag 
	add Age varchar(50),
		Address varchar(50),
		Gender varchar(50),
		UserType varchar(50)

	update FeaturesTag 
		set FeaturesTag.Age = #ProfilesDedupe.Age,
			FeaturesTag.Address = #ProfilesDedupe.Address,
			FeaturesTag.UserType = #ProfilesDedupe.UserType
		from FeaturesTag 
		inner join #ProfilesDedupe
		on FeaturesTag.UserId = #ProfilesDedupe.UserId
end