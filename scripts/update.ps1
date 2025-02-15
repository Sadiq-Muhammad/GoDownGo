$BinaryName = "godo"
$InstallDir = "$env:USERPROFILE\godo"
$DownloadUrl = ""

# Get Windows architecture
$arch = $env:PROCESSOR_ARCHITECTURE

# Determine the correct binary based on architecture
if ($arch -eq "AMD64") {
    $DownloadUrl = "https://github.com/Sadiq-Muhammad/GoDo/raw/master/builds/godo-windows-amd64.exe"
} elseif ($arch -eq "x86") {
    $DownloadUrl = "https://github.com/Sadiq-Muhammad/GoDo/raw/master/builds/godo-windows-386.exe"
} elseif ($arch -eq "ARM") {
    $DownloadUrl = "https://github.com/Sadiq-Muhammad/GoDo/raw/master/builds/godo-windows-arm.exe"
} elseif ($arch -eq "ARM64") {
    $DownloadUrl = "https://github.com/Sadiq-Muhammad/GoDo/raw/master/builds/godo-windows-arm64.exe"
} else {
    Write-Host "❌ Unsupported architecture: $arch"
    exit 1
}

# Ensure install directory exists
if (!(Test-Path $InstallDir)) {
    Write-Host "⚠️ Installation directory not found. Run the install script first."
    exit 1
}

# Backup existing binary
if (Test-Path "$InstallDir\$BinaryName.exe") {
    Move-Item "$InstallDir\$BinaryName.exe" "$InstallDir\$BinaryName.bak" -Force
}

# Download the latest version
Write-Host "🚀 Updating $BinaryName for Windows $arch..."
Invoke-WebRequest -Uri $DownloadUrl -OutFile "$InstallDir\$BinaryName.exe"

# Verify if update was successful
if (!(Test-Path "$InstallDir\$BinaryName.exe")) {
    Write-Host "❌ Update failed. Restoring previous version."
    Move-Item "$InstallDir\$BinaryName.bak" "$InstallDir\$BinaryName.exe" -Force
    exit 1
} else {
    Remove-Item "$InstallDir\$BinaryName.bak" -Force -ErrorAction SilentlyContinue
}

Write-Host "✅ Update complete! You are now running the latest version of godo."
