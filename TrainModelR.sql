/* 
	Description: This file creates the procedure to train an open source R model for the customer churn template.
	Author: farhad.ghassemi@microsoft.com
*/
use [ChurnMSRTemplate]
go

set ansi_nulls on
go

set quoted_identifier on
go

if exists (select * from sys.objects where type = 'P' and name = 'TrainModelR')
  drop procedure TrainModelR
go

create procedure TrainModelR
as
begin
  declare @inquery nvarchar(max) = N'
	select Age, Address, 
	TotalQuantity, TotalValue, StDevQuantity, StDevValue,
	AvgTimeDelta, Recency,
	UniqueTransactionId, UniqueItemId, UniqueLocation, UniqueProductCategory,
	TotalQuantityperUniqueTransactionId, TotalQuantityperUniqueItemId, TotalQuantityperUniqueLocation, TotalQuantityperUniqueProductCategory, 
	TotalValueperUniqueTransactionId, TotalValueperUniqueItemId, TotalValueperUniqueLocation, TotalValueperUniqueProductCategory,
	Tag
    from Features
    tablesample (70 percent) repeatable (98052)
	join Tags on Features.UserId=Tags.UserId
'
  -- Insert the trained model into a database table
  insert into ChurnModelR
  exec sp_execute_external_script @language = N'R',
                                  @script = N'

## Create model
InputDataSet$Tag <- factor(InputDataSet$Tag)
InputDataSet$Age <- factor(InputDataSet$Age)
InputDataSet$Address <- factor(InputDataSet$Address)
logitObj <- glm(Tag ~ ., family = binomial, data = InputDataSet)
summary(logitObj)

## Serialize model and put it in data frame
trained_model <- data.frame(model=as.raw(serialize(logitObj, connection=NULL)));'
,@input_data_1 = @inquery
,@output_data_1_name = N'trained_model';
end
go

execute TrainModelR
go
