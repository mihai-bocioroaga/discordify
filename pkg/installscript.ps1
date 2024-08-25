# Define paths
$sourcePath = ".\src"
$destinationPath = "$env:APPDATA\Discordify"
$registryEntries = @(".mp4", ".webm", ".mkv")

# Ensure the script is running in its own directory
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -Path $scriptDirectory

# Copy files to %AppData%
if (-not (Test-Path $destinationPath)) {
    New-Item -Path $destinationPath -ItemType Directory | Out-Null
}
Copy-Item -Path "$sourcePath\*" -Destination $destinationPath -Recurse -Force

# Define registry path and command
$batchFilePath = "`"$destinationPath\run.bat`" `"%1`""

foreach ($extension in $registryEntries) {
    # Define the registry path
    $registryPathHKCU = "HKCU:\Software\Classes\SystemFileAssociations\$extension\shell\Discordify"
    
    # Create registry keys and set values for HKCU
    New-Item -Path $registryPathHKCU -Force | Out-Null
    New-Item -Path "$registryPathHKCU\command" -Force | Out-Null
    Set-ItemProperty -Path $registryPathHKCU -Name "(Default)" -Value "Discordify"
    Set-ItemProperty -Path "$registryPathHKCU\command" -Name "(Default)" -Value $batchFilePath
}

Write-Host "Installation complete. 'Discordify' context menu entry added for .mp4, .webm, and .mkv files."
