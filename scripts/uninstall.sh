#!/bin/bash

BinaryName="gxsh"
DefaultInstallDir="/usr/local/bin"
MingwInstallDir="$HOME/bin"  # Windows Git Bash installs in home directory

# Detect OS
os=$(uname -s)
case "$os" in
    Linux) os="linux" ;;
    Darwin) os="darwin" ;;
    MINGW*|CYGWIN*) os="windows" ;;
    *) echo "❌ Unsupported OS: $os"; exit 1 ;;
esac

# Set installation directory
if [ "$os" = "windows" ]; then
    InstallDir="$MingwInstallDir"
else
    InstallDir="$DefaultInstallDir"
fi

# Remove the binary if it exists
if [ -f "$InstallDir/$BinaryName" ]; then
    echo "🗑 Removing $BinaryName..."
    rm -f "$InstallDir/$BinaryName"
    echo "✅ $BinaryName has been uninstalled."
else
    echo "⚠ $BinaryName is not installed in $InstallDir."
fi

echo "🎉 Uninstallation completed successfully."
