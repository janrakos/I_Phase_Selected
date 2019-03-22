$sourceSystem = "AIA4;ENUM;AIA"

$ignoreStrings = ""
$copyStrings = "" #"'ID_pkbaux_C_;Source system ENUM"

$fromOwnInputFolder = $false
$ownInputFolder = "C:\git\I_Phase"
$mainFolder = "C:\git\I_Phase_selected"
$createFilesInMainFolder = $true

$inputFilesEncoding = "utf8"

$isConversionWanted = $true
$doOnlyConversion = $false
$conversionDefinitionFile = "conversion.cfg"

. "$mainFolder\src\functions.ps1"
Main