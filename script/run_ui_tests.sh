#!/bin/bash

# run_ui_tests.sh
# Run UI tests for openclaw-deck-swift on specified platform
# Usage: bash script/run_ui_tests.sh <platform>
# Platforms: ios, ipados, macos

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_PATH="${PROJECT_DIR}/openclaw-deck-swift/openclaw-deck-swift.xcodeproj"
SCHEME_NAME="openclaw-deck-swift"

# ========================================
# 1. 参数验证
# ========================================

if [ -z "$1" ]; then
    echo "❌ Error: Platform parameter is required"
    echo ""
    echo "Usage: bash script/run_ui_tests.sh <platform>"
    echo ""
    echo "Platforms:"
    echo "  ios     - iOS Simulator (iPhone 15)"
    echo "  ipados  - iPadOS Simulator (iPad Pro 12.9-inch)"
    echo "  macos   - macOS (My Mac)"
    echo ""
    exit 1
fi

PLATFORM="$1"

# 验证平台参数
if [ "$PLATFORM" != "ios" ] && [ "$PLATFORM" != "ipados" ] && [ "$PLATFORM" != "macos" ]; then
    echo "❌ Error: Invalid platform '$PLATFORM'"
    echo ""
    echo "Usage: bash script/run_ui_tests.sh <platform>"
    echo ""
    echo "Platforms:"
    echo "  ios     - iOS Simulator (iPhone 15)"
    echo "  ipados  - iPadOS Simulator (iPad Pro 12.9-inch)"
    echo "  macos   - macOS (My Mac)"
    echo ""
    exit 1
fi

# ========================================
# 2. 根据平台设置 destination
# ========================================

case "$PLATFORM" in
    macos)
        DESTINATION="platform=macOS,name=My Mac"
        ;;
    ios)
        DESTINATION="platform=iOS Simulator,name=iPhone 15,OS=latest"
        ;;
    ipados)
        DESTINATION="platform=iPadOS Simulator,name=iPad Pro 12.9-inch (6th generation),OS=latest"
        ;;
esac

# ========================================
# 3. 设置构建目录
# ========================================

BUILD_DIR="${PROJECT_DIR}/build/ui_tests_${PLATFORM}"

echo "========================================"
echo "Running UI Tests for $SCHEME_NAME"
echo "Platform: $PLATFORM"
echo "Destination: $DESTINATION"
echo "========================================"
echo ""

# 只清理测试结果，保留构建产物以支持增量构建
rm -rf "$BUILD_DIR/TestResults.xcresult"
rm -rf "$BUILD_DIR/test_output.log"
mkdir -p "$BUILD_DIR"

echo "🔨 Building and testing..."
echo ""

# ========================================
# 4. 运行 UI 测试
# ========================================

# Run UI tests ONLY (skip unit tests)
set -o pipefail
if xcodebuild test \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -destination "$DESTINATION" \
    -only-testing:"${SCHEME_NAME}UITests" \
    -resultBundlePath "$BUILD_DIR/TestResults.xcresult" \
    -parallel-testing-enabled NO \
    CODE_SIGN_IDENTITY="-" \
    CODE_GENERATION_INSTRUMENTATION=YES \
    OTHER_SWIFT_FLAGS="-D TESTING" \
    -enableCodeCoverage YES \
    -configuration Debug \
    2>&1 | tee "$BUILD_DIR/test_output.log"; then
    
    # 检查测试是否真的通过
    if grep -q "TEST FAILED\|Test run.*failed\|failed.*failures" "$BUILD_DIR/test_output.log"; then
        echo ""
        echo "========================================"
        echo "❌ UI Tests Failed"
        echo "========================================"
        echo ""
        echo "Check detailed log: $BUILD_DIR/test_output.log"
        exit 1
    fi
    
    echo ""
    echo "========================================"
    echo "✅ UI Tests Completed Successfully!"
    echo "========================================"
    echo ""
    echo "Platform: $PLATFORM"
    echo "Results saved to: $BUILD_DIR/TestResults.xcresult"
    exit 0
else
    echo ""
    echo "========================================"
    echo "❌ UI Tests Failed"
    echo "========================================"
    echo ""
    echo "Check detailed log: $BUILD_DIR/test_output.log"
    exit 1
fi
