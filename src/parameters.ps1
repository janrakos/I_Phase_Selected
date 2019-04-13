<#### PARAMETERS - for additional info about each parameter check documentation ####>

<## File Processing Parameters ##>
#Following parameters can contain one or multiple strings divided by ';'
$sourceSystem = "SourceA;SourceB" 
$ignoreFileStrings = "" 
$copyFileStrings = ""

<## Folder Management Parameters ##>
$fromOwnInputFolder = $false
$ownInputFolder = "Path_To_Own_Input_Folder"
$createFilesForIFPC = $true
$IFPCFolder = "Path_To_IFPC" #this path has to be set correctly for default run

<## Conversion Parameters ##>
$isConversionWanted = $true
$doOnlyConversion = $false
$ownConfigurationFile = $false
$configurationFile = "ownConfiguration.cfg"
$targetEnvironment = "dev" #this parametr can contain only values: dev, test or testuat
$productionDataLoad = $false

. "$PSScriptRoot\functions.ps"
Main
