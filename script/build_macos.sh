#!/bin/bash

# build_macos.sh
# Build macOS version of openclaw-deck-swift

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_PATH="${PROJECT_DIR}/openclaw-deck-swift/openclaw-deck-swift.xcodeproj"
SCHEME_NAME="openclaw-deck-swift"
BUILD_DIR="${PROJECT_DIR}/build/macos"
BUILD_DB="${BUILD_DIR}/DerivedData/Build/Intermediates.noindex/XCBuildData/build.db"

# Wait for build database lock to be released
wait_for_build_lock() {
    local max_wait=${MAX_BUILD_WAIT:-60}  # 默认等待 60 秒
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
echo "Building macOS Version"
echo "========================================"
echo ""

# Create build directory
mkdir -p "$BUILD_DIR"

# Clean build directory
echo "Cleaning build directory..."
rm -rf "$BUILD_DIR"/*

# Wait for build lock before compiling
echo "Checking build database lock..."
wait_for_build_lock

# Build for macOS
# Note: Code signing is disabled to avoid errSecInternalComponent errors
echo "Building for macOS..."
xcodebuild build \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -configuration Release \
    -destination 'platform=macOS' \
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
