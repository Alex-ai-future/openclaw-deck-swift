#!/bin/bash

# run_ui_tests.sh
# Run UI tests for openclaw-deck-swift on different platforms
# Usage: bash script/run_ui_tests.sh <platform>
# Platforms: macos, ios, ipados

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_PATH="${PROJECT_DIR}/openclaw-deck-swift/openclaw-deck-swift.xcodeproj"
SCHEME_NAME="openclaw-deck-swift"

# 检查参数
if [ -z "$1" ]; then
    echo "❌ 缺少平台参数"
    echo ""
    echo "用法：bash script/run_ui_tests.sh <platform>"
    echo ""
    echo "可用平台:"
    echo "  macos   - 运行 macOS UI 测试（需要辅助功能权限）"
    echo "  ios     - 运行 iOS 模拟器 UI 测试（不需要权限）"
    echo "  ipados  - 运行 iPadOS 模拟器 UI 测试（不需要权限）"
    echo ""
    echo "示例:"
    echo "  bash script/run_ui_tests.sh macos"
    echo "  bash script/run_ui_tests.sh ios"
    echo "  bash script/run_ui_tests.sh ipados"
    exit 1
fi

PLATFORM="$1"

# 根据平台设置变量
case $PLATFORM in
  macos)
    BUILD_DIR="${PROJECT_DIR}/build/ui-tests-macos"
    DESTINATION="platform=macOS,name=My Mac"
    PLATFORM_NAME="macOS"
    ;;
  ios)
    BUILD_DIR="${PROJECT_DIR}/build/ui-tests-ios"
    DESTINATION="platform=iOS Simulator,name=iPhone 17"
    PLATFORM_NAME="iOS"
    ;;
  ipados)
    BUILD_DIR="${PROJECT_DIR}/build/ui-tests-ipados"
    PLATFORM_NAME="iPadOS"
    
    # 动态检测 iPad 模拟器
    echo "Finding available iPad simulator..."
    IPAD_SIMULATOR=$(xcrun simctl list devices available 'iPad' -j 2>/dev/null | \
        jq -r '.devices | to_entries[] | .value[] | select(.availability | contains("Available")) | .udid' | \
        head -1)
    
    if [ -z "$IPAD_SIMULATOR" ]; then
        DESTINATION='platform=iOS Simulator,name=iPad Pro 13-inch (M5)'
        echo "Using generic iPad destination: $DESTINATION"
    else
        DESTINATION="platform=iOS Simulator,id=$IPAD_SIMULATOR"
        echo "Using iPad simulator: $DESTINATION"
    fi
    ;;
  *)
    echo "❌ 无效的平台：$PLATFORM"
    echo ""
    echo "可用平台：macos, ios, ipados"
    echo ""
    echo "示例:"
    echo "  bash script/run_ui_tests.sh macos"
    echo "  bash script/run_ui_tests.sh ios"
    echo "  bash script/run_ui_tests.sh ipados"
    exit 1
    ;;
esac

echo "========================================"
echo "Running UI Tests for ${PLATFORM_NAME}"
echo "========================================"
echo ""

# Clean previous test results
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "🔨 Building and testing..."
echo ""

# Run UI tests
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
    OTHER_SWIFT_FLAGS="-D TESTING -D UI_TESTING" \
    2>&1 | tee "$BUILD_DIR/test_output.log"; then
    
    # Check if tests actually passed
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
    echo "Results saved to: $BUILD_DIR/test_output.log"
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
