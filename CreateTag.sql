/* 
	Description: This file creates the tag for the customer churn template.
	Author: farhad.ghassemi@microsoft.com
*/
use [ChurnMSRTemplate]
go

set ansi_nulls on
go

set quoted_identifier on
go

if exists (select * from sys.objects where type = 'P' and name = 'CreateTag')
  drop procedure CreateTag
go

create procedure [dbo].[CreateTag]
as
begin

	-- Calculate overall purchased items by each customer
	select UserId, count(TransactionId) as OverallProductsPurchased into #OverallActivities from Activities group by UserId

	-- Feature engineering in pre churn period
	select UserId, count(TransactionId) as PrechurnProductsPurchased
			into Tags
			from  Activities
			where TransactionTime<=dateAdd(day, -1*(select ChurnPeriod from ChurnVars), (select max(TransactionTime) from  Activities)) 
			group by UserId

	-- Create tags
	alter table Tags add Tag varchar(10)
	update Tags 
		set Tags.Tag = case 
							when ((OverallProductsPurchased-PrechurnProductsPurchased)<=(select ChurnThreshold from ChurnVars))  then 'Churner'
							else 'Nonchurner'
						end
		from Tags 
		full join #OverallActivities
		on Tags.UserId = #OverallActivities.UserId

	alter table Tags 
	drop column PrechurnProductsPurchased
end
go

execute CreateTag
go
