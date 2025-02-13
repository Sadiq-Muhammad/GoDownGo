$BinaryName = "godo"
$InstallDir = "$env:USERPROFILE\godo"
$DownloadUrl = ""

# Get Windows architecture using PowerShell-friendly methods
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

# Ensure the install directory exists
if (!(Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir | Out-Null
}

# Download the binary
Write-Host "🚀 Downloading $BinaryName for Windows $arch..."
Invoke-WebRequest -Uri $DownloadUrl -OutFile "$InstallDir\$BinaryName.exe"

# Verify if download was successful
if (!(Test-Path "$InstallDir\$BinaryName.exe")) {
    Write-Host "❌ Download failed. Please check your internet connection."
    exit 1
}

# Add install directory to user PATH permanently
$existingPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
if ($existingPath -notlike "*$InstallDir*") {
    [System.Environment]::SetEnvironmentVariable("Path", "$existingPath;$InstallDir", "User")
    Write-Host "🔗 Added $InstallDir to PATH. You may need to restart your terminal."
}

Write-Host "✅ Installation complete! You can now run '$BinaryName' from anywhere."
