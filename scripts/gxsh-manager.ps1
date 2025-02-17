<#
.SYNOPSIS
GXSH Manager - Combined installation manager for Windows

.DESCRIPTION
Provides interactive installation, update, and uninstallation of gxsh
#>

# Set console encoding to UTF-8 to support Unicode characters
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Version = "0.0.2-"
$BinaryName = "gxsh"
$InstallDir = "$env:USERPROFILE\gxsh"
$BaseUrl = "https://github.com/Sadiq-Muhammad/gxsh/raw/master/builds"

# Detect architecture correctly
$Arch = switch -Wildcard ((Get-WmiObject Win32_ComputerSystem).SystemType) {
    "*x64*"      { "AMD64" }
    "*x86*"      { "386" }
    "*ARM64*"    { "ARM64" }
    "*ARM*"      { "ARM" }
    default      { $env:PROCESSOR_ARCHITECTURE }
}

# ANSI color codes (only enable if terminal supports it)
if ($Host.UI.SupportsVirtualTerminal) {
    $ESC = [char]27
    $RED = "$ESC[91m"
    $GREEN = "$ESC[92m"
    $YELLOW = "$ESC[93m"
    $BLUE = "$ESC[94m"
    $MAGENTA = "$ESC[95m"
    $CYAN = "$ESC[96m"
    $RESET = "$ESC[0m"
} else {
    # Fallback to no colors
    $RED = $GREEN = $YELLOW = $BLUE = $MAGENTA = $CYAN = $RESET = ""
}

function Show-Header {
    Clear-Host
    Write-Host @"
${CYAN}
   ██████  ██   ██ ███████ ██   ██
  ██    ██ ╚██ ██╔╝██      ██   ██
  ██    ██  ╚███╔╝ ███████ ███████
  ██    ██  ██ ██║      ██ ██   ██
   ██████  ██   ██ ███████ ██   ██
${RESET}
${YELLOW}╔════════════════════════════════════════╗
║            Version $Version              ║
╚════════════════════════════════════════╝${RESET}

"@
}

function Invoke-Spinner {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        [string]$Message = "Processing",
        [array]$ArgumentList = @()
    )
    
    $spinner = @('|', '/', '-', '\')
    $cursorPos = $Host.UI.RawUI.CursorPosition
    $job = Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
    
    while ($job.State -eq 'Running') {
        foreach ($char in $spinner) {
            Write-Host "`r${YELLOW}[$char]${RESET} $Message" -NoNewline
            Start-Sleep -Milliseconds 100
        }
    }
    
    $Host.UI.RawUI.CursorPosition = $cursorPos
    Write-Host (" " * ($Message.Length + 6)) -NoNewline
    $Host.UI.RawUI.CursorPosition = $cursorPos
    
    $result = Receive-Job $job
    Remove-Job $job -Force
    return $result
}

function Get-DownloadUrl {
    param($Arch)
    
    switch ($Arch) {
        "AMD64"   { return "$BaseUrl/gxsh-windows-amd64.exe" }
        "386"     { return "$BaseUrl/gxsh-windows-386.exe" }
        "ARM"     { return "$BaseUrl/gxsh-windows-arm.exe" }
        "ARM64"   { return "$BaseUrl/gxsh-windows-arm64.exe" }
        default   { throw "${RED}Unsupported architecture: $Arch${RESET}" }
    }
}

function Install-GXSH {
    Show-Header
    Write-Host "${BLUE}[*] Starting installation...${RESET}"
    
    try {
        # Create installation directory
        Invoke-Spinner -Message "Creating directory" -ArgumentList $InstallDir -ScriptBlock {
            param($dir)
            if (-not (Test-Path $dir)) {
                New-Item -Path $dir -ItemType Directory | Out-Null
            }
        }

        # Download binary
        $url = Get-DownloadUrl $Arch
        Invoke-Spinner -Message "Downloading binary" -ArgumentList $url, $InstallDir, $BinaryName -ScriptBlock {
            param($u, $dir, $name)
            Invoke-WebRequest -Uri $u -OutFile "$dir\$name.exe" -UseBasicParsing
        }

        # Update PATH
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($currentPath -notmatch [regex]::Escape($InstallDir)) {
            Invoke-Spinner -Message "Updating PATH" -ArgumentList $currentPath, $InstallDir -ScriptBlock {
                param($path, $dir)
                [Environment]::SetEnvironmentVariable("Path", "$path;$dir", "User")
            }
        }

        Write-Host "${GREEN}[√] Installation complete!${RESET}"
        Write-Host "${CYAN}Note: Restart your terminal for PATH changes to take effect${RESET}"
    }
    catch {
        Write-Host "${RED}[X] Installation failed: $($_.Exception.Message)${RESET}"
    }
}

function Update-GXSH {
    Show-Header
    Write-Host "${YELLOW}[*] Starting update...${RESET}"
    
    try {
        if (-not (Test-Path "$InstallDir\$BinaryName.exe")) {
            throw "gxsh not installed. Please install first."
        }

        # Backup existing binary
        Invoke-Spinner -Message "Creating backup" -ArgumentList $InstallDir, $BinaryName -ScriptBlock {
            param($dir, $name)
            Copy-Item "$dir\$name.exe" "$dir\$name.bak" -Force
        }

        # Download update
        $url = Get-DownloadUrl $Arch
        Invoke-Spinner -Message "Downloading update" -ArgumentList $url, $InstallDir, $BinaryName -ScriptBlock {
            param($u, $dir, $name)
            Invoke-WebRequest -Uri $u -OutFile "$dir\$name.exe" -UseBasicParsing
        }

        # Verify update
        if (-not (Test-Path "$InstallDir\$BinaryName.exe")) {
            throw "Download failed"
        }

        Invoke-Spinner -Message "Cleaning up" -ArgumentList $InstallDir, $BinaryName -ScriptBlock {
            param($dir, $name)
            Remove-Item "$dir\$name.bak" -Force -ErrorAction SilentlyContinue
        }

        Write-Host "${GREEN}[√] Update successful!${RESET}"
    }
    catch {
        Write-Host "${RED}[X] Update failed: $($_.Exception.Message)${RESET}"
        if (Test-Path "$InstallDir\$BinaryName.bak") {
            Write-Host "${YELLOW}[*] Restoring previous version${RESET}"
            Move-Item "$InstallDir\$BinaryName.bak" "$InstallDir\$BinaryName.exe" -Force
        }
    }
}

function Uninstall-GXSH {
    Show-Header
    Write-Host "${RED}[*] Starting uninstall...${RESET}"
    
    try {
        # Remove installation directory
        if (Test-Path $InstallDir) {
            Invoke-Spinner -Message "Removing files" -ArgumentList $InstallDir -ScriptBlock {
                param($dir)
                Remove-Item $dir -Recurse -Force -ErrorAction Stop
            }
        }

        # Update PATH
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($currentPath -match [regex]::Escape($InstallDir)) {
            Invoke-Spinner -Message "Updating PATH" -ArgumentList $currentPath, $InstallDir -ScriptBlock {
                param($path, $dir)
                $newPath = ($path -split ';' | Where-Object { $_ -ne $dir }) -join ';'
                [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            }
        }

        Write-Host "${GREEN}[√] Uninstall completed!${RESET}"
    }
    catch {
        Write-Host "${RED}[X] Uninstall failed: $($_.Exception.Message)${RESET}"
    }
}

function Show-MainMenu {
    do {
        Show-Header
        Write-Host "${CYAN}1. Install gxsh"
        Write-Host "${GREEN}2. Update gxsh"
        Write-Host "${RED}3. Uninstall gxsh"
        Write-Host "${BLUE}4. Exit${RESET}"
        $choice = Read-Host "`nSelect an option (1-4)"

        switch ($choice) {
            '1' { Install-GXSH }
            '2' { Update-GXSH }
            '3' { Uninstall-GXSH }
            '4' { 
                Write-Host "${CYAN}[*] Goodbye!${RESET}"
                return 
            }
            default { Write-Host "${RED}[!] Invalid selection${RESET}" }
        }

        if ($choice -in 1..3) {
            Read-Host "`nPress Enter to continue..."
        }
    } while ($true)
}

# Main execution
try {
    Show-MainMenu
}
catch {
    Write-Host "${RED}[X] An error occurred: $($_.Exception.Message)${RESET}"
}