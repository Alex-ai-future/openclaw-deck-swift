#!/bin/bash

# run_unit_tests.sh
# Run only unit tests (excluding UI tests) for openclaw-deck-swift

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_PATH="${PROJECT_DIR}/openclaw-deck-swift/openclaw-deck-swift.xcodeproj"
SCHEME_NAME="openclaw-deck-swift"

echo "========================================"
echo "Running Unit Tests for $SCHEME_NAME"
echo "========================================"
echo ""

# Run unit tests only (not UI tests)
# Using macOS destination for faster execution (no simulator boot needed)
# -parallel-testing-enabled NO: Disable parallel testing for stability
OUTPUT=$(xcodebuild test \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -destination 'platform=macOS' \
    -only-testing:"${SCHEME_NAME}Tests" \
    -parallel-testing-enabled NO 2>&1)

# Check if tests passed by looking for the test result summary
if echo "$OUTPUT" | grep -q "Test run with.*passed"; then
    echo "$OUTPUT" | grep -E "(✔|✘|◇|Suite|Test)" | tail -50
    echo ""
    echo "========================================"
    echo "✅ Unit Tests Passed"
    echo "========================================"
    exit 0
else
    echo "$OUTPUT" | grep -E "(✔|✘|◇|Suite|Test|failed)" | tail -50
    echo ""
    echo "========================================"
    echo "❌ Unit Tests Failed"
    echo "========================================"
    exit 1
fi
