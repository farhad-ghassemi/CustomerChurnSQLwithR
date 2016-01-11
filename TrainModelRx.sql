/* 
	Description: This file creates the procedure to train an Revolution R model for the customer churn template.
	Author: farhad.ghassemi@microsoft.com
	Date: Jan 2016
*/
use [Churn]
go

set ansi_nulls on
go

set quoted_identifier on
go

if EXISTS (select * from sys.objects where type = 'P' AND name = 'TrainModelRx')
  drop procedure TrainModelRx
go

create procedure TrainModelRx
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
    from FeaturesTag
    tablesample (70 percent) repeatable (98052)
'
  -- Insert the trained model into a database table
  insert into ChurnModelRx
  exec sp_execute_external_script @language = N'R',
                                  @script = N'

## Create model
InputDataSet$Tag <- factor(InputDataSet$Tag)
InputDataSet$Age <- factor(InputDataSet$Age)
InputDataSet$Address <- factor(InputDataSet$Address)
logitObj <- rxLogit(Tag ~ Age+Address+TotalQuantity+TotalValue+StDevQuantity+StDevValue+AvgTimeDelta+Recency+
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

