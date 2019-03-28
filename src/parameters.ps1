<#### PARAMETERS - for additional info about each parameter check documentation ####>

<## File Processing Parameters ##>
# $sourceSystem parameter can contain one or multiple strings divided by ';', source systems matching any of defined strings are kept in file  
# All source systems in day load scripts: "AIA;AIA4;API;ATL;RSVVS RSODS;VPL;VVS;ACT;ENUM;01_LIK;LSK;LIK;Max_Sum_Insured;MRE"
$sourceSystem = "AIA" 

#$ignoreFileStrings can contain one or multiple strings divided by ';', file is skipped in processing when any of defined strings are found in that file
$ignoreFileStrings = "'DW_Date_PKB;'IM_;'IQ_;'ID_pkbaux_DM_MSI_Factors" 

#$copyFileStrings can contain one or multiple strings divided by ';', file is copied with whole content to output when any of defined strings are found in that file
$copyFileStrings = ""


<## Folder Management Parameters ##>
$fromOwnInputFolder = $false
$ownInputFolder = ""

$createFilesForIFPC = $false
$IFPCFolder = ""


<## Conversion Parameters ##>
$isConversionWanted = $true
$doOnlyConversion = $false

$ownConfigurationFile = $true
$configurationFile = "ownConfiguration.cfg"

#can contain only values: kpse, kpseuat or dev
$targetEnvironment = "kpse"

#setting productionDataLoad parameter to true results in minimized conversion -> converted are only necessary strings such as connections, global temporary tables, error tables and target tables, everything else is kept in production state
$productionDataLoad = $true


. "$PSScriptRoot\functions.ps1"
Main