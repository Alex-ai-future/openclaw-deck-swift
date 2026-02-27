#!/bin/bash

# run_unit_tests.sh
# Run only unit tests (excluding UI tests) for openclaw-deck-swift
# Optimized for speed - uses incremental builds

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

# Clean previous test results only
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Only clean DerivedData if build fails
CLEAN_ON_FAILURE=true

echo "🔨 Building and testing (incremental)..."
echo ""

# Run unit tests ONLY (skip UI tests)
# Capture exit code properly when using tee
set -o pipefail
if xcodebuild test \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -destination 'platform=macOS,name=My Mac' \
    -only-testing:"${SCHEME_NAME}Tests" \
    -resultBundlePath "$BUILD_DIR/TestResults.xcresult" \
    -parallel-testing-enabled NO \
    CODE_SIGN_IDENTITY="-" \
    CODE_GENERATION_INSTRUMENTATION=YES \
    2>&1 | tee "$BUILD_DIR/test_output.log"; then
    
    # Check if tests actually passed (not just build)
    if grep -q "TEST FAILED\|Test run.*failed\|failed.*failures" "$BUILD_DIR/test_output.log"; then
        echo ""
        echo "========================================"
        echo "❌ Unit Tests Failed"
        echo "========================================"
        echo ""
        echo "Check detailed log: $BUILD_DIR/test_output.log"
        exit 1
    fi
    
    echo ""
    echo "========================================"
    echo "✅ Unit Tests Completed Successfully!"
    echo "========================================"
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
    exit 1
fi
