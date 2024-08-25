@echo off

echo Running install script, adding files into %AppData%\Discordify and setting registry keys...

setlocal

:: Define the PowerShell script path
set "PS_SCRIPT_PATH=%~dp0\pkg\installscript.ps1"

:: Use PowerShell to start the script with elevated permissions
powershell -Command "Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%PS_SCRIPT_PATH%\"' -Verb RunAs -Wait"

endlocal

echo Done!

pause
