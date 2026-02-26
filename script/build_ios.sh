#!/bin/bash

# build_ios.sh
# Build iOS version of openclaw-deck-swift

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_PATH="${PROJECT_DIR}/openclaw-deck-swift/openclaw-deck-swift.xcodeproj"
SCHEME_NAME="openclaw-deck-swift"
BUILD_DIR="${PROJECT_DIR}/build/ios"

echo "========================================"
echo "Building iOS Version"
echo "========================================"
echo ""

# Create build directory
mkdir -p "$BUILD_DIR"

# Clean build directory
echo "Cleaning build directory..."
rm -rf "$BUILD_DIR"/*

# Build for iOS Simulator
echo "Building for iOS Simulator..."
xcodebuild build \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -configuration Release \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    -quiet \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO > "$BUILD_DIR/build.log" 2>&1

BUILD_STATUS=$?

# Show last 20 lines of log
tail -20 "$BUILD_DIR/build.log"

if [ $BUILD_STATUS -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "✅ iOS Build Succeeded"
    echo "========================================"
    echo ""
    echo "Build output location: $BUILD_DIR"
else
    echo ""
    echo "========================================"
    echo "❌ iOS Build Failed"
    echo "========================================"
    echo ""
    echo "Check build log: $BUILD_DIR/build.log"
    exit 1
fi
