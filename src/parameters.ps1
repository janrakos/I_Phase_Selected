$sourceSystem = "AIA4"

$scriptStartString = "MD_SCRIPT_TIMES.SCRIPT_START"
$scriptEndString = "MD_SCRIPT_TIMES.SCRIPT_END"
$sourceSystemStartString = "source system SourceSystemName script start"
$sourceSystemEndString = "source system SourceSystemName script end"

$ignoreStrings = ""
$copyStrings = "'ID_pkbaux_C_;Source system ENUM"

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