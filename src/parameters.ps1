$sourceSystem = "AIA4"

$scriptStartString = "MD_SCRIPT_TIMES.SCRIPT_START"
$scriptEndString = "MD_SCRIPT_TIMES.SCRIPT_END"
$sourceSystemStartString = "source system SourceSystemName script start"
$sourceSystemEndString = "source system SourceSystemName script end"
$ignoreStrings = ""
$copyStrings = "'ID_pkbaux_C_;Source system ENUM"

$copyFromOwnInputFolder = $false
$ownInputFolder = "C:\Users\jrakos\Dropbox\�kola\V�E -In�en�r\Diplomka\code\I_Phase"
$mainFolder = "C:\Users\jrakos\Dropbox\�kola\V�E -In�en�r\Diplomka\code\I_Phase_Selected"

$inputFilesEncoding = "utf8"

. "$mainFolder\src\functions.ps1"
Main