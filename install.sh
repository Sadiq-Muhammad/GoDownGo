#!/bin/bash
set -e

BINARY_NAME="godo"
INSTALL_DIR="/usr/local/bin"

# Build the binary
echo "Building $BINARY_NAME..."
GOOS=$(uname | tr '[:upper:]' '[:lower:]') GOARCH=amd64 go build -o $BINARY_NAME

# Move binary to /usr/local/bin
echo "Installing $BINARY_NAME to $INSTALL_DIR..."
sudo mv $BINARY_NAME $INSTALL_DIR

# Make executable
sudo chmod +x $INSTALL_DIR/$BINARY_NAME

echo "✅ Installation complete! You can now run '$BINARY_NAME' from anywhere."
