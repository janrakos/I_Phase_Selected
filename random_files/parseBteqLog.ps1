###################################################################################################
# Name:        parseBteqLog.ps1
# Author:      David Šťastný (e_dstas1)
# Version:     0.2
# Created:     24.01.2014
# Updated:     27.01.2014
#
# Description: Parsování BTEQ logů pro získání počtu insertovaných, updatovaných či 
#              deletovaných řádků per tabulka per statement per skript.
#
# Input:       - název log souboru nebo maska např. *.log
#              - název výstupního CSV souboru
#
# Output:      Výstupní CSV formát neobsahuje hlavičku a má tyto sloupce:
# 
# Date;ScriptName;LineNumber;StatementIndex;DatabaseName;TableName;RowsInserted;RowsUpdated;RowsDeleted;TimeInSeconds
#
#
# TODO
# - zpracování UPDATE statementů
# - zpracování DELETE statementů
# - zpracování explicitních transakcí
#
###################################################################################################

#
# Definice a kontrola vstupních parametrů
#
Param([string]$inputFile, [string]$outputFile)
if (-not ($inputFile)) {
    Write-Host "- missing input file!"
    Write-Host "Usage: parseBteqLog.ps1 input.log output.csv"
    Return
}
if (-not ($outputFile)) {
    Write-Host "- missing output file!"
    Write-Host "Usage: parseBteqLog.ps1 input.log output.csv"
    Return
}


#
# funkce pro zpracování jednoho log souboru
#
Function ParseBteqLogFile([string]$file) {
    Write-Debug "Processing file $file ..."
    
    
    $lines = Get-Content $file
    $script_line = [regex]::match($lines[0], "(\d{4}-\d{2}-\d{2}) .*, script: (\S+)\.txt")
    $current_date = $script_line.Groups[1].Value
    $current_script = $script_line.Groups[2].Value
    
    $line_number = 0
    $current_index = 0
    
    $current_table = ""
    $current_line = 0
    $current_inserted = 0
    
    $lines | ForEach-Object { 
        $line_number++;
        $table_name = ([regex]::matches($_, "insert into (\S+).*") | % { $_.groups | select -index 1 }).Value
        if ($table_name) {
            $current_table = ($table_name -split "\.") -join ";";
            $current_line = $line_number;
            $current_index++;
        }
        
        $insert_row = ([regex]::matches($_, " \*\*\* Insert completed. (No|One|\d+) (row|rows) added.") | % { $_.groups | select -index 1 }).Value
        if ($insert_row) {
            $insert_row = $insert_row -replace "No", 0
            $insert_row = $insert_row -replace "One", 1
            $current_inserted = [int]$insert_row
        }
        
        $seconds_row = ([regex]::matches($_, " \*\*\* Total elapsed time was (\d+) second") | % { $_.groups | select -index 1 }).Value
        if ($seconds_row) {
            if ($current_table -ne "") {
                # výstup v CSV formátu do standardního kanálu
                "$current_date;$current_script;$current_line;$current_index;$current_table;$current_inserted;0;0;$seconds_row" | Out-File -FilePath $outputFile -Append
                
                # vyčistíme proměnné
                $current_line = 0
                $current_table = ""
                $current_inserted = 0;
            }
        }
        
    }
}

#
# hlavní cyklus skriptu
#
Resolve-Path $inputFile | ForEach-Object {
    ParseBteqLogFile $_
}

