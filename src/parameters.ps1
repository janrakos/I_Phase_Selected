<## PARAMETERS - for additional info about each parameter check documentation ##>

<# File Processing Parameters #>
$sourceSystem = "AIA4;ENUM"
$ignoreStrings = ""
$copyStrings = ""
$inputFilesEncoding = "utf8"


<# Folder Management Parameters #>
$mainFolder = "C:\git\I_Phase_selected" # base folder with needed subfolders and files
$fromOwnInputFolder = $false
$ownInputFolder = "C:\git\I_Phase"
$createFilesForIFPC = $true
$IFPCFolder = "C:\git\I_Phase_Selected"


<# Conversion Parameters #>
$isConversionWanted = $true
$doOnlyConversion = $false
$targetEnvironment = ""
$productionDataLoad = $false
$ownConversionDefinitionFile = $false
$ConversionDefinitionFile = ""


. "$mainFolder\src\functions.ps1"
Main