$sourceSystem = "AIA4"

$scriptStartString = "MD_SCRIPT_TIMES.SCRIPT_START"
$scriptEndString = "MD_SCRIPT_TIMES.SCRIPT_END"
$sourceSystemStartString = "source system SourceSystemName script start"
$sourceSystemEndString = "source system SourceSystemName script end"
$ignoreStrings = ""
$copyStrings = "'ID_pkbaux_C_;Source system ENUM"

$copyFromOwnInputFolder = $false
$ownInputFolder = "C:\git\I_Phase"
$mainFolder = "C:\git\I_Phase_selected"

$inputFilesEncoding = "utf8"

. "$mainFolder\src\functions.ps1"
Main