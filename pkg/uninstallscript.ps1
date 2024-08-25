# Define registry paths
$registryEntries = @(".mp4", ".webm", ".mkv")

foreach ($extension in $registryEntries) {
    # Define the registry paths
    $registryPathHKCU = "HKCU:\Software\Classes\SystemFileAssociations\$extension\shell\Discordify"
    $registryPathHKLM = "HKLM:\Software\Classes\SystemFileAssociations\$extension\shell\Discordify"
    
    # Remove registry keys for HKCU
    Remove-Item -Path $registryPathHKCU -Recurse -Force -ErrorAction SilentlyContinue
    
    # Remove registry keys for HKLM
    Remove-Item -Path $registryPathHKLM -Recurse -Force -ErrorAction SilentlyContinue
}

# Remove Discordify directory
$discordifyPath = "$env:APPDATA\Discordify"
if (Test-Path $discordifyPath) {
    Remove-Item -Path $discordifyPath -Recurse -Force
}

Write-Host "Uninstallation complete. 'Discordify' context menu entry removed and folder deleted."
