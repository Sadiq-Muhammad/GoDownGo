#!/bin/bash
set -x

BinaryName="godo"
DefaultInstallDir="/usr/local/bin"
MingwInstallDir="$HOME/bin"  # Windows Git Bash installs in home directory
DownloadUrl=""

# Detect OS and architecture
os=$(uname -s)
arch=$(uname -m)

# Normalize OS names
case "$os" in
    Linux) os="linux" ;;
    Darwin) os="darwin" ;;
    MINGW*|CYGWIN*) os="windows" ;;
    *) echo "❌ Unsupported OS: $os"; exit 1 ;;
esac

# Normalize architecture names
case "$arch" in
    x86_64) arch="amd64" ;;
    i686|i386) arch="386" ;;
    armv7l) arch="arm" ;;
    aarch64) arch="arm64" ;;
    mips) arch="mips" ;;
    mips64) arch="mips64" ;;
    mips64le) arch="mips64le" ;;
    mipsle) arch="mipsle" ;;
    ppc64) arch="ppc64" ;;
    ppc64le) arch="ppc64le" ;;
    *) echo "❌ Unsupported architecture: $arch"; exit 1 ;;
esac

# Determine the correct binary URL
DownloadUrl="https://github.com/Sadiq-Muhammad/GoDo/raw/master/builds/godo-${os}-${arch}"
[ "$os" = "windows" ] && DownloadUrl+=".exe"  # Append .exe for Windows

# Set installation directory
if [ "$os" = "windows" ]; then
    InstallDir="$MingwInstallDir"
else
    InstallDir="$DefaultInstallDir"
fi

# Ensure the install directory exists
sudo mkdir -p "$InstallDir"

# Download the binary
echo "🚀 Downloading $BinaryName for $os-$arch..."
if command -v curl >/dev/null 2>&1; then
    curl -sSL "$DownloadUrl" -o "$InstallDir/$BinaryName"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$DownloadUrl" -O "$InstallDir/$BinaryName"
else
    echo "❌ Error: curl or wget is required to download files."
    exit 1
fi

# Ensure download was successful
if [ ! -f "$InstallDir/$BinaryName" ]; then
    echo "❌ Download failed. Please check your internet connection."
    exit 1
fi

# Make the binary executable (not needed on Windows)
if [ "$os" != "windows" ]; then
    sudo chmod +x "$InstallDir/$BinaryName"
fi

# Display completion message
echo "✅ Installation complete! You can now run '$BinaryName' from anywhere."
