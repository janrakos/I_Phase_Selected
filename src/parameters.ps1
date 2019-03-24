<#### PARAMETERS - for additional info about each parameter check documentation ####>

<## File Processing Parameters ##>
# $sourceSystem parameter can contain one or multiple strings divided by ';', source systems matching any of defined strings are kept in file  
$sourceSystem = "AIA4  ;ENUM;  AIA  " 

#$ignoreFileStrings can contain one or multiple strings divided by ';', file is skipped in processing when any of defined strings are found in that file
$ignoreFileStrings = "" 

#$copyFileStrings can contain one or multiple strings divided by ';', file is copied with whole content to output when any of defined strings are found in that file
$copyFileStrings = ""


<## Folder Management Parameters ##>
#base folder with needed subfolders and files
$mainFolder = "C:\git\I_Phase_selected" 

$fromOwnInputFolder = $false
$ownInputFolder = "C:\git\I_Phase"

$createFilesForIFPC = $true
$IFPCFolder = "$mainFolder"


<## Conversion Parameters ##>
$isConversionWanted = $true
$doOnlyConversion = $false

$ownConfigurationFile = $false
$configurationFile = "$mainFolder\src\cfg\ownConfiguration.cfg"

#can contain only values: kpse, kpseuat or dev
$targetEnvironment = "kpse"

#setting productionDataLoad parameter to true results in minimized conversion -> converted are only necessary strings such as connections, global temporary tables, error tables and target tables, everything else is kept in production state
$productionDataLoad = $true


. "$mainFolder\src\functions.ps1"
Main