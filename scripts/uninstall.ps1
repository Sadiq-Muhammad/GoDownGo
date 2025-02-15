$BinaryName = "gxsh"
$InstallDir = "$env:USERPROFILE\gxsh"

# Check if the installation directory exists
if (Test-Path $InstallDir) {
    Write-Host "🗑 Removing $BinaryName installation directory..."
    Remove-Item -Recurse -Force $InstallDir
    Write-Host "✅ $BinaryName has been uninstalled."
} else {
    Write-Host "⚠ $BinaryName is not installed. No action needed."
}

# Remove install directory from user PATH
$existingPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
if ($existingPath -like "*$InstallDir*") {
    $newPath = ($existingPath -split ";" | Where-Object { $_ -ne $InstallDir }) -join ";"
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "🔗 Removed $InstallDir from PATH. You may need to restart your terminal."
} else {
    Write-Host "ℹ $InstallDir was not found in PATH."
}

Write-Host "🎉 Uninstallation completed successfully."
