﻿$string = ";ggg   ;;hhh"
$arrayFromString = $string.Split(";",[System.StringSplitOptions]::RemoveEmptyEntries) 
[int] $arrayCounter = 0
foreach ($string in $arrayFromString) {
    $arrayFromString[$arrayCounter] = $string.trim()
    $arrayCounter++
}


if (!($arrayFromString[0] -eq "" -and $arrayFromString.count -eq 1)) {
      Write-Host $arrayFromString.count
      Write-Host $arrayFromString[0]
      Write-Host $arrayFromString[1]
      Write-Host $arrayFromString[2]
      Write-Host "process strings"
    }
else {
write-host "nedelej nic"
}


Remove-Item "C:\git\I_Phase_selected\output\*.*"

$string = "ID_pkbaux_C_Adjustment_Type.txt"
$string = $string.Remove(0,10)
$string.IndexOf(".txt")
$string = $string.Remove($string.IndexOf(".txt"),3)