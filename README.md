# Customer Churn Template on a SQL Server R Services
### Introduction:
Predicting customer churn is an important problem for many industries. This repository provides the files to set up and run a customer churn machine learning template on a [SQL Server R services](https://msdn.microsoft.com/en-us/library/mt604845.aspx). 

The template discussed here closely follows the [Azure ML template for customer churn](http://gallery.cortanaanalytics.com/Collection/Retail-Customer-Churn-Prediction-Template-1?share=1). The template takes two datasets as input: a customer profile dataset and a transaction dataset. The schema for these datasets in the current implementation can be found [here](http://gallery.cortanaanalytics.com/Experiment/Retail-Churn-Template-Step-1-of-4-tagging-data-1).
However, the users should be easily able to modify the schema to their own need as what has provided here is only an example. The template also allows the users to define the churn period and the threshold in the number of transactions to identify churners. 

### Steps to Set up and Run Customer Churn Template:
#### Step 1: Downloading Files 
All files related to this walkthrough (including the sample datasets) are stored in this git repository. To download these files on a local machine with access to the SQL server (or directly on the SQL server), click on **Download ZIP** or clone the repository by running `git clone https://github.com/farhad-ghassemi/CustomerChurnSQLwithR`.

#### Step 2: Creating the Database and Tables
The user needs to upload the datasets (`Transactions.csv` and `Profiles.csv`) into a local directory on the SQL server. Once these files are uploaded to the SQL server, the user must run `CreateDBUploadTables.sql` from a SQL Server Management Studio (SSMS) with access to the server. 
The first few lines of this script introduces user-defined variables (These lines are marked by comments in the file). The important variables to pay attention to include: 1) The name of the database, 2) The location of the files on the server and 3) The name of tables to be created. 
The user can also define here the values of the churn period and churn threshold.

If the user uses the default values, after running the scrip, a database called `Churn` is generated with the following tables:
  
|            Table         |          Purpose             |
|------------------------------|-------------------------------|
| `Transactions` | Customer trasnsactions   |
| `Profiles`             | Customer profiles               |
| `ChurnVars`           | Churn period and threshold parameters|
| `ChurnModelR`           | Churn model trained using open source R|
| `ChurnModelRx`           | Churn model trained using Revolution R|

#### Step 3: Feature and Tags Generation, Model Training and Prediction (Open-Source R and Revolution R)
Once the database and tabels are created, the user can run `CustomerChurnTemplateR.sql` or `CustomerChurnTemplateRx.sql` to create features and tags from the `Profiles` and `Transactions` tables and to train a model and make predictions. `CustomerChurnTemplateR.sql` relies on
the open source R functions whereas `CustomerChurnTemplateRx.sql` employs the Revolution R commands. Each of these scripts call the following procedures to accomplish their tasks:  

|            Procedure          |          Purpose             |
|------------------------------|-------------------------------|
| `CreateFeaturesAndTag.sql` | Generate features and tags    |
| `TrainModelR.sql` or `TrainModelRx.sql`              | Train the model               |
| `PredictChurnR.sql` or `PredictChurnRx.sql`          | Predict the customer behavior |