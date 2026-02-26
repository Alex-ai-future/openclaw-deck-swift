#!/bin/bash

# run_unit_tests.sh
# Run only unit tests (excluding UI tests) for openclaw-deck-swift

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_PATH="${PROJECT_DIR}/openclaw-deck-swift/openclaw-deck-swift.xcodeproj"
SCHEME_NAME="openclaw-deck-swift"
BUILD_DIR="${PROJECT_DIR}/build/tests"

echo "========================================"
echo "Running Unit Tests for $SCHEME_NAME"
echo "========================================"
echo ""

# Clean previous test results
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Clean Xcode DerivedData to avoid database lock issues
echo "🧹 Cleaning build cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/openclaw-deck-swift-*/Build/Intermediates.noindex/XCBuildData/*.db 2>/dev/null || true

# Kill any running xcodebuild processes
pkill -9 xcodebuild 2>/dev/null || true

# Wait for cleanup
sleep 2

echo "🔨 Building and testing..."
echo ""

# Run unit tests ONLY (skip UI tests)
# Using -only-testing to run only the unit test target
if xcodebuild test \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -destination 'platform=macOS,name=My Mac' \
    -only-testing:"${SCHEME_NAME}Tests" \
    -resultBundlePath "$BUILD_DIR/TestResults.xcresult" \
    -parallel-testing-enabled NO \
    CODE_SIGN_IDENTITY="-" \
    -quiet \
    2>&1 | tee "$BUILD_DIR/test_output.log"; then
    
    echo ""
    echo "========================================"
    echo "✅ Unit Tests Completed Successfully!"
    echo "========================================"
    echo ""
    
    # Show test summary
    if command -v xcresulttool &> /dev/null; then
        echo "📊 Test Summary:"
        xcresulttool get --format json --path "$BUILD_DIR/TestResults.xcresult" 2>/dev/null | \
            grep -o '"testableName":"[^"]*"' | sort | uniq || true
    fi
    
    echo ""
    echo "Results saved to: $BUILD_DIR/TestResults.xcresult"
    exit 0
else
    echo ""
    echo "========================================"
    echo "❌ Unit Tests Failed"
    echo "========================================"
    echo ""
    echo "Check detailed log: $BUILD_DIR/test_output.log"
    echo "Check results: $BUILD_DIR/TestResults.xcresult"
    exit 1
fi
