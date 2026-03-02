# OpenClaw Deck Swift

多 Session AI 聊天客户端 - 基于 SwiftUI 原生构建

一款用于管理多个 OpenClaw Agent Session 的客户端应用，支持 iPadOS、macOS 和 iOS。

**GitHub**: [github.com/Alex-ai-future/openclaw-deck-swift](https://github.com/Alex-ai-future/openclaw-deck-swift)

## 快速开始

### 1. 编译运行

```bash
cd ~/Projects
git clone https://github.com/Alex-ai-future/openclaw-deck-swift.git
open openclaw-deck-swift/openclaw-deck-swift.xcodeproj
# Xcode 中 Cmd+R 运行
```

### 2. 配置 Gateway

应用需要连接 OpenClaw Gateway 才能工作：

1. 安装 [OpenClaw Gateway](https://github.com/openclaw/openclaw)
2. 启动：`pnpm start`
3. 应用中配置：`ws://127.0.0.1:18789`

详细配置：[用户指南](docs/USER_GUIDE.md)

### 3. 开始聊天

- 点击 `+` 创建新 Session
- 输入消息并发送
- 拖拽排序管理 Session

## 功能特性

- 多 Session 并行管理
- 实时流式消息显示
- Session 拖拽排序
- 语音输入
- Cloudflare 多设备同步 ⭐ NEW
- 快速发送（/new 命令）⭐ NEW
- iPadOS + macOS + iOS 支持

## 文档

- [📱 用户指南](docs/USER_GUIDE.md) - 使用说明和故障排除
- [📋 使用样例](docs/USAGE_EXAMPLES.md) - 实际使用场景示例
- [🏛️ 架构文档](docs/introduction.md) - 技术细节和实现
- [🤖 OpenClaw 文档](https://docs.openclaw.ai) - Gateway 配置

## 脚本工具

```bash
# 编译项目
bash script/build.sh macos|ios|ipados

# 运行单元测试
bash script/run_unit_tests.sh

# 运行 UI 测试
bash script/run_ui_tests.sh

# 代码格式化
bash script/format.sh

# 安全提交（自动格式化）
./script/committer "[类型] 描述" 文件 1 文件 2...
```

**提交类型：** `[feature]` `[fix]` `[ui]` `[refactor]` `[docs]`

## 系统要求

- iPadOS 18.0+ / macOS 15.0+
- Xcode 16.0+
- OpenClaw Gateway

---

**MIT License**
