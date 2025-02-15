#!/bin/bash

# Define the output build directory
BUILD_DIR="builds"

# Define the target platforms and architectures
targets=(
    "windows amd64 .exe"
    "windows 386 .exe"
    "windows arm .exe"
    "windows arm64 .exe"
    "linux amd64 "
    "linux 386 "
    "linux arm "
    "linux arm64 "
    "linux ppc64 "
    "linux ppc64le "
    "linux mips "
    "linux mipsle "
    "linux mips64 "
    "linux mips64le "
    "darwin amd64 "
    "darwin arm64 "
)

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed. Please install Go and try again."
    exit 1
fi

# Create the build directory if it doesn't exist
mkdir -p "$BUILD_DIR"

# Loop through each target and build
for target in "${targets[@]}"; do
    read -r os arch ext <<< "$target"
    output_file="$BUILD_DIR/gxsh-$os-$arch$ext"

    echo "🚀 Building for $os-$arch..."
    
    # Set environment variables and build
    GOOS="$os" GOARCH="$arch" go build -o "$output_file"
    
    # Check if the build succeeded
    if [ $? -eq 0 ]; then
        echo "✅ Build successful: $output_file"
    else
        echo "❌ Build failed for $os-$arch"
    fi

done

echo "🎉 All builds completed! Files are stored in the '$BUILD_DIR' directory."
