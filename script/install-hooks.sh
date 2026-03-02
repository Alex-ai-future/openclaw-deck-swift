#!/bin/bash

# install-hooks.sh - 安装 Git hooks
# 用法：bash script/install-hooks.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$PROJECT_DIR/.git/hooks"

echo "🔧 安装 Git hooks..."

# 检查 .git 目录是否存在
if [ ! -d "$HOOKS_DIR" ]; then
  echo "❌ 错误：.git/hooks 目录不存在"
  echo "   请确保在项目根目录运行此脚本"
  exit 1
fi

# 安装 pre-commit hook
echo "📝 安装 pre-commit hook..."
cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash

# Pre-commit hook - 调用项目脚本
# 本地配置，指向 script/pre-commit

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

exec "$PROJECT_DIR/script/pre-commit"
EOF

chmod +x "$HOOKS_DIR/pre-commit"

echo "✅ Git hooks 安装完成！"
echo ""
echo "已安装的 hooks:"
echo "  - pre-commit (自动格式化 Swift 代码)"
