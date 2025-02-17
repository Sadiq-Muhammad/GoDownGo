#!/bin/bash

# Combined installation manager for gxsh
BinaryName="gxsh"
DefaultInstallDir="/usr/local/bin"
MingwInstallDir="$HOME/bin"
DownloadBase="https://github.com/Sadiq-Muhammad/gxsh/raw/master/builds"
Version="0.0.2"

# Colors and animations
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'
SPINNER=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

# Animation functions
spinner() {
    local pid=$1
    local message=$2
    local delay=0.1
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${SPINNER[i]} $message"
        i=$(( (i+1) % 10 ))
        sleep "$delay"
    done
    printf "\r\033[K"
}

show_header() {
    clear
    echo -e "${CYAN}"
    echo "   ██████  ██   ██ ███████ ██   ██ "
    echo "  ██    ██ ╚██ ██  ██      ██   ██ "
    echo "  ██    ██  ╚███   ███████ ███████ "
    echo "  ██    ██  ██ ██       ██ ██   ██ "
    echo "   ██████  ██   ██ ███████ ██   ██ "
    echo -e "${NC}"
    echo -e "${YELLOW}╔════════════════════════════════════════╗"
    echo -e "║              GXSH v$Version               ║"
    echo -e "╚════════════════════════════════════════╝${NC}"
    echo
}

detect_platform() {
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    case "$os" in
        linux*) os="linux" ;;
        darwin*) os="darwin" ;;
        mingw*|cygwin*) os="windows" ;;
        *) echo -e "${RED}❌ Unsupported OS: $os${NC}"; exit 1 ;;
    esac

    arch=$(uname -m)
    case "$arch" in
        x86_64) arch="amd64" ;;
        i?86) arch="386" ;;
        armv*) arch="arm" ;;
        aarch64) arch="arm64" ;;
        *) echo -e "${RED}❌ Unsupported architecture: $arch${NC}"; exit 1 ;;
    esac

    [ "$os" = "windows" ] && BinaryName+=".exe"
}

set_install_dir() {
    if [ "$os" = "windows" ]; then
        InstallDir="$MingwInstallDir"
    else
        InstallDir="$DefaultInstallDir"
    fi
    mkdir -p "$InstallDir"
}

download_binary() {
    local url="$DownloadBase/gxsh-${os}-${arch}"
    [ "$os" = "windows" ] && url+=".exe"

    echo -e "${BLUE}🌐 Downloading binary...${NC}"
    if command -v curl &>/dev/null; then
        curl -sSL "$url" -o "$InstallDir/$BinaryName" &
    else
        wget -q "$url" -O "$InstallDir/$BinaryName" &
    fi
    local pid=$!
    spinner "$pid" "Downloading"
    wait "$pid"

    if [ ! -f "$InstallDir/$BinaryName" ]; then
        echo -e "${RED}❌ Download failed${NC}"
        exit 1
    fi
}

install() {
    echo -e "${YELLOW}🚀 Starting installation...${NC}"
    detect_platform
    set_install_dir
    
    if [ -f "$InstallDir/$BinaryName" ]; then
        echo -e "${YELLOW}⚠ Binary already exists. Use update instead.${NC}"
        return 1
    fi

    download_binary
    
    if [ "$os" != "windows" ]; then
        chmod +x "$InstallDir/$BinaryName"
    fi

    echo -e "${GREEN}✅ Installation complete!${NC}"
    echo -e "Add ${CYAN}$InstallDir${NC} to your PATH if needed"
    read -n 1 -s -r -p "Press any key to continue..." </dev/tty
    echo
}

update() {
    echo -e "${YELLOW}🔄 Starting update...${NC}"
    detect_platform
    set_install_dir

    if [ ! -f "$InstallDir/$BinaryName" ]; then
        echo -e "${RED}❌ Binary not found. Install first.${NC}"
        return 1
    fi

    BackupFile="$InstallDir/${BinaryName}.bak"
    mv "$InstallDir/$BinaryName" "$BackupFile"
    
    download_binary

    if [ ! -s "$InstallDir/$BinaryName" ]; then
        echo -e "${RED}❌ Update failed, restoring backup${NC}"
        mv "$BackupFile" "$InstallDir/$BinaryName"
        return 1
    fi

    rm -f "$BackupFile"

    echo -e "${GREEN}✅ Update successful!${NC}"
    read -n 1 -s -r -p "Press any key to continue..." </dev/tty
    echo
}

uninstall() {
    echo -e "${YELLOW}🗑 Starting uninstall...${NC}"
    detect_platform
    set_install_dir

    if [ -f "$InstallDir/$BinaryName" ]; then
        rm -f "$InstallDir/$BinaryName"
        echo -e "${GREEN}✅ Uninstall complete!${NC}"
    else
        echo -e "${YELLOW}⚠ Binary not found in $InstallDir${NC}"
    fi
    read -n 1 -s -r -p "Press any key to continue..." </dev/tty
    echo
}

main_menu() {
    show_header
    while true; do
        echo -e "${CYAN}1. Install GXSH"
        echo -e "${GREEN}2. Update GXSH"
        echo -e "${RED}3. Uninstall GXSH"
        echo -e "${BLUE}4. Exit${NC}"
        echo
        read -rp "Choose an option (1-4): " choice </dev/tty

        case $choice in
            1) install ;;
            2) update ;;
            3) uninstall ;;
            4) echo -e "${CYAN}👋 Goodbye!${NC}"; exit 0 ;;
            *) 
                echo -e "${RED}❌ Invalid option${NC}"
                read -n 1 -s -r -p "Press any key to continue..." </dev/tty
                echo
                ;;
        esac
    done
}


# Main execution
trap "echo -e '\n${RED}❌ Operation cancelled${NC}'; exit 1" SIGINT
main_menu