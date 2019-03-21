function Main () {
  $ErrorActionPreference = "Stop"
  try {
  validateParameters
  $outputFolder = "$mainFolder\output"
  if ($fromOwnInputFolder -eq $true) {
    $inputFolder = $ownInputFolder
  }
  else {
    $inputFolder = "$mainFolder\input"
  }
  $logFile = createLogFile
  $allFiles = Get-ChildItem -Path $inputFolder | Where-Object { !$_.PSIsContainer } | Sort-Object
  Remove-Item "$outputFolder\*.*"
  if ($isConversionWanted -eq $true -and $doOnlyConversion -eq $true) {
    foreach ($file in $allFiles) {
      copyFileToFolder $file $inputFolder $outputFolder
    }
  }
  else {
    foreach ($file in $allFiles) {
      $fileName = $file.Name
      $scriptStart = getRowNumberOfText $scriptStartString
      $scriptEnd = getRowNumberOfText $scriptEndString
      $copyStringsArray = createArrayFromString $copyStrings
      $isAnyCopyStringInFile = isAnyStringFromArrayInFile $file $copyStringsArray
      $ignoreStringsArray = createArrayFromString $ignoreStrings
      $isAnyIgnoreStringInFile = isAnyStringFromArrayInFile $file $ignoreStringsArray
      if ($isAnyIgnoreStringInFile -eq $true) {
        logWrite $logFile "Script $fileName contains one or more ignore strings. Script was ignored and was not processed or copied to output."
      }
      elseif ($isAnyCopyStringInFile -eq $true) {
        copyFileToFolder $file $inputFolder $outputFolder
        logWrite $logFile "Script $fileName contains one or more copy strings. Script was copied from input folder without processing."
      }
      elseif ($ScriptStart -eq $null -or $ScriptEnd -eq $null -or $scriptStart -eq "MultipleRowsFoundError" -or $scriptEnd -eq "MultipleRowsFoundError") {
        copyFileToFolder $file $inputFolder $outputFolder
        logWrite $logFile "WARNING: Problem in finding Start or End of skript $fileName. Script was copied from input folder without processing."
      }
      else {
        processFileForOneSourceSystem $file $scriptStart $scriptEnd
      }
    }
  }
  $processedFiles = Get-ChildItem -Path $outputFolder | Where-Object { !$_.PSIsContainer } | Sort-Object
  if ($createFilesInMainFolder -eq $true) {
    foreach ($file in $processedFiles) {
      copyFileToFolder $file $outputFolder $mainFolder
    }
  }
}
Catch {
  $ErrorMessage = $_.Exception.Message
  logWrite $logFile "ERROR: $ErrorMessage"
  logWrite $logFile "Terminating."
}
}

function validateParameters {
  if (!($fromOwnInputFolder -is [bool])) {
    throw "Parametr `$fromOwnInputFolder is not set properly. It's value have to be $true or $false."
  }
  if (!(Test-Path $ownInputFolder) -and $fromOwnInputFolder -eq $true) {
    throw "Input folder $ownInputFolder does not exist."
  }
  if (!(Test-Path "$mainFolder\input") -and $fromOwnInputFolder -eq $false) {
    throw "Input folder $mainFolder\input does not exist."
  }
  if (!(Test-Path "$mainFolder\output")) {
    throw "Main folder $mainFolder\output does not exist."
  }
  if ($sourceSystem -in $null,"" -or !($SourceSystem -is [string])) {
    throw "Parametr `$sourceSystem does not have valid value. Check documentation for more information about this parametr."
  }
  if ($scriptStartString -in $null,"" -or !($scriptStartString -is [string])) {
    throw "Parametr `$scriptStartString does not have valid value. Check documentation for more information about this parametr."
  }
  if ($scriptEndString -in $null,"" -or !($scriptEndString -is [string])) {
    throw "Parametr `$scriptEndString does not have valid value. Check documentation for more information about this parametr."
  }
  if ($sourceSystemStartString -in $null,"" -or !($sourceSystemStartString -like '*SourceSystemName*' -and $sourceSystemStartString -is [string])) {
    throw "Parametr `$sourceSystemStartString does not have valid value. Check documentation for more information about this parametr."
  }
  if ($sourceSystemEndString -in $null,"" -or !($sourceSystemEndString -like '*SourceSystemName*' -and $sourceSystemEndString -is [string])) {
    throw "Parametr `$sourceSystemEndString does not have valid value. Check documentation for more information about this parametr."
  }
  if (!($copyStrings -is [string])) {
    throw "Parametr `$copyStrings does not have valid value. Check documentation for more information about this parametr."
  }
  if (!($ignoreStrings -is [string])) {
    throw "Parametr `$ignoreStrings does not have valid value. Check documentation for more information about this parametr."
  }
  if (!($inputFilesEncoding.ToLower() -in "unknown", "string", "unicode", "bigendianunicode", "utf8", "utf7", "utf32", "ascii", "default", "oem" )) {
    throw "Parametr `$inputFilesEncoding does not have valid value. Check documentation for more information about this parametr."
  }
  if (!($createFilesInMainFolder -is [bool])) {
    throw "Parametr `$createFilesInMainFolder is not set properly. It's value have to be $true or $false."
  }
  if (!($isConversionWanted -is [bool])) {
    throw "Parametr `$isConversionWanted is not set properly. It's value have to be $true or $false."
  }
  if (!($doOnlyConversion -is [bool])) {
    throw "Parametr `$doOnlyConversion is not set properly. It's value have to be $true or $false."
  }
  if (!(Test-Path "$mainFolder\src\cfg\$conversionDefinitionFile") -and $isConversionWanted -eq $true) {
    throw "$conversionDefinitionFile does not exist in configuration folder $mainFolder\src\cfg\ ."
  }
}

function getRowNumberOfText ([string]$search) {
  $searchedLine = Get-Content "$inputFolder\$file" -encoding $inputFilesEncoding | Select-String $search
  if ($searchedLine -eq $null) {
    return $null
  }
  elseif ($searchedLine.count -gt 1) {
    return "MultipleRowsFoundError"
  }
  else {
    [int] $lineNumber = $searchedLine.LineNumber
    return $lineNumber
  }
}

function deleteFilefromFolder ($file, $folder) {
  $fileName = $file.Name
  if (Test-Path "$folder\$fileName") {
    Remove-Item "$folder\$fileName"
  }
}

function copyFileToFolder ($file, $sourceFolder, $targetFolder) {
  $fileName = $file.Name
  deleteFilefromFolder $file $targetFolder
  Copy-Item -Path "$sourceFolder\$fileName" -Destination $targetFolder
}

function createEmptiedFileInFolder ($file, $sourceFolder, $targetFolder) {
    $fileName = $file.Name
    copyFileToFolder $file $sourceFolder $targetFolder
    Clear-Content "$targetFolder\$fileName"
}

function createFileFromArray ($file, [System.Collections.ArrayList]$array) {
  $fileName = $file.Name
  if ($inputFilesEncoding.ToLower() -eq 'utf8') {
  $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
  [System.IO.File]::WriteAllLines("$outputFolder\$fileName", $array, $Utf8NoBomEncoding)
  }
  else {
  $newFile = New-Item "$outputFolder\$fileName" -ItemType file 
  $array | Out-File $newFile -Encoding $inputFilesEncoding
  }
}

function createArrayFromString ([string]$string) {
    $arrayFromString = $string.Split(";",[System.StringSplitOptions]::RemoveEmptyEntries) 
    [int] $arrayCounter = 0
    foreach ($string in $arrayFromString) {
    $arrayFromString[$arrayCounter] = $string.trim()
    $arrayCounter++
    }
    return ,$arrayFromString
}

function isAnyStringFromArrayInFile ($file, $stringArray) {
    if ($stringArray[0] -eq "" -and $stringArray.count -eq 1) {
        return $false
    }
    else {
    foreach ($string in $stringArray)  {
    $searchedString = Get-Content "$inputFolder\$file" -encoding $inputFilesEncoding | Select-String $string
    if ($searchedString -ne $null) {
        return $true
    }
    }
    return $false
    }
}

function processFileForOneSourceSystem ($file, [int]$scriptStart, [int]$scriptEnd) {    $replacedSourceStart = $sourceSystemStartString -replace "SourceSystemName",$sourceSystem
    $replacedSourceEnd = $sourceSystemEndString -replace "SourceSystemName",$sourceSystem
    $sourceSystemStart = getRowNumberOfText $replacedSourceStart
    $sourceSystemEnd = getRowNumberOfText $replacedSourceEnd
    if ($SourceSystemStart -eq "MultipleRowsFoundError" -or $sourceSystemEnd -eq "MultipleRowsFoundError") {
      copyFileToFolder $file $inputFolder $outputFolder
      logWrite $logFile "WARNING: Multiple Start or End strings of source system $SourceSystem was found in skript $fileName. Script was copied to output folder without processing."
    }
    elseif ($SourceSystemStart -eq $null -and $SourceSystemEnd -eq $null) {
      createEmptiedFileInFolder $file $inputFolder $outputFolder
      logWrite $logFile "Source system $SourceSystem was not found in script $fileName. Content of the file was deleted."
    }
    elseif ($SourceSystemStart -eq $null -or $SourceSystemEnd -eq $null) {
      copyFileToFolder $file $inputFolder $outputFolder
      logWrite $logFile "WARNING: Start or End string of source system $SourceSystem is missing in script $fileName. Script was copied to output folder without processing."
    }
    else {
      [System.Collections.ArrayList]$arrayFromFile = @(Get-Content "$inputFolder\$file" -encoding $inputFilesEncoding)
      $startfrom1 = $scriptStart + 1
      $count1 = $sourceSystemStart - $startfrom1 - 1
      $startFrom2 = $sourceSystemEnd - $count1
      $count2 = $scriptEnd - $sourceSystemEnd - 1
      $arrayFromFile.removeRange($startfrom1,$count1)
      $arrayFromFile.removeRange($startFrom2,$count2)
      createFileFromArray $file $arrayFromFile
      logWrite $logFile "File $fileName was processed succesfully."
    }
}

function processFileForMultipleSourceSystems  {

}

function createLogFile {
    $logFileDir = "$mainFolder\log"
    $Stamp = (Get-Date).toString("dd-MM-yyyy HHmmss")
    $logFileName = "run." + $Stamp -replace " ","."
    $newLogFile = New-Item "$logFileDir\$logFileName.log" -ItemType file 
    return $newLogFile
}

function logWrite ($logFile, [string]$message) {
    Add-Content $logFile -Value $message
    Write-Host $message
}

