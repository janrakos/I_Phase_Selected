function Main () {
  $ErrorActionPreference = "Stop"
  $mainFolder = "C:\git\I_Phase_selected"
  $outputFolder = setUpDir "output"
  $logFileFolder = setUpDir "log"
  $logFile = createLogFile
  try {
  validateParameters
  $inputFolder = setUpInputDir
  $allFiles = Get-ChildItem -Path $inputFolder | Where-Object { !$_.PSIsContainer } | Sort-Object
  Remove-Item "$outputFolder\*.*"
  if ($isConversionWanted -eq $true -and $doOnlyConversion -eq $true) {
    foreach ($file in $allFiles) {
      copyFileToFolder $file $inputFolder $outputFolder
    }
  }
  else {
    $scriptStartString = "MD_SCRIPT_TIMES.SCRIPT_START"
    $scriptEndString = "MD_SCRIPT_TIMES.SCRIPT_END"
    $copyStringsArray = createArrayFromString $copyStrings
    $ignoreStringsArray = createArrayFromString $ignoreStrings
    foreach ($file in $allFiles) {
      $fileName = $file.Name
      $scriptStart = getRowNumberOfText $file $scriptStartString
      $scriptEnd = getRowNumberOfText $file $scriptEndString
      $isAnyCopyStringInFile = isAnyStringFromArrayInFile $file $copyStringsArray
      $isAnyIgnoreStringInFile = isAnyStringFromArrayInFile $file $ignoreStringsArray
      if ($isAnyIgnoreStringInFile -eq $true) {
        logWrite "Script $fileName contains one or more ignore strings. Script was ignored and was not processed or copied to output."
      }
      elseif ($isAnyCopyStringInFile -eq $true) {
        copyFileToFolder $file $inputFolder $outputFolder
        logWrite "Script $fileName contains one or more copy strings. Script was copied from input folder without processing."
      }
      elseif ($ScriptStart -eq $null -or $ScriptEnd -eq $null -or $scriptStart -eq "MultipleRowsFoundError" -or $scriptEnd -eq "MultipleRowsFoundError") {
        copyFileToFolder $file $inputFolder $outputFolder
        logWrite "WARNING: Problem in finding Start or End of skript $fileName. Script was copied from input folder without processing."
      }
      else {
        processFile $file
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
  logWrite "ERROR: $ErrorMessage"
  logWrite "Terminating."
}
}

function setUpDir ($dir) {
    if (!(Test-Path "$mainFolder\$dir")) {
        New-Item "$mainFolder\$dir" -itemtype directory
    }
    $outputFolder = "$mainFolder\$dir"
    return $outputFolder
}

function setUpInputDir () {
    if ($fromOwnInputFolder -eq $true) {
        $inputFolder = $ownInputFolder
    }
    else {
        $inputFolder = "$mainFolder\input"
    }
    return $inputFolder
}

function validateParameters () {
  if (!($fromOwnInputFolder -is [bool])) {
    throw "Parametr `$fromOwnInputFolder is not set properly. It's value have to be $true or $false."
  }
  if (!(Test-Path $ownInputFolder) -and $fromOwnInputFolder -eq $true) {
    throw "Input folder $ownInputFolder does not exist."
  }
  if (!(Test-Path "$mainFolder\input") -and $fromOwnInputFolder -eq $false) {
    throw "Input folder $mainFolder\input does not exist."
  }
  if ($sourceSystem -in $null,"" -or !($SourceSystem -is [string])) {
    throw "Parametr `$sourceSystem does not have valid value. Check documentation for more information about this parametr."
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

function getRowNumberOfText ($file, $search) {
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

function createFileFromArray ($file, $array, $folder) {
  $fileName = $file.Name
  if ($inputFilesEncoding.ToLower() -eq 'utf8') {
  $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
  [System.IO.File]::WriteAllLines("$folder\$fileName", $array, $Utf8NoBomEncoding)
  }
  else {
  $newFile = New-Item "$folder\$fileName" -ItemType file 
  $array | Out-File $newFile -Encoding $inputFilesEncoding
  }
}

function createArrayFromString ($string) {
    $arrayFromString = $string.Split(";",[System.StringSplitOptions]::RemoveEmptyEntries) 
    [int] $arrayCounter = 0
    foreach ($string in $arrayFromString) {
    $arrayFromString[$arrayCounter] = $string.trim()
    $arrayCounter++
    }
    return ,$arrayFromString #quote is important for keeping array data type when array is empty
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

function processFile ($file) {
    $sourceSystemArray = createArrayFromString $sourceSystem
    $sourceSystemStartString = "source system SourceSystemName script start"
    $sourceSystemEndString = "source system SourceSystemName script end"
    $emptyFileFlag = $true
    $copyFileFlag = $false
    $sourceSystemProcessSuccesFlag = $true
    [System.Collections.ArrayList]$SourceSystemStartLineNumbers = @()
    [System.Collections.ArrayList]$SourceSystemEndLineNumbers = @()
    foreach ($srcSystem in $sourceSystemArray) {
        if ($sourceSystemProcessSuccesFlag -eq $true) {
            $replacedSourceStart = $sourceSystemStartString -replace "SourceSystemName",$srcSystem
            $replacedSourceEnd = $sourceSystemEndString -replace "SourceSystemName",$srcSystem
            $sourceSystemStart = getRowNumberOfText $file $replacedSourceStart
            $sourceSystemEnd = getRowNumberOfText $file $replacedSourceEnd
            if ($SourceSystemStart -eq "MultipleRowsFoundError" -or $sourceSystemEnd -eq "MultipleRowsFoundError") {
                $emptyFileFlag = $false
                $copyFileFlag = $true
                $sourceSystemProcessSuccesFlag = $false
                logWrite "WARNING: Multiple Start or End strings of source system $srcSystem was found in skript $fileName. Script was copied to output folder without processing."
            }
            elseif ($SourceSystemStart -eq $null -and $SourceSystemEnd -eq $null) {
                #do nothing - behavior given by default values in flag parameters is needed
            }
            elseif ($SourceSystemStart -eq $null -or $SourceSystemEnd -eq $null) {
                $emptyFileFlag = $false
                $copyFileFlag = $true
                $sourceSystemProcessSuccesFlag = $false
                logWrite "WARNING: Start or End string of source system $srcSystem is missing in script $fileName. Script was copied to output folder without processing."
            }
            elseif ($sourceSystemStart -gt $sourceSystemEnd) {
                $emptyFileFlag = $false
                $copyFileFlag = $true
                $sourceSystemProcessSuccesFlag = $false
                logWrite "WARNING: Order of Start and End strings of source system $srcSystem in script $fileName is incorrect. Script was copied to output folder without processing."                
            }
            else {
                $emptyFileFlag = $false
                $SourceSystemStartLineNumbers += $sourceSystemStart
                $SourceSystemEndLineNumbers += $sourceSystemEnd
            }
        }
    }
    if ($copyFileFlag -eq $true) {
        copyFileToFolder $file $inputFolder $outputFolder
    }
    elseif ($emptyFileFlag -eq $true) {
        createEmptiedFileInFolder $file $inputFolder $outputFolder
        logWrite "Any of source systems defined in `$SourceSystem parametr was not found in script $fileName. Content of the file was deleted."
    }
    else {
      # Creating new output file with HEAD of input file
      [System.Collections.ArrayList]$scriptHeadArray = @(Get-Content "$inputFolder\$file" -encoding $inputFilesEncoding)
      [int] $RowsInFile = $scriptHeadArray.count
      [int] $headEnd = $scriptStart + 2  
      $scriptHeadArray.RemoveRange($headEnd,$RowsInFile - $headEnd)
      createFileFromArray $file $scriptHeadArray $outputFolder

      # Insering source system/-s to output file
      for ([int]$i=0; $i -lt $SourceSystemStartLineNumbers.count; $i++) {
        [System.Collections.ArrayList]$sourceSystemArray = @(Get-Content "$inputFolder\$file" -encoding $inputFilesEncoding)
        $count1 = $SourceSystemStartLineNumbers[$i] - 1
        $sourceSystemArray.RemoveRange(0,$count1)
        $arrayLength = $sourceSystemArray.count
        $SrcEnd = $SourceSystemEndLineNumbers[$i] - $count1 + 1
        $sourceSystemArray.RemoveRange($SrcEnd,$arrayLength - $SrcEnd)
        Add-Content -Path "$outputFolder/$file" -Value $sourceSystemArray -encoding $inputFilesEncoding
      }

      # Insering FOOT from input file to output file
      [System.Collections.ArrayList]$scriptFootArray = @(Get-Content "$inputFolder\$file" -encoding $inputFilesEncoding)
      [int] $footStart = $scriptEnd - 1
      $scriptFootArray.RemoveRange(0,$footStart)
      Add-Content -Path "$outputFolder/$file" -Value $scriptFootArray -encoding $inputFilesEncoding

      logWrite "File $fileName was processed succesfully."
    }
}

function createLogFile () {
    $Stamp = (Get-Date).toString("dd-MM-yyyy HHmmss")
    $logFileName = "run." + $Stamp -replace " ","."
    $newLogFile = New-Item "$logFileFolder\$logFileName.log" -ItemType file 
    return $newLogFile
}

function logWrite ([string]$message) {
    $Stamp = (Get-Date).toString("dd.MM.yyyy HH:mm:ss")
    Add-Content $logFile -Value "$Stamp     $message"
    Write-Host $message
}

