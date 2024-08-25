setlocal

set "PS_SCRIPT_PATH=%AppData%\Discordify\discordify.ps1"
set "PS_ARGS=%*"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT_PATH%" %PS_ARGS%

pause

endlocal
