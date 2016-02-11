# Customer Churn Template on Microsoft SQL Server R Services

INTRODUCTION
------------

This template demonstrates how to build and deploy a customer churn model using a [Microsoft SQL Server R Services](https://msdn.microsoft.com/en-us/library/mt604845.aspx). 

 * For a full description of the template in Cortana Analytics Suite, visit the [project page](http://gallery.cortanaanalytics.com/Collection/Retail-Customer-Churn-Prediction-Template-1).

 * To check the source code, modify or track changes, please visit this [github link](https://github.com/Azure/Azure-MachineLearning-DataScience-Private/tree/master/Misc/SQL_RRE_Templates/Churn).


REQUIREMENTS
------------

To run the scripts, it requires the following:

 * Microsoft SQL Server R Services installed and configured. Visit [this link](https://msdn.microsoft.com/en-us/library/mt604885.aspx) to configure a server. 
 * A user name and password or Windows Authnetication capability to access the server.
 * Data on user information as well as their activities/interactions with the vendor. In this template, we provide sample datasets and how to load them to the server.
 
WORKFLOW AUTOMATION
-------------------

The end-to-end workflow is automated with a Windows PowerShell script. The script can be invoked remotely from the PowerShell console by running the following command:

	MSR-SQL-Churn.ps1

The PowerShell script invokes a number of SQL scripts through the steps described below. Each step can be also skipped if not needed. The PowerShell script is mainly provided as a convenient way for the user to deploy the template.   
An experienced user may directly run, modifiy or intergrate the provided SQL scripts in their your system.    

   
STEP 1: DATA PREPARATION
------------------------

The template requires two datasets as input: a dataset of the user profiles and a dataset of the user activities. As part of this repository, we have provided two sample datasets. The schema for these datasets can be found [here](http://gallery.cortanaanalytics.com/Experiment/Retail-Churn-Template-Step-1-of-4-tagging-data-1).
Furthermore, the files can be downloaded from this [link](http://azuremlsamples.azureml.net/templatedata/RetailChurn_ActivityInfoData.csv) and this [link](http://azuremlsamples.azureml.net/templatedata/RetailChurn_UserInfoData.csv).

Once the PowerShell script is invoked, the user must first enter a server name (or its IP address) and a database name. If the user presses enter for the database name, a default name is used. Then, the user must enter the user name and password. 
If the user does not provide a user name or password, a connection based on the Windows account information is established.     

The user then must enter 
The template also allows the users to define the churn period and the threshold in the number of transactions to identify churners. 


### Steps to Set up and Run Customer Churn Template:
#### Step 1: Downloading Files 
All files related to this walkthrough (including the sample datasets) are stored in this git repository. To download these files on a local machine with access to the SQL server (or directly on the SQL server), click on **Download ZIP** or clone the repository by running `git clone https://github.com/farhad-ghassemi/CustomerChurnSQLwithR`.

#### Step 2: Creating Database and Tables
The user needs to upload the datasets (`Transactions.csv` and `Profiles.csv`) into a local directory on the SQL server. Once these files are uploaded to the SQL server, the user must run `CreateDBUploadTables.sql` from a SQL Server Management Studio (SSMS) with access to the server. 
The first few lines of this script introduces user-defined variables (These lines are marked by comments in the file). The important variables to pay attention to include: 1) The name of the database, 2) The location of the files on the server and 3) The name of tables to be created. 
The user can also define here the values of the churn period and churn threshold.

If the user uses the default values, after running the scrip, a database called `Churn` is generated with the following tables:
  
|            Table         |          Purpose             |
|------------------------------|-------------------------------|
| `Transactions` | Customer trasnsactions   |
| `Profiles`             | Customer profiles               |
| `ChurnVars`           | Churn period and threshold parameters|
| `ChurnModelR`           | Churn model trained using open-source R|
| `ChurnModelRx`           | Churn model trained using Microsoft R Server|

#### Step 3: Feature and Tags Generation, Model Training and Prediction (Open-Source R and Microsoft R Server)
Once the database and tabels are created, the user can run `CustomerChurnTemplateR.sql` or `CustomerChurnTemplateRx.sql` to create features and tags from the `Profiles` and `Transactions` tables and to train a model and make predictions. `CustomerChurnTemplateR.sql` relies on
the open-source R functions whereas `CustomerChurnTemplateRx.sql` employs the [Microsoft R Server (formerly known as Revolution R)](https://www.microsoft.com/en-us/server-cloud/products/r-server/) functions. Each of these scripts call the following procedures to accomplish their tasks:  

|            Procedure          |          Purpose             |
|------------------------------|-------------------------------|
| `CreateFeaturesTag.sql` | Generate features and tags    |
| `TrainModelR.sql` or `TrainModelRx.sql`              | Train the model               |
| `PredictChurnR.sql` or `PredictChurnRx.sql`          | Predict the customer behavior |

### Output:
The template generates a table with the following columns for a group of customers who are randomly selected and used as the test dataset:

|            Column          |          Description            |
|------------------------------|-------------------------------|
| `UserId` | Customer Id    |
| `Tag`              | True customer status (churner or non-churner)               |
| `Score`          | Model score |
| `Auc`          | Model auc on test dataset (identical for all columns) |