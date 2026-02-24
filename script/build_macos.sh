#!/bin/bash

# build_macos.sh
# Build macOS version of openclaw-deck-swift

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_PATH="${PROJECT_DIR}/openclaw-deck-swift/openclaw-deck-swift.xcodeproj"
SCHEME_NAME="openclaw-deck-swift"
BUILD_DIR="${PROJECT_DIR}/build/macos"

echo "========================================"
echo "Building macOS Version"
echo "========================================"
echo ""

# Create build directory
mkdir -p "$BUILD_DIR"

# Clean build directory
echo "Cleaning build directory..."
rm -rf "$BUILD_DIR"/*

# Build for macOS
echo "Building for macOS..."
if xcodebuild build \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -configuration Release \
    -destination 'platform=macOS' \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    -quiet 2>&1 | tee "$BUILD_DIR/build.log"; then
    echo ""
    echo "========================================"
    echo "✅ macOS Build Succeeded"
    echo "========================================"
    echo ""
    echo "Build output location: $BUILD_DIR"
    
    # Show build artifacts
    echo ""
    echo "Build artifacts:"
    find "$BUILD_DIR/DerivedData/Build/Products/Release" -name "*.app" -type d 2>/dev/null | head -5 || true
else
    echo ""
    echo "========================================"
    echo "❌ macOS Build Failed"
    echo "========================================"
    echo ""
    echo "Check build log: $BUILD_DIR/build.log"
    exit 1
fi
