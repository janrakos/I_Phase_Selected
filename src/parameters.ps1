$sourceSystem = "AIA4;ENUM"

$ignoreStrings = ""
$copyStrings = ""

$fromOwnInputFolder = $false
$ownInputFolder = "C:\git\I_Phase"
$createFilesInMainFolder = $true

$inputFilesEncoding = "utf8"

$isConversionWanted = $true
$doOnlyConversion = $false
$ownConversionDefinitionFile = "conversion.cfg"

. "$mainFolder\src\functions.ps1"
Main