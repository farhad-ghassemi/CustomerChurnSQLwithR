################################################################################
#    Copyright (c) Microsoft. All rights reserved.
#    
#    Apache 2.0 License
#    
#    You may obtain a copy of the License at
#    http://www.apache.org/licenses/LICENSE-2.0
#    
#    Unless required by applicable law or agreed to in writing, software 
#    distributed under the License is distributed on an "AS IS" BASIS, 
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or 
#    implied. See the License for the specific language governing 
#    permissions and limitations under the License.
#
################################################################################
param([string]$DestDir)

$web_client = new-object System.Net.WebClient


function DownloadRawFromGitWithFileList($base_url, $file_list_name, $destination_dir)
{   
    if (!(Test-Path $destination_dir)) {
        mkdir $destination_dir
    }

    # Download the list so we can iterate over it.
    $tempPath = [IO.Path]::GetTempFileName()
    $url = $base_url + $file_list_name
    $web_client.DownloadFile($url, $tempPath)

    # Iterate over the different lines in the file and add them to the machine
    $reader = [System.IO.File]::OpenText($tempPath)
    try {
        for(;;) {
            $line = $reader.ReadLine()
            if ($line -eq $null) { break }
           
            # download the file specified by this line...
            $url = $base_url + $line
            $destination = Join-Path $destination_dir $line
            $web_client.DownloadFile($url, $destination)
        }
    }
    finally {
        $reader.Close()
    }
}

function GetSampleFilesFromGit($list_name, $destination_dir){
    $file_url = "https://github.com/farhad-ghassemi/CustomerChurnSQLwithR/blob/master/"
    DownloadRawFromGitWithFileList $file_url $list_name $destination_dir
}


###################### End of Functions / Start of Script ######################
Write-Output "Fetching the sample .sql script files to $DestDir..."
GetSampleFilesFromGit "FilestoDownload.txt" $DestDir
Write-Output "Fetching the sample .sql script files completed."
Write-Output "Now entering the destination directory $DestDir."
cd $DestDir