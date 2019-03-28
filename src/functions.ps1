function Main () {
    $ErrorActionPreference = "Stop"
    $mainFolder = Split-Path -Path $PSScriptRoot
    $outputFolder = setupDir "output"
    $logFileFolder = setupDir "log"
    $logFile = createLogFile
    try { #thanks to try we can catch errors and log them in log file 
        validateParameters
        $inputFolder = setupInputDir
        $allFiles = Get-ChildItem -Path $inputFolder | Where-Object { !$_.PSIsContainer } | Sort-Object
        Remove-Item "$outputFolder\*.*"
        if ($isConversionWanted -eq $true -and $doOnlyConversion -eq $true) {
            foreach ($file in $allFiles) {
                copyFileToFolder $file $inputFolder $outputFolder
            }
			logWrite "Scripts were copied from $inputFolder to $outputFolder."
        }
        else {
            $scriptStartString = "MD_SCRIPT_TIMES.SCRIPT_START"
            $scriptEndString = "MD_SCRIPT_TIMES.SCRIPT_END"
            $copyStringsArray = createArrayFromString $copyFileStrings
            $ignoreStringsArray = createArrayFromString $ignoreFileStrings
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
        $outputFiles = Get-ChildItem -Path $outputFolder | Where-Object { !$_.PSIsContainer } | Sort-Object
        if ($isConversionWanted -eq $true) {
            convertFiles $outputFiles
        }
        if ($createFilesForIFPC -eq $true) {
            foreach ($file in $outputFiles) {
                copyFileToFolder $file $outputFolder $IFPCFolder
            }
            logWrite "Files in output folder were succesfully copied to $IFPCFolder."
        }
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        logWrite "ERROR: $ErrorMessage"
        logWrite "Terminating."
    }
}

function setupDir ($dir) {
    if (!(Test-Path "$mainFolder\$dir")) {
        New-Item "$mainFolder\$dir" -itemtype directory
    }
    $settedUpFolder = "$mainFolder\$dir"
    return $settedUpFolder
}

function createLogFile () {
    $Stamp = (Get-Date).toString("dd-MM-yyyy HHmmss")
    $logFileName = "run." + $Stamp -replace " ","."
    $newLogFile = New-Item "$logFileFolder\$logFileName.log" -ItemType file 
    return $newLogFile
}

function logWrite ($message) {
    $Stamp = (Get-Date).toString("dd.MM.yyyy HH:mm:ss")
    Add-Content $logFile -Value "$Stamp     $message"
    Write-Host $message
}

function validateParameters () {
    if (!($fromOwnInputFolder -is [bool])) {
        Set-Variable -Force -Name "fromOwnInputFolder" -Value $false -Scope Global
        logWrite "WARNING: Parametr `$fromOwnInputFolder is not set properly. It's value should be $true or $false. Process will continue with default value, which is $false."
    }
    if (($ownInputFolder -in $null,"" -or !(Test-Path $ownInputFolder)) -and $fromOwnInputFolder -eq $true) {
        throw "Input folder $ownInputFolder does not exist. Please enter a valid path to input directory."
    }
    if (!($isConversionWanted -is [bool])) {
        Set-Variable -Force -Name "isConversionWanted" -Value $true -Scope Global
        logWrite "WARNING: Parametr `$isConversionWanted is not set properly. It's value should be $true or $false. Process will continue with default value, which is $true."
    }
    if (!($doOnlyConversion -is [bool]) -and $isConversionWanted -eq $true) {
        Set-Variable -Force -Name "doOnlyConversion" -Value $false -Scope Global
        logWrite "WARNING: Parametr `$doOnlyConversion is not set properly. It's value have to be $true or $false. Process will continue with default value, which is $false."
    }
    if (($sourceSystem -in $null,"" -or !($SourceSystem -is [string])) -and !($isConversionWanted -eq $true -and $doOnlyConversion -eq $true)) {
        throw "Parametr `$sourceSystem is mandatory and does not have valid value. For possible values check documentation."
    }
    if (!($copyFileStrings -is [string]) -and !($isConversionWanted -eq $true -and $doOnlyConversion -eq $true)) {
        Set-Variable -Force -Name "copyFileStrings" -Value "" -Scope Global
        logWrite "WARNING: Parametr `$copyFileStrings is not set properly. It's value have to be a string. Process will continue with default value, which is empty string."
    }
    if (!($ignoreFileStrings -is [string]) -and !($isConversionWanted -eq $true -and $doOnlyConversion -eq $true)) {
        Set-Variable -Force -Name "ignoreFileStrings" -Value "" -Scope Global
        logWrite "WARNING: Parametr `$ignoreFileStrings is not set properly. It's value have to be a string. Process will continue with default value, which is empty string."
    }
    if (!($createFilesForIFPC -is [bool])) {
        Set-Variable -Force -Name "createFilesForIFPC" -Value $true -Scope Global
        logWrite "WARNING: Parametr `$createFilesForIFPC is not set properly. It's value have to be $true or $false. Process will continue with default value, which is $true."
    }
    if (($IFPCFolder -in $null,"" -or !(Test-Path $IFPCFolder)) -and $createFilesForIFPC -eq $true) {
        throw "IFPC folder $IFPCFolder does not exist. Please enter a valid path to IFPC directory."
    }
    if (!($ownConfigurationFile -is [bool]) -and $isConversionWanted -eq $true) {
        Set-Variable -Force -Name "ownConfigurationFile" -Value $false -Scope Global
        logWrite "WARNING: Parametr `$ownConfigurationFile is not set properly. It's value have to be $true or $false. Process will continue with default value, which is $false."
    }
    if (!(Test-Path "$mainFolder\src\cfg\$configurationFile") -and $isConversionWanted -eq $true -and $ownConfigurationFile -eq $true) {
        throw "Configuration file $configurationFile does not exist. Please enter a valid path to needed configuration file."
    }
    if (!($targetEnvironment.ToLower() -in "dev", "kpse", "kpseuat" ) -and $isConversionWanted -eq $true -and $ownConfigurationFile -eq $false) {
        throw "Parametr `$targetEnvironment is mandatory and does not have valid value. For possible values check documentation."
		Set-Variable -Force -Name "targetEnvironment" -Value "dev" -Scope Global
        logWrite "WARNING: Parametr `$targetEnvironment is not set properly. For possinble values check documentation. Process will continue with default value, which is 'dev'."
    }
    if (!($productionDataLoad -is [bool]) -and $isConversionWanted -eq $true -and $ownConfigurationFile -eq $false) {
        Set-Variable -Force -Name "productionDataLoad" -Value $false -Scope Global
        logWrite "WARNING: Parametr `$productionDataLoad is not set properly. It's value have to be $true or $false. Process will continue with default value, which is $false."
    }
}

function setupInputDir () {
	if ($fromOwnInputFolder -eq $true) {
		$inputFolder = $ownInputFolder
	}
    else {
        $inputFolder = setupDir "input"
    }
    return $inputFolder
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
    Copy-Item "$sourceFolder\$fileName" -Destination $targetFolder
}

function createArrayFromString ($string) {
    $arrayFromString = $string.Split(";",[System.StringSplitOptions]::RemoveEmptyEntries) 
    [int] $arrayCounter = 0
    foreach ($string in $arrayFromString) {
        $arrayFromString[$arrayCounter] = $string.trim()
        $arrayCounter++
    }
    return ,$arrayFromString #quote is important for keeping array data type even when array is empty
}

function isAnyStringFromArrayInFile ($file, $stringArray) {
    if ($stringArray[0] -eq "" -and $stringArray.count -eq 1) {
        return $false
    }
    else {
        foreach ($string in $stringArray)  {
            $searchedString = Get-Content "$inputFolder\$file"  | Select-String $string
            if ($searchedString -ne $null) {
                return $true
            }
        }
        return $false
    }
}

function getRowNumberOfText ($file, $search) {
    $searchedLine = Get-Content "$inputFolder\$file"  | Select-String $search
    if ($searchedLine -eq $null) {
        return $null
    }
    elseif ($searchedLine.count -gt 1) {
        return "MultipleRowsFoundError"
    }
    else {
        $lineNumber = $searchedLine.LineNumber
        return $lineNumber
    }
}

function copyEmptiedFileToFolder ($file, $sourceFolder, $targetFolder) {
    $fileName = $file.Name
    copyFileToFolder $file $sourceFolder $targetFolder
    Clear-Content "$targetFolder\$fileName"
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
        copyEmptiedFileToFolder $file $inputFolder $outputFolder
        logWrite "Any of source systems defined in `$SourceSystem parametr was not found in script $fileName. Content of the file was deleted."
    }
    else {
      # Creating new output file with HEAD of input file
      [System.Collections.ArrayList]$scriptHeadArray = @(Get-Content "$inputFolder\$file" )
      $RowsInFile = $scriptHeadArray.count
      $headEnd = $scriptStart + 1  
      $scriptHeadArray.RemoveRange($headEnd,$RowsInFile - $headEnd)
      Set-Content "$outputFolder/$file" -Value $scriptHeadArray

      # Insering source system/-s to output file
      for ($i=0; $i -lt $SourceSystemStartLineNumbers.count; $i++) {
        [System.Collections.ArrayList]$sourceSystemArray = @(Get-Content "$inputFolder\$file" )
        $count1 = $SourceSystemStartLineNumbers[$i] - 1
        $sourceSystemArray.RemoveRange(0,$count1)
        $arrayLength = $sourceSystemArray.count
        $SrcEnd = $SourceSystemEndLineNumbers[$i] - $count1
        $sourceSystemArray.RemoveRange($SrcEnd,$arrayLength - $SrcEnd)
        Add-Content "$outputFolder/$file" -Value $sourceSystemArray 
      }

      # Insering FOOT from input file to output file
      [System.Collections.ArrayList]$scriptFootArray = @(Get-Content "$inputFolder\$file" )
      $footStart = $scriptEnd - 1
      $scriptFootArray.RemoveRange(0,$footStart)
      Add-Content "$outputFolder/$file" -Value $scriptFootArray 

      logWrite "File $fileName was processed succesfully."
    }
}

function convertFiles ($files) {
    $conversionDefinitionFile = setupConfigurationFile
    $ConvDefFileRows = @(Get-Content $conversionDefinitionFile )
    $patterns = @()
    $replacingStrings = @()
    foreach ($fileRow in $ConvDefFileRows) {
        if ($fileRow -ne "") {
            $separatorIndex = $fileRow.IndexOf("#")
            $fileRowLength = $fileRow.length
            $pattern = $fileRow.Substring(0,$separatorIndex)
            $replacingString = $fileRow.Substring($separatorIndex+1,$fileRowLength-$separatorIndex-1)
            $patterns += $pattern
            $replacingStrings += $replacingString
        }
    }
    foreach ($file in $files) {
        for ($i=0; $i -lt $patterns.count; $i++) {
            replaceStringInFile $file.FullName $patterns[$i] $replacingStrings[$i]
        }
    }
    logWrite "Files in output folder were succesfully converted using configuration file $conversionDefinitionFile."
}

function setupConfigurationFile () {
    if ($ownConfigurationFile -eq $true) {
        return "$mainFolder\src\cfg\$configurationFile"
    }
    else {
        $patternFile = "$mainFolder\src\cfg\defaultConfigurationPattern.cfg"
        $generatedFile = "$mainFolder\src\cfg\generatedConfiguration.cfg"
        Clear-Content $generatedFile
        Get-Content -Path $patternFile  | Set-Content -Path $generatedFile
        replaceStringInFile $generatedFile "\*ENV\*" $targetEnvironment
        if ($productionDataLoad -eq $true) {
            replaceStringInFile $generatedFile "\*TESTLOAD\*.*\n" $null
            foreach ($file in $files) {
                If ((Get-Content $file.FullName) -ne $Null -and $file.Name -like "*_pkbaux_*") {
                    $tableName = $file.Name
                    $tableName = $tableName.Remove(0,10)
                    $tableName = $tableName.Remove($tableName.IndexOf(".txt"),4)
                    Add-Content -Path $generatedFile -Value "pkb_aux\.$tableName#pkb_aux_$targetEnvironment.$tableName" 
                }
            }
        }
        else {
            replaceStringInFile $generatedFile "\*TESTLOAD\*" $null
        }
        (Get-Content $generatedFile ) | ? { -not [String]::IsNullOrWhiteSpace($_) } | Set-Content $generatedFile
        return $generatedFile
    }    
}

function replaceStringInFile ($file, $pattern, $replacingString) {
    ((Get-Content $file -Raw ) -replace $pattern, $replacingString) | Set-Content $file 
}