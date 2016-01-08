# CustomerChurnSQLwithR
This repository provides the files to set up and run a customer churn machine learning template on a [SQL Server R services](https://msdn.microsoft.com/en-us/library/mt604845.aspx). In terms of feature engineering and tag generation and other modeling details, this implementation of the customer churn template on
SQL server R services follows the detailed provided in [the Azure ML template for customer churn](http://gallery.cortanaanalytics.com/Collection/Retail-Customer-Churn-Prediction-Template-1?share=1).  

#### Step 1: Download sample datasets and SQL script files on a local machine with access to the SQL server.
All files related to this walkthrough (including the sample datasets) are stored in a git repository. To download these files, click on **Download Zip** or clone the repository 'git clone https://github.com/farhad-ghassemi/CustomerChurnSQLwithR</code>'.

#### Step 2: Upload sample datasets into the SQL server and create a database and tables.
The user needs to copy the datasets (transactions.csv and profiles.csv) into a local directory on the SQL server, note the path where the files are uploaded to and run the following PowerShell script.

.\runsql.ps1 -server <server address> -dbname <name of the db you want to create> -u <user name> -p <password> -csvfilepath <path to the csv file to be uploaded to the table>
```

If your account is Windows Authentication, parameters '-u <user name> -p <password>' are not needed. 

In addition to creating the database and 
required tables, the above script also generates features and tages, trains a model and evaluates its performance on a test data. Alternatively, the user can run the scripts described in the table below
from the SQL Server Management Studio on a local machine that has access to the SQL server.

|            File Name                    |          Function             |
|-----------------------------------------|-------------------------------|
| <code>generateFeaturesAndTag.sql</code> | Generates features and tags   |
| <code>trainModel.sql</code>             | Train the model               |
| <code>predictChurn.sql</code>           | Predict the customer behavior |