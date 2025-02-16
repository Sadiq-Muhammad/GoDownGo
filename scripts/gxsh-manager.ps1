<#
.SYNOPSIS
GXSH Manager - Combined installation manager for Windows

.DESCRIPTION
Provides interactive installation, update, and uninstallation of gxsh
#>

$Version = "0.0.2-"
$BinaryName = "gxsh"
$InstallDir = "$env:USERPROFILE\gxsh"
$BaseUrl = "https://github.com/Sadiq-Muhammad/gxsh/raw/master/builds"
$Arch = $env:PROCESSOR_ARCHITECTURE

# ANSI color codes
$ESC = [char]27
$RED = "$ESC[91m"
$GREEN = "$ESC[92m"
$YELLOW = "$ESC[93m"
$BLUE = "$ESC[94m"
$MAGENTA = "$ESC[95m"
$CYAN = "$ESC[96m"
$RESET = "$ESC[0m"

function Show-Header {
    Clear-Host
    Write-Host @"
    
${CYAN}   ██████  ██   ██ ███████ ██   ██ 
  ██    ██ ╚██ ██  ██      ██   ██ 
  ██    ██  ╚███   ███████ ███████ 
  ██    ██  ██ ██       ██ ██   ██ 
   ██████  ██   ██ ███████ ██   ██ 
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
        [string]$Message = "Processing"
    )
    
    $spinner = @('|', '/', '-', '\')
    $cursorPos = $Host.UI.RawUI.CursorPosition
    $job = Start-Job -ScriptBlock $ScriptBlock
    
    while ($job.State -eq 'Running') {
        foreach ($char in $spinner) {
            Write-Host "`r${YELLOW}[$char]${RESET} $Message" -NoNewline
            Start-Sleep -Milliseconds 100
        }
    }
    
    $Host.UI.RawUI.CursorPosition = $cursorPos
    Write-Host (" " * ($Message.Length + 6)) -NoNewline
    $Host.UI.RawUI.CursorPosition = $cursorPos
    
    return Receive-Job $job
}

function Get-DownloadUrl {
    switch ($Arch) {
        "AMD64"   { return "$BaseUrl/gxsh-windows-amd64.exe" }
        "x86"     { return "$BaseUrl/gxsh-windows-386.exe" }
        "ARM"     { return "$BaseUrl/gxsh-windows-arm.exe" }
        "ARM64"   { return "$BaseUrl/gxsh-windows-arm64.exe" }
        default   { throw "${RED}Unsupported architecture: $Arch${RESET}" }
    }
}

function Install-GXSH {
    Show-Header
    Write-Host "${BLUE}🚀 Starting installation...${RESET}"
    
    try {
        # Create installation directory
        Invoke-Spinner -Message "Creating directory" -ScriptBlock {
            if (-not (Test-Path $InstallDir)) {
                New-Item -Path $InstallDir -ItemType Directory | Out-Null
            }
        }

        # Download binary
        $url = Get-DownloadUrl
        Invoke-Spinner -Message "Downloading binary" -ScriptBlock {
            Invoke-WebRequest -Uri $url -OutFile "$InstallDir\$BinaryName.exe" -UseBasicParsing
        }

        # Update PATH
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($currentPath -notmatch [regex]::Escape($InstallDir)) {
            Invoke-Spinner -Message "Updating PATH" -ScriptBlock {
                [Environment]::SetEnvironmentVariable(
                    "Path",
                    "$currentPath;$InstallDir",
                    "User"
                )
            }
        }

        Write-Host "${GREEN}✅ Installation complete!${RESET}"
        Write-Host "${CYAN}Note: You may need to restart your terminal for PATH changes${RESET}"
    }
    catch {
        Write-Host "${RED}❌ Installation failed: $($_.Exception.Message)${RESET}"
    }
}

function Update-GXSH {
    Show-Header
    Write-Host "${YELLOW}🔄 Starting update...${RESET}"
    
    try {
        if (-not (Test-Path "$InstallDir\$BinaryName.exe")) {
            throw "gxsh not installed. Please install first."
        }

        # Backup existing binary
        Invoke-Spinner -Message "Creating backup" -ScriptBlock {
            Copy-Item "$InstallDir\$BinaryName.exe" "$InstallDir\$BinaryName.bak" -Force
        }

        # Download update
        $url = Get-DownloadUrl
        Invoke-Spinner -Message "Downloading update" -ScriptBlock {
            Invoke-WebRequest -Uri $url -OutFile "$InstallDir\$BinaryName.exe" -UseBasicParsing
        }

        # Verify update
        if (-not (Test-Path "$InstallDir\$BinaryName.exe")) {
            throw "Download failed"
        }

        Invoke-Spinner -Message "Cleaning up" -ScriptBlock {
            Remove-Item "$InstallDir\$BinaryName.bak" -Force -ErrorAction SilentlyContinue
        }

        Write-Host "${GREEN}✅ Update successful!${RESET}"
    }
    catch {
        Write-Host "${RED}❌ Update failed: $($_.Exception.Message)${RESET}"
        if (Test-Path "$InstallDir\$BinaryName.bak") {
            Write-Host "${YELLOW}↩ Restoring previous version${RESET}"
            Move-Item "$InstallDir\$BinaryName.bak" "$InstallDir\$BinaryName.exe" -Force
        }
    }
}

function Uninstall-GXSH {
    Show-Header
    Write-Host "${RED}🗑 Starting uninstall...${RESET}"
    
    try {
        # Remove installation directory
        if (Test-Path $InstallDir) {
            Invoke-Spinner -Message "Removing files" -ScriptBlock {
                Remove-Item $InstallDir -Recurse -Force -ErrorAction Stop
            }
        }

        # Update PATH
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($currentPath -match [regex]::Escape($InstallDir)) {
            Invoke-Spinner -Message "Updating PATH" -ScriptBlock {
                $newPath = ($currentPath -split ';' | Where-Object { $_ -ne $InstallDir }) -join ';'
                [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            }
        }

        Write-Host "${GREEN}✅ Uninstall completed!${RESET}"
    }
    catch {
        Write-Host "${RED}❌ Uninstall failed: $($_.Exception.Message)${RESET}"
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
                Write-Host "${CYAN}👋 Goodbye!${RESET}"
                return 
            }
            default { Write-Host "${RED}❌ Invalid selection${RESET}" }
        }

        if ($choice -in 1..3) {
            Pause
        }
    } while ($true)
}

# Main execution
try {
    Show-MainMenu
}
catch {
    Write-Host "${RED}❌ An error occurred: $($_.Exception.Message)${RESET}"
}