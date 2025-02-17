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

# Check if UPX is installed
if command -v upx &> /dev/null; then
    UPX_AVAILABLE=true
    echo "✅ UPX found! Will compress binaries."
else
    UPX_AVAILABLE=false
    echo "⚠️ UPX not found. Skipping compression."
fi

# Create the build directory if it doesn't exist
mkdir -p "$BUILD_DIR"

# Loop through each target and build
for target in "${targets[@]}"; do
    read -r os arch ext <<< "$target"
    output_file="$BUILD_DIR/gxsh-$os-$arch$ext"

    echo "🚀 Building for $os-$arch..."
    
    # Set environment variables and build with stripped debug symbols
    GOOS="$os" GOARCH="$arch" go build -ldflags="-s -w" -o "$output_file"
    
    # Check if the build succeeded
    if [ $? -eq 0 ]; then
        echo "✅ Build successful: $output_file"

        # Compress with UPX if available
        if [ "$UPX_AVAILABLE" = true ]; then
            echo "🗜 Compressing $output_file..."
            upx --best --lzma "$output_file" &> /dev/null
            if [ $? -eq 0 ]; then
                echo "✅ Compression successful: $output_file"
            else
                echo "⚠️ Compression failed for $output_file"
            fi
        fi
    else
        echo "❌ Build failed for $os-$arch"
    fi
done

echo "🎉 All builds completed! Files are stored in the '$BUILD_DIR' directory."
