# Customer Churn Template on a SQL Server R Services
### Introduction:
Predicting customer churn is an important problem for many industries. This repository provides the files to set up and run a customer churn machine learning template on a [SQL Server R services](https://msdn.microsoft.com/en-us/library/mt604845.aspx). 

The template discussed here closely follows the [Azure ML template for customer churn](http://gallery.cortanaanalytics.com/Collection/Retail-Customer-Churn-Prediction-Template-1?share=1).  
The template takes two datasets as input: a customer profile dataset and a transaction dataset. The schema for these datasets in the current implementation can be found [here](http://gallery.cortanaanalytics.com/Experiment/Retail-Churn-Template-Step-1-of-4-tagging-data-1).
However, the users should be easily able to modify the schema to their own need as what has provided here is only an example. Furthermore the template allows the users to define the churn period and the threshold in number of transactions to identify churners. 

### Steps to Set up the Template:
#### Step 1: Download sample datasets and SQL script files on a local machine with access to the SQL server.
All files related to this walkthrough (including the sample datasets) are stored in this git repository. To download these files, click on **Download ZIP** or clone the repository by running `git clone https://github.com/farhad-ghassemi/CustomerChurnSQLwithR`.

#### Step 2: Upload sample datasets into the SQL server and create a database and tables.
The user needs to upload the datasets (`Transactions.csv` and `Profiles.csv`) into a local directory on the SQL server. Once these files are uploaded to the dataset, the user must run `CreateDBUploadTables.sql` from a SQL Server Management Studio (SSMS). 
The sql script assumes that the two datasets are stored at this location: `C:\ChurnData`. If the location is different, the user can modify the script before running it. Furthermore, the values of the churn period and churn threshold are
also defined in this sql script. After running this script, a database called `Churn` should be generated and the following tables should exist in the database:
  

|            Table         |          Purpose             |
|------------------------------|-------------------------------|
| `Transactions` | Customer trasnsactions   |
| `Profiles`             | Customer profiles               |
| `ChurnVars`           | Churn period and threshold parameters|
| `ChurnModelR`           | Churn model trained using Open Source R|
| `ChurnModelRx`           | Churn model trained using Revolution R|

  
In addition to creating the database and 
required tables, the above script also generates features and tages, trains a model and evaluates its performance on a test data. Alternatively, the user can run the scripts described in the table below
from the SQL Server Management Studio on a local machine that has access to the SQL server.

|            File Name         |          Function             |
|------------------------------|-------------------------------|
| `generateFeaturesAndTag.sql` | Generate features and tags    |
| `trainModel.sql`             | Train the model               |
| `predictChurn.sql`           | Predict the customer behavior |