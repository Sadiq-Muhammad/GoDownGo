$BinaryName = "godo"
$InstallDir = "C:\Program Files\godo"
$DownloadUrl = ""

# Get the OS and architecture
$os = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
$arch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture

# Determine the correct binary based on OS and architecture
if ($os -like "*Windows*") {
    if ($arch -eq "X64") {
        $DownloadUrl = "https://github.com/Sadiq-Muhammad/GoDo/blob/master/builds/godo-windows-amd64.exe"  # Replace with actual URL for Windows AMD64
    } elseif ($arch -eq "X86") {
        $DownloadUrl = "https://github.com/Sadiq-Muhammad/GoDo/blob/master/builds/godo-windows-386.exe"  # Replace with actual URL for Windows 32-bit (386)
    }
}

# Ensure directory exists
if (!(Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir | Out-Null
}

# Download the binary if URL is set
if ($DownloadUrl -ne "") {
    Write-Host "Downloading $BinaryName for $os $arch..."
    Invoke-WebRequest -Uri $DownloadUrl -OutFile "$InstallDir\$BinaryName$($os -eq 'windows' ? '.exe' : '')"

    # Add directory to PATH
    $env:Path += ";$InstallDir"
    [System.Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)

    Write-Host "✅ Installation complete! You can now run '$BinaryName' from anywhere."
} else {
    Write-Host "❌ No compatible binary found for $os $arch."
}
