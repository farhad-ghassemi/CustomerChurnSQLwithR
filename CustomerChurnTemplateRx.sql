/* 
	Description: This file execute the following procedure to create features, train a Revolution R model and make predictions for the customer churn template.
	Author: farhad.ghassemi@microsoft.com
	Date: Jan 2016
*/


use [Churn]
go

set ansi_nulls on
go

set quoted_identifier on
go

if EXISTS (select * from sys.objects where object_id = OBJECT_ID(N'FeaturesTag') AND type in (N'U'))
  drop table FeaturesTag
go

execute CreateFeaturesTag
execute TrainModelRx

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
execute PredictChurnRx @inquery = @query_string;

