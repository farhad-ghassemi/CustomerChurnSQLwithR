Use [Churn]
Go

--- Define parameters
create table ChurnVars
(
	ChurnPeriod int,
	ChurnThreshold int
)
insert into ChurnVars (ChurnPeriod,ChurnThreshold) values (21,0)

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

-- Train the model (Gender and UserType were not used as these variables currently have only one level)
create table ChurnModel
(
	model varbinary(max) not null
)

create procedure TrainModel
as
begin
  declare @inquery nvarchar(max) = N'
	select Age, Address, 
	TotalQuantity, TotalValue, StDevQuantity, StDevValue,
	AvgTimeDelta, Recency,
	UniqueTransactionId, UniqueItemId, UniqueLocation, UniqueProductCategory,
	TotalQuantityperUniqueTransactionId, TotalQuantityperUniqueItemId, TotalQuantityperUniqueLocation, TotalQuantityperUniqueProductCategory, 
	TotalValueperUniqueTransactionId, TotalValueperUniqueItemId, TotalValueperUniqueLocation, TotalValueperUniqueProductCategory, 
	Label
    from FeaturesLabel
    tablesample (70 percent) repeatable (98052)
'
  -- Insert the trained model into a database table
  insert into ChurnModel
  exec sp_execute_external_script @language = N'R',
                                  @script = N'

## Create model
InputDataSet$Label <- factor(InputDataSet$Label)
InputDataSet$Age <- factor(InputDataSet$Age)
InputDataSet$Address <- factor(InputDataSet$Address)
logitObj <- rxLogit(Label ~ Age+Address+TotalQuantity+TotalValue+StDevQuantity+StDevValue+AvgTimeDelta+Recency+
	                        UniqueTransactionId+UniqueItemId+UniqueLocation+UniqueProductCategory+
							TotalQuantityperUniqueTransactionId+TotalQuantityperUniqueItemId+TotalQuantityperUniqueLocation+TotalQuantityperUniqueProductCategory+ 
							TotalValueperUniqueTransactionId+TotalValueperUniqueItemId+TotalValueperUniqueLocation+TotalValueperUniqueProductCategory, data = InputDataSet)
summary(logitObj)

## Serialize model and put it in data frame
trained_model <- data.frame(model=as.raw(serialize(logitObj, NULL)));
',
                                  @input_data_1 = @inquery,
                                  @output_data_1_name = N'trained_model'
  ;
end

exec TrainModel

create table ChurnModelNoRx
(
	model varbinary(max) not null
)
create procedure TrainModelNoRx
as
begin
  declare @inquery nvarchar(max) = N'
	select Age, Address, 
	TotalQuantity, TotalValue, StDevQuantity, StDevValue,
	AvgTimeDelta, Recency,
	UniqueTransactionId, UniqueItemId, UniqueLocation, UniqueProductCategory,
	TotalQuantityperUniqueTransactionId, TotalQuantityperUniqueItemId, TotalQuantityperUniqueLocation, TotalQuantityperUniqueProductCategory, 
	TotalValueperUniqueTransactionId, TotalValueperUniqueItemId, TotalValueperUniqueLocation, TotalValueperUniqueProductCategory, 
	Label
    from FeaturesLabel
    tablesample (70 percent) repeatable (98052)
'
  -- Insert the trained model into a database table
  insert into ChurnModelNoRx
  exec sp_execute_external_script @language = N'R',
                                  @script = N'

## Create model
InputDataSet$Label <- factor(InputDataSet$Label)
InputDataSet$Age <- factor(InputDataSet$Age)
InputDataSet$Address <- factor(InputDataSet$Address)
logitObj <- glm(Label ~ ., family = binomial, data = InputDataSet)
summary(logitObj)

## Serialize model and put it in data frame
trained_model <- data.frame(model=as.raw(serialize(logitObj, NULL)));
',
                                  @input_data_1 = @inquery,
                                  @output_data_1_name = N'trained_model'
  ;
end

exec TrainModelNoRx

-- Test the model (Gender and UserType were not used as these variables currently have only one level)
create procedure PredictChurn @inquery nvarchar(max)
as
begin
  declare @modelt varbinary(max) = (select top 1 model from ChurnModel);
  exec sp_execute_external_script @language = N'R',
                                  @script = N'
mod <- unserialize(as.raw(model));
print(summary(mod))
Scores<-rxPredict(modelObject = mod, data = InputDataSet, outData = NULL, 
          predVarNames = "Score", type = "response", writeModelVars = FALSE, overwrite = TRUE);
OutputDataSet <- data.frame(InputDataSet$UserId,InputDataSet$Label,Scores)
str(OutputDataSet)
print(OutputDataSet)

',
                                  @input_data_1 = @inquery,
                                  @params = N'@model varbinary(max)',
                                  @model = @modelt
  with RESULT sets ((UserId bigint,
                     Label varchar(10),    
                     Score float));
end

declare @query_string nvarchar(max)
set @query_string='
select a.* from FeaturesLabel a
left outer join
(
select * from FeaturesLabel
tablesample (70 percent) repeatable (98052)
)b
on a.UserId=b.UserId
where b.UserId is null 
'
exec PredictChurn @inquery = @query_string;

create procedure PredictChurnNoRx @inquery nvarchar(max)
as
begin
  declare @modelt varbinary(max) = (select top 1 model from ChurnModelNoRx);
  exec sp_execute_external_script @language = N'R',
                                  @script = N'
mod <- unserialize(as.raw(model));
print(summary(mod))
Scores <- predict(mod, newdata = InputDataSet, type = "response");
OutputDataSet <- data.frame(InputDataSet$UserId,InputDataSet$Label,Scores)
str(OutputDataSet)
print(OutputDataSet)

',
                                  @input_data_1 = @inquery,
                                  @params = N'@model varbinary(max)',
                                  @model = @modelt
  with RESULT sets ((UserId bigint,
                     Label varchar(10),    
                     Score float));
end

declare @query_string nvarchar(max)
set @query_string='
select a.* from FeaturesLabel a
left outer join
(
select * from FeaturesLabel
tablesample (70 percent) repeatable (98052)
)b
on a.UserId=b.UserId
where b.UserId is null 
'
exec PredictChurnNoRx @inquery = @query_string;

-- Temporary commands
select * from #ActivitiesDedupe
select * from FeaturesLabel
select * from #ProfilesDedupe
alter table #ActivitiesDedupe
drop column TotalQuantityperUniqueTransactionId
select * from Activities where UserId='930505'
select count(UserId) from #PrechurnActivity
select count(*) from FeaturesLabel
select count(*) from #Test
select count(*) from INFORMATION_SCHEMA.COLUMNS where table_catalog = 'Churn' and table_name = 'FeaturesLabel'
drop procedure TrainModel
drop procedure TrainModelNoRx
drop procedure PredictChurn
drop procedure PredictChurnNoRx
select * from #Train
select * from #Test where UserId='2065991'
select * from #Test where UserId='2066158'
select * from #Test where UserId='631211'

-- Drop temp tables
drop table #ActivitiesDedupe
drop table #ProfilesDedupe
drop table #OverallActivity
drop table #PrechurnActivity
drop table #LagTimestamp
drop table FeaturesLabel
drop table #Test
drop table #Train
drop table ChurnModel


