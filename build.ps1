# Define the output build directory
$buildDir = "builds"

# Define the target platforms and architectures
$targets = @(
    @{ OS="windows"; ARCH="amd64"; EXT=".exe" },
    @{ OS="windows"; ARCH="386"; EXT=".exe" },
    @{ OS="linux"; ARCH="amd64"; EXT="" },
    @{ OS="linux"; ARCH="arm"; EXT="" },
    @{ OS="linux"; ARCH="arm64"; EXT="" },
    @{ OS="darwin"; ARCH="amd64"; EXT="" },
    @{ OS="darwin"; ARCH="arm64"; EXT="" }
)

# Create the main build directory
if (!(Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}

# Loop through each target and build
foreach ($target in $targets) {
    $os = $target.OS
    $arch = $target.ARCH
    $ext = $target.EXT
    $outputDir = "$buildDir/$os-$arch"
    $outputFile = "$outputDir/godo$ext"

    # Create platform-specific folder
    if (!(Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir | Out-Null
    }

    # Set environment variables and build
    Write-Host "Building for $os-$arch..."
    $env:GOOS = $os
    $env:GOARCH = $arch
    go build -o $outputFile

    if ($?) {
        Write-Host "✅ Build successful: $outputFile"
    } else {
        Write-Host "❌ Build failed for $os-$arch"
    }
}

Write-Host "🎉 All builds completed! Files are stored in the 'builds' directory."
