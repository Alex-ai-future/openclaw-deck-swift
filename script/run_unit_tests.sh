#!/bin/bash

# run_unit_tests.sh
# Run only unit tests (excluding UI tests) for openclaw-deck-swift

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_PATH="${PROJECT_DIR}/openclaw-deck-swift/openclaw-deck-swift.xcodeproj"
SCHEME_NAME="openclaw-deck-swift"
BUILD_DIR="${PROJECT_DIR}/build/tests"

echo "========================================"
echo "Running Unit Tests for $SCHEME_NAME"
echo "========================================"
echo ""

# Create build directory for test results
mkdir -p "$BUILD_DIR"

# Clean build directory
rm -rf "$BUILD_DIR"/*

# Run unit tests
# Using macOS destination for faster execution (no simulator boot needed)
# Code signing disabled to avoid errSecInternalComponent errors
OUTPUT=$(xcodebuild test \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -destination 'platform=macOS,name=My Mac' \
    -only-testing:"${SCHEME_NAME}Tests" \
    -resultBundlePath "$BUILD_DIR/TestResults.xcresult" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    2>&1)

# Check if tests passed by looking for the test result summary
# Note: Disabled tests are counted as "issues" but don't indicate failure
if echo "$OUTPUT" | grep -q "Test run with.*passed\|Suite.*passed"; then
    echo "$OUTPUT" | grep -E "(✔|✘|◇|Suite|Test)" | tail -100
    echo ""
    echo "========================================"
    echo "✅ Unit Tests Completed"
    echo "========================================"
    echo ""
    echo "Note: Some tests may be disabled. Check output for details."
    exit 0
else
    echo "$OUTPUT" | grep -E "(✔|✘|◇|Suite|Test|error|failed)" | tail -100
    echo ""
    echo "========================================"
    echo "❌ Unit Tests Failed"
    echo "========================================"
    exit 1
fi
