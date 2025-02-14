# Define the output build directory
$buildDir = "builds"

# Define the target platforms and architectures
$targets = @(
    @{ OS="windows"; ARCH="amd64"; EXT=".exe" },
    @{ OS="windows"; ARCH="386"; EXT=".exe" },
    @{ OS="windows"; ARCH="arm"; EXT=".exe" },
    @{ OS="windows"; ARCH="arm64"; EXT=".exe" },
    @{ OS="linux"; ARCH="amd64"; EXT="" },
    @{ OS="linux"; ARCH="386"; EXT="" },
    @{ OS="linux"; ARCH="arm"; EXT="" },
    @{ OS="linux"; ARCH="arm64"; EXT="" },
    @{ OS="linux"; ARCH="ppc64"; EXT="" },
    @{ OS="linux"; ARCH="ppc64le"; EXT="" },
    @{ OS="linux"; ARCH="mips"; EXT="" },
    @{ OS="linux"; ARCH="mipsle"; EXT="" },
    @{ OS="linux"; ARCH="mips64"; EXT="" },
    @{ OS="linux"; ARCH="mips64le"; EXT="" },
    @{ OS="darwin"; ARCH="amd64"; EXT="" },
    @{ OS="darwin"; ARCH="arm64"; EXT="" }
)

# Check if Go is installed
if (!(Get-Command go -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Go is not installed. Please install Go and try again."
    exit 1
}

# Create the build directory if it doesn't exist
if (!(Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}

# Loop through each target and build
foreach ($target in $targets) {
    $os = $target.OS
    $arch = $target.ARCH
    $ext = $target.EXT
    $outputFile = "$buildDir/godo-$os-$arch$ext"

    # Set environment variables and build
    Write-Host "🚀 Building for $os-$arch..."
    $env:GOOS = $os
    $env:GOARCH = $arch

    # Compile the binary
    go build -o $outputFile

    # Check if the build succeeded
    if ($?) {
        Write-Host "✅ Build successful: $outputFile"
    } else {
        Write-Host "❌ Build failed for $os-$arch"
    }
}

Write-Host "🎉 All builds completed! Files are stored in the 'builds' directory."
