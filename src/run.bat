echo off
powershell -Command %PMCTLFILEDIR%\ScriptSeparator\src\parameters.ps1
IF %ERRORLEVEL% NEQ 0 Exit 1