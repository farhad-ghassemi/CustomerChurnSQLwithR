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
		into FeaturesLabel
		from  #ActivitiesDedupe
		where Timestamp<=dateAdd(day, -1*(select ChurnPeriod from ChurnVars), (select max(Timestamp) from  #ActivitiesDedupe)) 
		group by UserId

alter table FeaturesLabel 
add TotalQuantityperUniqueTransactionId real,
    TotalQuantityperUniqueItemId real,
    TotalQuantityperUniqueLocation real,
    TotalQuantityperUniqueProductCategory real,
	TotalValueperUniqueTransactionId real,
	TotalValueperUniqueItemId real,
	TotalValueperUniqueLocation real,
	TotalValueperUniqueProductCategory real
-- '+1' is added to follow the Azure ML template. Not sure if it is necessary.
update FeaturesLabel
	set FeaturesLabel.TotalQuantityperUniqueTransactionId = cast(TotalQuantity as float)/(UniqueTransactionId+1),
	    FeaturesLabel.TotalQuantityperUniqueItemId = cast(TotalQuantity as float)/(UniqueItemId+1),
	    FeaturesLabel.TotalQuantityperUniqueLocation = cast(TotalQuantity as float)/(UniqueLocation+1),
		FeaturesLabel.TotalQuantityperUniqueProductCategory = cast(TotalQuantity as float)/(UniqueProductCategory+1),
		FeaturesLabel.TotalValueperUniqueTransactionId = TotalValue/(UniqueTransactionId+1),
	    FeaturesLabel.TotalValueperUniqueItemId = TotalValue/(UniqueItemId+1),
	    FeaturesLabel.TotalValueperUniqueLocation = TotalValue/(UniqueLocation+1),
		FeaturesLabel.TotalValueperUniqueProductCategory = TotalValue/(UniqueProductCategory+1)
	from FeaturesLabel

-- Add labels to the feature table
alter table FeaturesLabel add Label varchar(10)
update FeaturesLabel 
	set FeaturesLabel.Label = case 
									when ((OverallProductsPurchased-PrechurnProductsPurchased)<=(select ChurnThreshold from ChurnVars))  then 'Churner'
									else 'Nonchurner'
							   end
	from FeaturesLabel 
	full join #OverallActivities
	on FeaturesLabel.UserId = #OverallActivities.UserId

-- Remove total item purchased and add profile variables
alter table FeaturesLabel 
drop column PrechurnProductsPurchased

alter table FeaturesLabel 
add Age varchar(50),
    Address varchar(50),
	Gender varchar(50),
	UserType varchar(50)

update FeaturesLabel 
	set FeaturesLabel.Age = #ProfilesDedupe.Age,
	    FeaturesLabel.Address = #ProfilesDedupe.Address,
		FeaturesLabel.UserType = #ProfilesDedupe.UserType
	from FeaturesLabel 
	inner join #ProfilesDedupe
	on FeaturesLabel.UserId = #ProfilesDedupe.UserId
