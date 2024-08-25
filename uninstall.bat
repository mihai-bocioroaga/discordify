@echo off

echo Running uninstall script, removing files from %AppData%\Discordify and removing registry keys...

setlocal

set "PS_SCRIPT_PATH=%~dp0\pkg\uninstallscript.ps1"

powershell -Command "Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%PS_SCRIPT_PATH%\"' -Verb RunAs -Wait"

endlocal

echo Done!

pause