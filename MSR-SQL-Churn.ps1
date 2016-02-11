<#d
.SYNOPSIS
Script to trian and test the customer churn template with SQL + MRS
#>

##########################################################################
# Internal parameters.
##########################################################################
$activities_tbname = "Activities"
$users_tbname = "Users"
$local_file_path = ".\"
$activities_local_fname = $local_file_path + "Activities.csv" 
$users_local_fname = $local_file_path + "Users.csv" 

##########################################################################
# Make a connection to the server.
##########################################################################
$server = Read-Host -prompt 'Server name'
#$server = "10.145.22.126"
$dbname = Read-Host -prompt 'Database name [Default:ChurnMSRTemplate]'
$defaultdbname = "ChurnMSRTemplate"
$files = $local_file_path + "*.sql"
$listfiles = Get-ChildItem $files
#if ($defaultdbname -ne $dbname)
#{
#    foreach ($file in $listfiles)
#    {
#        (Get-Content $file).replace($defaultdbname, $dbname) | Set-Content $file
#    }
#}

$u = Read-Host -prompt 'Username'
$p0 = Read-Host -prompt 'Password' -AsSecureString
$p1 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($p0)
$p = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($p1)
try 
{ 
    $SQLConnection = New-Object System.Data.SqlClient.SqlConnection 
    #The MS SQL Server user and password is specified 
    if($u -and $p) 
    { 
        $SQLConnection.ConnectionString = "Server=" + $server + ";Database=master;User ID= "  + $u + ";Password="  + $p + ";" 
    } 
    #The MS SQL Server user and password is not specified - using the Windows user credentials 
    else 
    { 
        $SQLConnection.ConnectionString = "Server=" + $server + ";Database=master;Integrated Security=True" 
    } 
    $SQLConnection.Open() 
} 
#Error of connection 
catch 
{ 
    Write-Host $Error[0] -ForegroundColor Red 
    exit 1 
} 

##########################################################################
# Replace variables with their values in sql scripts.
##########################################################################
#The GO switch is specified - parsing T-SQL code with GO
function ExecuteSQLFile($sqlfile,$go_or_not)
{ 
    if($go_or_not -eq 1) 
    { 
        $SQLCommandText = @(Get-Content -Path $sqlfile) 
        foreach($SQLString in  $SQLCommandText) 
        { 
            if($SQLString -ne "go") 
            { 
                #Preparation of SQL packet 
                if($SQLString.ToLower() -match "set @db_name")
                {
                    $SQLPacket += "set @db_name = '" + $dbname + "'`n"
                }
                Elseif($SQLString -match "SET @db_name")
                {
                    $SQLPacket += "SET @db_name = " + $dbname + "`n"
                }
                Else
                {
                    $SQLPacket += $SQLString + "`n"
                } 
            } 
            else 
            { 
                Write-Host "---------------------------------------------" 
                Write-Host "Executed SQL packet:" 
                Write-Host $SQLPacket 
                $IsSQLErr = $false 
                #Execution of SQL packet 
                try 
                { 
                    $SQLCommand = New-Object System.Data.SqlClient.SqlCommand($SQLPacket, $SQLConnection) 
                    $SQLCommand.CommandTimeout = 0
                    $SQLCommand.ExecuteScalar() 
                } 
                catch 
                { 
 
                    $IsSQLErr = $true 
                    Write-Host $Error[0] -ForegroundColor Red 
                    $SQLPacket | Out-File -FilePath ($PWD.Path + "\SQLErrors.txt") -Append 
                    $Error[0] | Out-File -FilePath ($PWD.Path + "\SQLErrors.txt") -Append 
                    "----------" | Out-File -FilePath ($PWD.Path + "\SQLErrors.txt") -Append 
                } 
                if(-not $IsSQLErr) 
                { 
                    Write-Host "Execution succesful" 
                } 
                else 
                { 
                    Write-Host "Execution failed"  -ForegroundColor Red 
                } 
                $SQLPacket = "" 
            } 
        } 
    } 
    else 
    { 
        #Reading the T-SQL file as a whole packet 
        $SQLCommandText = Get-Content $sqlfile -Raw 
        #Execution of SQL packet 
        try 
        { 
            $SQLCommand = New-Object System.Data.SqlClient.SqlCommand($SQLCommandText, $SQLConnection) 
            $SQLCommand.CommandTimeout = 0
            $SQLCommand.ExecuteScalar() 
        } 
        catch 
        { 
            Write-Host $Error[0] -ForegroundColor Red 
        } 
    } 
    #Disconnection from MS SQL Server     
    Write-Host "-----------------------------------------" 
    Write-Host $sqlfile "execution done"
}

function ExecuteSQL
{
param(
[String]
$sqlscript
)
    Invoke-Sqlcmd -ServerInstance $server  -Database $dbname -Username $u -Password $p -InputFile $sqlscript -QueryTimeout 200000
}

##########################################################################
# Create tables from csv files.
##########################################################################
Write-Host -foregroundcolor 'green' ("Step 1: Create and populate in Database" -f $dbname)
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
	$activities_url = Read-Host -prompt 'URL for activities file'
	$users_url = Read-Host -prompt 'URL for users file'
	#$activities_url = "http://azuremlsamples.azureml.net/templatedata/RetailChurn_ActivityInfoData.csv"
	#$users_url = "http://azuremlsamples.azureml.net/templatedata/RetailChurn_UserInfoData.csv"

	Invoke-WebRequest -Uri $activities_url -OutFile $activities_local_fname 	
	Invoke-WebRequest -Uri $users_url -OutFile $users_local_fname 	
	
	# create database and tables
    $script = $local_file_path + "CreateDBUploadTables.sql"
    ExecuteSQLFile $script 1

    # load activities table
	Write-Host -foregroundcolor 'green' ("Here")
    $activities_db_tbname = $dbname + ".dbo." + $activities_tbname
    if($u -and $p) 
    { 
		bcp $activities_db_tbname in $activities_local_fname -S $server -U $u -P $p -t ',' -c
	}
	#The MS SQL Server user and password is not specified - using the Windows user credentials 
	else
	{
		bcp $activities_db_tbname in $activities_local_fname -S $server -T -t ',' -c
	}
	
    # load users table
    $users_db_tbname = $dbname + ".dbo." + $users_tbname
    if($u -and $p) 
    { 
		bcp $users_db_tbname in $users_local_fname -S $server -U $u -P $p -t ',' -c
	}
	#The MS SQL Server user and password is not specified - using the Windows user credentials 
	else
	{
		bcp $users_db_tbname in $users_local_fname -S $server -T -t ',' -c
	}	
}

##########################################################################
# Create and execute the stored procedure for feature engineering and tags
##########################################################################
Write-Host -foregroundcolor 'green' ("Step 2: Data processing and feature engineering")
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
    # create and execute the stored procedure for feature engineering
    $script = $local_file_path + "CreateFeatures.sql"
    ExecuteSQLFile $script 1
	

    # create and execute the stored procedure for tags
    $script = $local_file_path + "CreateTag.sql"
    ExecuteSQLFile $script 1
}

#############################################################################################
# Create and execute the stored procedures for training an open-source R or Microsoft R model
#############################################################################################
Write-Host -foregroundcolor 'green' ("Step 3a: Training an open-source model")
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
    # create and execute the stored procedure for an open-source R model
    $script = $local_file_path + "TrainModelR.sql"
    ExecuteSQLFile $script 1
}

Write-Host -foregroundcolor 'green' ("Step 3b: Training a Microsoft R model")
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
    # create and execute the stored procedure for a Microsoft R model
    $script = $local_file_path + "TrainModelRx.sql"
    ExecuteSQLFile $script 1
}

########################################################################################################################
# Create and execute the stored procedures for prediction based on previously trained open-source R or Microsoft R model
########################################################################################################################
Write-Host -foregroundcolor 'green' ("Step 4a: Predicting based on the open-source model")
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
    # create and execute the stored procedure for an open-source R model
    $script = $local_file_path + "PredictR.sql"
    ExecuteSQLFile $script 1
}

Write-Host -foregroundcolor 'green' ("Step 4b: Predicting based on the Microsoft R model")
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
    # create and execute the stored procedure for a Microsoft R model
    $script = $local_file_path + "PredictRx.sql"
    ExecuteSQLFile $script 1
}

