$BinaryName = "godo.exe"
$InstallDir = "C:\Program Files\godo"

# Ensure directory exists
if (!(Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir | Out-Null
}

# Build the binary
Write-Host "Building $BinaryName..."
go build -o "$InstallDir\$BinaryName"

# Add directory to PATH
$env:Path += ";$InstallDir"
[System.Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)

Write-Host "✅ Installation complete! You can now run '$BinaryName' from anywhere."
