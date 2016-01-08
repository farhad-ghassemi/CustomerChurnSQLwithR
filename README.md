# CustomerChurnSQLwithR
This repository provides the files to set up and run a customer churn machine learning platform in SQL server with R services. 

### Step 1: Download the sample datasets on the SQL server and SQL script files on a local machine that has access to SQL server.
All files related to this walkthrough (including the sample datasets) are stored in a git repository. 
The user needs to copy the datasets (transactions.csv and profiles.csv) into a local directory on the SQL server and write down the path to these files as 
this information is needed in the next step when loading the datasets to the table. The other files in the repository should be copied to a local machine with access to the SQL server.  

To download all files, open a Windows PowerShell command console and run the following commands:

<code>
$source = ‘https://github.com/farhad-ghassemi/CustomerChurnSQLwithR/master/Download_ChurnCustomerFiles.ps1’
$ps1_dest = “$pwd\Download_ChurnCustomerFiles.ps1.ps1”
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($source, $ps1_dest)
.\Download_SQL_Scripts.ps1 –DestDir ‘C:\ChurnCustomerSQLwithR’
</code>