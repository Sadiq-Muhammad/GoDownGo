#!/bin/bash

BinaryName="godo"
InstallDir="/usr/local/bin"
DownloadUrl=""

# Get OS and architecture
os=$(uname -s)
arch=$(uname -m)

# Determine the correct binary based on OS and architecture
if [[ "$os" == "Linux" ]]; then
    if [[ "$arch" == "x86_64" ]]; then
        DownloadUrl="https://github.com/Sadiq-Muhammad/GoDo/builds/godo-linux-amd64"  # Replace with actual URL for Linux AMD64
    elif [[ "$arch" == "armv7l" ]]; then
        DownloadUrl="https://github.com/Sadiq-Muhammad/GoDo/builds/godo-linux-arm"  # Replace with actual URL for Linux ARM
    elif [[ "$arch" == "aarch64" ]]; then
        DownloadUrl="https://github.com/Sadiq-Muhammad/GoDo/builds/godo-linux-arm64"  # Replace with actual URL for Linux ARM64
    fi
elif [[ "$os" == "Darwin" ]]; then  # macOS
    if [[ "$arch" == "x86_64" ]]; then
        DownloadUrl="https://github.com/Sadiq-Muhammad/GoDo/builds/godo-darwin-amd64"  # Replace with actual URL for macOS AMD64
    elif [[ "$arch" == "arm64" ]]; then
        DownloadUrl="https://github.com/Sadiq-Muhammad/GoDo/builds/godo-darwin-arm64"  # Replace with actual URL for macOS ARM64
    fi
elif [[ "$os" == "MINGW"* || "$os" == "CYGWIN"* ]]; then  # Windows (via Git Bash or Cygwin)
    if [[ "$arch" == "x86_64" ]]; then
        DownloadUrl="https://github.com/Sadiq-Muhammad/GoDo/builds/godo-windows-amd64.exe"  # Replace with actual URL for Windows AMD64
    elif [[ "$arch" == "i686" ]]; then
        DownloadUrl="https://github.com/Sadiq-Muhammad/GoDo/builds/godo-windows-386.exe"  # Replace with actual URL for Windows 32-bit
    fi
fi

# Check if the URL is set
if [ -n "$DownloadUrl" ]; then
    echo "Downloading $BinaryName for $os $arch..."
    curl -sSL "$DownloadUrl" -o "$InstallDir/$BinaryName"

    # Make the binary executable (Linux/macOS)
    chmod +x "$InstallDir/$BinaryName"

    echo "✅ Installation complete! You can now run '$BinaryName' from anywhere."
else
    echo "❌ No compatible binary found for $os $arch."
fi
