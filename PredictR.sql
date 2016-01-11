/* 
	Description: This file creates the procedure to predict churn outcome based on the open source R model previously built.
	Author: farhad.ghassemi@microsoft.com
	Date: Jan 2016
*/
use [Churn]
go

set ansi_nulls on
go

set quoted_identifier on
go

if EXISTS (select * from sys.objects where type = 'P' AND name = 'PredictChurnR')
  drop procedure TrainModelR
go


create procedure PredictChurnR @inquery nvarchar(max)
as
begin
  declare @modelt varbinary(max) = (select top 1 model from ChurnModelR);
  exec sp_execute_external_script @language = N'R',
                                  @script = N'
mod <- unserialize(as.raw(model));
print(summary(mod))
Scores <- predict(mod, newdata = InputDataSet, type = "response");
OutputDataSet <- data.frame(InputDataSet$UserId,InputDataSet$Tag,Scores)
str(OutputDataSet)
print(OutputDataSet)

',
                                  @input_data_1 = @inquery,
                                  @params = N'@model varbinary(max)',
                                  @model = @modelt
  with RESULT sets ((UserId bigint,
                     Tag varchar(10),    
                     Score float));
end

declare @query_string nvarchar(max)
set @query_string='
select a.* from FeaturesTag a
left outer join
(
select * from FeaturesTag
tablesample (70 percent) repeatable (98052)
)b
on a.UserId=b.UserId
where b.UserId is null 
'