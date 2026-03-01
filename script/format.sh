#!/bin/bash

# format.sh - 格式化 Swift 代码（使用 swiftformat）
# 用法：
#   bash script/format.sh              # 格式化所有修改的 Swift 文件（默认）
#   bash script/format.sh --staged     # 只格式化暂存的文件（pre-commit 用）
#   bash script/format.sh --all        # 格式化整个项目
#   bash script/format.sh --check      # 只检查，不修改
#   bash script/format.sh --help       # 显示帮助信息

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SWIFT_DIR="${PROJECT_DIR}/openclaw-deck-swift/openclaw-deck-swift"

# 显示帮助信息
show_help() {
  cat << EOF
📝 Swift 代码格式化工具

用法：bash script/format.sh [选项]

选项：
  (无参数)             格式化所有修改的 Swift 文件（默认）
  --staged, -s         只格式化暂存的文件（pre-commit 用）
  --all, -a            格式化整个项目
  --check, -c          只检查，不修改（CI 用）
  --help, -h           显示帮助信息

示例：
  bash script/format.sh              # 格式化修改的文件（默认）
  bash script/format.sh --staged     # 提交前格式化
  bash script/format.sh --all        # 格式化整个项目
  bash script/format.sh --check      # CI 检查模式
  bash script/format.sh --help       # 显示帮助

EOF
}

# 检查是否需要显示帮助
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  show_help
  exit 0
fi

# 无参数时使用默认模式（modified）
MODE="${1:-modified}"

case "$MODE" in
  --all|-a)
    echo "📝 格式化所有 Swift 代码..."
    swiftformat "$SWIFT_DIR"
    echo "✅ 格式化完成"
    ;;
  
  --staged)
    echo "🔒 格式化暂存的 Swift 文件..."
    
    SWIFT_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.swift$' || true)
    
    if [ -z "$SWIFT_FILES" ]; then
      echo "✅ 没有 Swift 文件需要检查"
      exit 0
    fi
    
    echo "检查文件："
    echo "$SWIFT_FILES" | sed 's/^/  /'
    echo ""
    
    # 先检查格式
    echo "检查格式..."
    if swiftformat --lint $SWIFT_FILES 2>&1 | grep -q "Source input did not pass lint check"; then
      echo "⚠️  发现格式问题，正在修复..."
      swiftformat $SWIFT_FILES
      echo "✅ 格式修复完成"
    else
      echo "✅ 格式检查通过"
    fi
    ;;
  
  modified)
    echo "🔍 格式化修改的 Swift 文件..."
    
    # 获取所有修改的和未跟踪的 Swift 文件
    SWIFT_FILES=$(git diff --name-only --diff-filter=ACM | grep '\.swift$' || true)
    UNTRACKED_SWIFT=$(git ls-files --others --exclude-standard | grep '\.swift$' || true)
    
    # 合并两个列表
    if [ -n "$UNTRACKED_SWIFT" ]; then
      if [ -n "$SWIFT_FILES" ]; then
        SWIFT_FILES="$SWIFT_FILES"$'\n'"$UNTRACKED_SWIFT"
      else
        SWIFT_FILES="$UNTRACKED_SWIFT"
      fi
    fi
    
    if [ -z "$SWIFT_FILES" ]; then
      echo "✅ 没有 Swift 文件需要检查"
      exit 0
    fi
    
    echo "检查文件："
    echo "$SWIFT_FILES" | sed 's/^/  /'
    echo ""
    
    # 先检查格式
    echo "检查格式..."
    if swiftformat --lint $SWIFT_FILES 2>&1 | grep -q "Source input did not pass lint check"; then
      echo "⚠️  发现格式问题，正在修复..."
      swiftformat $SWIFT_FILES
      echo "✅ 格式修复完成"
    else
      echo "✅ 格式检查通过"
    fi
    ;;
  
  --check|-c)
    echo "🔍 检查 Swift 代码格式..."
    
    if swiftformat --lint --reporter github-actions-log "$SWIFT_DIR" 2>&1 | grep -q "Source input did not pass lint check"; then
      echo "❌ 格式检查失败，请运行以下命令修复："
      echo "   bash script/format.sh"
      exit 1
    else
      echo "✅ 格式检查通过"
      exit 0
    fi
    ;;
  
  *)
    echo "❌ 未知参数：$MODE"
    echo ""
    show_help
    exit 1
    ;;
esac
