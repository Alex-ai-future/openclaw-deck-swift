#!/bin/bash

# build.sh
# Build openclaw-deck-swift for different platforms
# Usage: bash script/build.sh <platform>
# Platforms: macos, ios, ipados

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_PATH="${PROJECT_DIR}/openclaw-deck-swift/openclaw-deck-swift.xcodeproj"
SCHEME_NAME="openclaw-deck-swift"

# 检查参数
if [ -z "$1" ]; then
    echo "❌ 缺少平台参数"
    echo ""
    echo "用法：bash script/build.sh <platform>"
    echo ""
    echo "可用平台:"
    echo "  macos   - 编译 macOS 版本"
    echo "  ios     - 编译 iOS 模拟器版本"
    echo "  ipados  - 编译 iPadOS 模拟器版本"
    echo ""
    echo "示例:"
    echo "  bash script/build.sh macos"
    echo "  bash script/build.sh ios"
    echo "  bash script/build.sh ipados"
    exit 1
fi

PLATFORM="$1"

# CI 环境跳过编译锁检查
if [ -n "$CI" ]; then
  echo "🔧 CI 环境，跳过编译锁检查"
fi

# 根据平台设置变量
case $PLATFORM in
  macos)
    BUILD_DIR="${PROJECT_DIR}/build/macos"
    DESTINATION="platform=macOS"
    PLATFORM_NAME="macOS"
    NEEDS_BUILD_LOCK=$([ -n "$CI" ] && echo "false" || echo "true")
    ;;
  ios)
    BUILD_DIR="${PROJECT_DIR}/build/ios"
    DESTINATION="platform=iOS Simulator"
    PLATFORM_NAME="iOS"
    NEEDS_BUILD_LOCK=false
    ;;
  ipados)
    BUILD_DIR="${PROJECT_DIR}/build/ipados"
    PLATFORM_NAME="iPadOS"
    NEEDS_BUILD_LOCK=$([ -n "$CI" ] && echo "false" || echo "true")
    
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
    echo "  bash script/build.sh macos"
    echo "  bash script/build.sh ios"
    echo "  bash script/build.sh ipados"
    exit 1
    ;;
esac

BUILD_DB="${BUILD_DIR}/DerivedData/Build/Intermediates.noindex/XCBuildData/build.db"

# 等待编译数据库锁释放
wait_for_build_lock() {
    local max_wait=${MAX_BUILD_WAIT:-60}
    local waited=0
    local interval=2
    
    while lsof "$BUILD_DB" >/dev/null 2>&1 && [ $waited -lt $max_wait ]; do
        echo "⏳ 等待其他编译进程完成... (${waited}s/${max_wait}s)"
        sleep $interval
        waited=$((waited + interval))
    done
    
    if lsof "$BUILD_DB" >/dev/null 2>&1; then
        echo "❌ 编译超时：数据库仍被锁定（已等待 ${max_wait}s）"
        echo "   可能原因：其他 AI/进程正在编译"
        echo "   解决：稍后重试，或手动清理：rm -rf ${BUILD_DIR}/DerivedData"
        exit 1
    fi
    
    if [ $waited -gt 0 ]; then
        echo "✅ 数据库锁已释放，开始编译（等待了 ${waited}s）"
    fi
}

echo "========================================"
echo "Building ${PLATFORM_NAME} Version"
echo "========================================"
echo ""

# 创建编译目录
mkdir -p "$BUILD_DIR"

# 清理编译目录
echo "Cleaning build directory..."
rm -rf "$BUILD_DIR"/*

# 如果需要，等待编译锁
if [ "$NEEDS_BUILD_LOCK" = true ]; then
    echo "Checking build database lock..."
    wait_for_build_lock
fi

# 编译
echo "Building for ${PLATFORM_NAME}..."
xcodebuild build \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -configuration Release \
    -destination "$DESTINATION" \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    -quiet \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO > "$BUILD_DIR/build.log" 2>&1

BUILD_STATUS=$?

# 显示所有编译错误
if [ $BUILD_STATUS -ne 0 ]; then
    echo ""
    echo "========================================"
    echo "❌ ${PLATFORM_NAME} Build Failed"
    echo "========================================"
    echo ""
    
    # 显示所有 error: 行
    echo "编译错误："
    grep -i "error:" "$BUILD_DIR/build.log"
    
    echo ""
    echo "完整日志：$BUILD_DIR/build.log"
    exit 1
fi

# 编译成功
echo ""
echo "========================================"
echo "✅ ${PLATFORM_NAME} Build Succeeded"
echo "========================================"
echo ""
echo "Build output location: $BUILD_DIR"

# 显示编译产物
echo ""
echo "Build artifacts:"
find "$BUILD_DIR/DerivedData/Build/Products/Release" -name "*.app" -type d 2>/dev/null | head -5 || \
find "$BUILD_DIR/DerivedData/Build/Products/Release-iphonesimulator" -name "*.app" -type d 2>/dev/null | head -5 || true
