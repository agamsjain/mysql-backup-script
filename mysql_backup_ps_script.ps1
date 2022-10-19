# Declare variables

$rootPath            = "C:\PuruBackup"
$backupRootFolder    = "mysql"
$backupZipRootFolder = "mysql_in_zip"

$configRootFolder = "config"
$hostIP           = "192.168.0.111"
$port             = "3306"
$schema_list_file = "schemas.txt"

$mysql_config_file_name = "mysql.cnf"
$logFile                = "automate-mysqldump.log"


$date = Get-Date -UFormat "%d-%m-%Y"
$time = Get-Date -Format "hhmmtt"

$mysqlDumpCommand   = "mysqldump"
$userArgs           = "-u puru1"
$protocolString     = "--protocol=tcp"
$hostnamePortString = "--host=" + $hostIP + " --port=" + $port
$characterSetString = "--default-character-set=utf8"
$extraArgs          = "--column-statistics=FALSE --skip-triggers"



#prepare configuration
$logFile_finalPath                 = Join-Path -Path $rootPath               -ChildPath $logFile
$configFolder                      = Join-Path -Path $rootPath               -ChildPath $configRootFolder
$mysqlBackupRootPath               = Join-Path -Path $rootPath               -ChildPath $backupRootFolder
$mysqlZipBackupRootPath            = Join-Path -Path $rootPath               -ChildPath $backupZipRootFolder
$configFileWithPath                = Join-Path -Path $configFolder           -ChildPath $mysql_config_file_name
$schemaNameListWithPath            = Join-Path -Path $configFolder           -ChildPath $schema_list_file
$mysqlBackupPerDatePath            = Join-Path -Path $mysqlBackupRootPath    -ChildPath $date
$mysqlBackupDateTimePath_finalPath = Join-Path -Path $mysqlBackupPerDatePath -ChildPath $time

$defaultFileArgs    = "--defaults-file=" + $configFileWithPath



New-Item -Path $mysqlBackupPerDatePath -Name $time -ItemType "directory"


if (-NOT (Test-Path $logFile_finalPath)) {
    New-Item -Path . -Name $logFile_finalPath -ItemType "file"
    Add-Content $logFile_finalPath "Created on: $date`n"
}


Add-Content $logFile_finalPath "[$date]: Starting mysqldump"

$schema_name_list = Get-Content -Path $schemaNameListWithPath

foreach($schema in $schema_name_list) {

    $table_names_file_name  = $schema + ".txt"
    $tableNameFileWithPath = Join-Path -Path $configFolder  -ChildPath $table_names_file_name
    $table_name_list = Get-Content -Path $tableNameFileWithPath

    foreach($table_name in $table_name_list) {
       
        $table_name = $table_name.Trim();    
        $fileName = $mysqlBackupDateTimePath_finalPath + "\" + $schema + "_" + $table_name + ".sql"
        $fileNameArg = "-r " + $fileName
        $fullTableName = "`"" + $schema + "`" `"" + $table_name + "`""
        $finalCommand = $mysqlDumpCommand, $defaultFileArgs, $hostnamePortString, $characterSetString, $protocolString, $fileNameArg, $userArgs, $fullTableName -join ' '
        Add-Content $logFile_finalPath $finalCommand
        Invoke-Expression $finalCommand
    }
}

$zipFileName = "btct-puru-" + $date + "-" +$time + ".zip"
$ZipFile_FinalPath = Join-Path -Path $mysqlZipBackupRootPath -ChildPath $zipFileName
Compress-Archive -Path $mysqlBackupDateTimePath_finalPath -DestinationPath $ZipFile_FinalPath
