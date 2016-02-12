# Customer Churn Template on Microsoft SQL Server R Services

INTRODUCTION
------------

This template demonstrates how to build and deploy a customer churn model using a [Microsoft SQL Server R Services](https://msdn.microsoft.com/en-us/library/mt604845.aspx). 

 * For a full description of the template in Cortana Analytics Suite, visit the [project page](http://gallery.cortanaanalytics.com/Collection/Retail-Customer-Churn-Prediction-Template-1).

 * To check the source code, modify or track changes, please visit this [link](https://github.com/Azure/Azure-MachineLearning-DataScience-Private/tree/master/Misc/SQL_RRE_Templates/Churn).


REQUIREMENTS
------------

This template requires the following components:

 * Microsoft SQL Server R Services: Visit this [link](https://msdn.microsoft.com/en-us/library/mt604885.aspx) for steps to configure a server.
 
 * User name and password (set up separately or via Windows account) to access the server.
 
 * Data on the profile of users who interact with the business as well as their activities: In this template, we haved provided sample datasets and instructions on how to load these datasets to the server.
 
WORKFLOW AUTOMATION
-------------------

The end-to-end workflow is automated with a Windows PowerShell script. The script can be invoked remotely from the PowerShell console by running the following command:

	MSR-SQL-Churn.ps1

The PowerShell script invokes a number of SQL scripts through the steps described below. Each step can be also skipped if not needed. The PowerShell script is mainly provided as a convenient way for the user to deploy the template.   
An experienced user may directly run, modifiy or intergrate the provided SQL scripts in their your system.    

   
STEP 1: DATA PREPARATION
------------------------

The template requires two datasets as input: a dataset of the user profiles and a dataset of the user activities. As part of this repository, we have provided sample files for these datasets. 
These files can be downloaded [here](http://azuremlsamples.azureml.net/templatedata/RetailChurn_ActivityInfoData.csv) and [here](http://azuremlsamples.azureml.net/templatedata/RetailChurn_UserInfoData.csv).
The schema for the datasets are described [here](http://gallery.cortanaanalytics.com/Experiment/Retail-Churn-Template-Step-1-of-4-tagging-data-1).

In this step, the user is first asked to enter the following information:

 * Server name (or its IP address).
 
 * Database name: If the user does not provide a name and simply presses enter when answering this question, a default name is used. 
 
 * User name and password: If the user does not provide a user name and password, the script assumes a Windows Authnetication connection must be established and employes the Windows account informtion to connect to the server.     

 * URL address for the users and activities files: If the user does not specify a URL, the files are downloaded from a default location.

 * Churn period and threshold: In order to identify churners and non-churners, the templates needs these two parameters. The churn period specifies the number of days at the end of the activities period which is observed 
for identifying churners. Within this period, those users who have activities more than the churn threshold are considered as non-churners and otherwise as churners. 
 
Using the `bcp` utility, the script then retrieves the files from the URL address and uploads them into the server. It then envokes `CreateDBTables.sql` to create the database with the following tables: 
  
|            Table         |          Purpose             |
|------------------------------|-------------------------------|
| `Activities` | Customer activities   |
| `Users`             | Customer profiles               |
| `ChurnVars`           | Churn period and threshold|
| `ChurnModelR`           | Churn model trained using open-source R|
| `ChurnModelRx`           | Churn model trained using Microsoft R Server|
| `ChurnPredictR`           | Prediction results based on open-source R model|
| `ChurnPredictRx`           | Prediction results based on Microsoft R Server model|

STEP 2: FEATURE ENGINEERING
---------------------------

In the second step, `CreateFeatures.sql` and `CreateTag.sql` are invoked to create features and tags. The output of these two scripts is stored in these tables: `Features` and `Tags`.

STEP 3 (a and b): MODEL TRAINING
------------------------------

In the third step, `TrainModelR.sql` or `TrainModelRx.sql` are invoked to train the churn models. `TrainModelR.sql` employs the open-source R functions whereas `TrainModelRx.sql` employs the Microsoft R Server functions. 
The trained models are stored in `ChurnModelR` and `ChurnModelRx` tables.

STEP 4 (a and b): PREDICTION
----------------------------------

In the fourth step, `PredictR.sql` or `PredictRx.sql` are invoked to make predictions based on the models trained in the previous steps. `PredictR.sql` employs the open-source R model whereas `PredictRx.sql` employs the Microsoft R Server model. 
The results are stored in a table with the following columns:

|            Column          |          Description            |
|------------------------------|-------------------------------|
| `UserId` | User Id    |
| `Tag`              | True customer status (churner or non-churner)               |
| `Score`          | Model score |
| `Auc`          | Model auc on test dataset (identical for all columns) |