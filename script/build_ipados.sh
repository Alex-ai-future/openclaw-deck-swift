#!/bin/bash

# build_ipados.sh
# Build iPadOS version of openclaw-deck-swift

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_PATH="${PROJECT_DIR}/openclaw-deck-swift/openclaw-deck-swift.xcodeproj"
SCHEME_NAME="openclaw-deck-swift"
BUILD_DIR="${PROJECT_DIR}/build/ipados"

echo "========================================"
echo "Building iPadOS Version"
echo "========================================"
echo ""

# Create build directory
mkdir -p "$BUILD_DIR"

# Clean build directory
echo "Cleaning build directory..."
rm -rf "$BUILD_DIR"/*

# Find available iPad simulator
echo "Finding available iPad simulator..."

# Try to find any available iPad simulator
IPAD_SIMULATOR=$(xcrun simctl list devices available 'iPad' -j 2>/dev/null | \
    jq -r '.devices | to_entries[] | .value[] | select(.availability | contains("Available")) | .udid' | \
    head -1)

if [ -z "$IPAD_SIMULATOR" ]; then
    # Fallback to generic iPad destination with available model
    DESTINATION='platform=iOS Simulator,name=iPad Pro 13-inch (M5)'
    echo "Using generic iPad destination: $DESTINATION"
else
    DESTINATION="platform=iOS Simulator,id=$IPAD_SIMULATOR"
    echo "Using iPad simulator: $DESTINATION"
fi

# Build for iPadOS
echo "Building for iPadOS..."
xcodebuild build \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -configuration Release \
    -destination "$DESTINATION" \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    -quiet > "$BUILD_DIR/build.log" 2>&1

BUILD_STATUS=$?

# Show last 20 lines of log
tail -20 "$BUILD_DIR/build.log"

if [ $BUILD_STATUS -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "✅ iPadOS Build Succeeded"
    echo "========================================"
    echo ""
    echo "Build output location: $BUILD_DIR"

    # Show build artifacts
    echo ""
    echo "Build artifacts:"
    find "$BUILD_DIR/DerivedData/Build/Products/Release-iphonesimulator" -name "*.app" -type d 2>/dev/null | head -5 || true
else
    echo ""
    echo "========================================"
    echo "❌ iPadOS Build Failed"
    echo "========================================"
    echo ""
    echo "Check build log: $BUILD_DIR/build.log"
    exit 1
fi
