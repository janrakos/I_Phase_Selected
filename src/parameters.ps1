<#### PARAMETERS - for additional info about each parameter check documentation ####>

<## File Processing Parameters ##>
# $sourceSystem parameter can contain one or multiple strings divided by ';',
# source systems matching any of defined strings are kept in file
$sourceSystem = "" 

# $ignoreFileStrings can contain one or multiple strings divided by ';',
# file is skipped in processing when any of defined strings are found in that file
$ignoreFileStrings = "" 

# $copyFileStrings can contain one or multiple strings divided by ';',
# file is copied with whole content to output when any of defined strings are found in that file
$copyFileStrings = ""


<## Folder Management Parameters ##>
$fromOwnInputFolder = $false
$ownInputFolder = ""

$createFilesForIFPC = $false
$IFPCFolder = ""


<## Conversion Parameters ##>
$isConversionWanted = $true
$doOnlyConversion = $false

$ownConfigurationFile = $false
$configurationFile = "ownConfiguration.cfg"

#can contain only values: kpse, kpseuat or dev
$targetEnvironment = "dev"

# setting productionDataLoad parameter to true results in minimized conversion
# converted are only necessary strings such as connections, global temporary tables, error tables and target tables,
# everything else is kept in production state
$productionDataLoad = $false


. "$PSScriptRoot\functions.ps1"
Main