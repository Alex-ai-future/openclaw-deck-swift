# OpenClaw Deck Swift - 使用说明书

**版本：** 1.0  
**最后更新：** 2026-02-26  
**适用平台：** macOS, iPadOS, iOS

---

## 目录

1. [快速开始](#1-快速开始)
2. [功能说明](#2-功能说明)
3. [常见问题](#3-常见问题)
4. [快捷键](#4-快捷键)
5. [故障排除](#5-故障排除)
6. [技术细节](#6-技术细节)

---

## 1. 快速开始

### 1.0 Gateway 配置（必须先配置）

**OpenClaw Deck Swift 需要连接 OpenClaw Gateway 才能工作。**

**步骤 1：安装 OpenClaw Gateway**

```bash
# 克隆 OpenClaw 项目
git clone https://github.com/openclaw/openclaw.git
cd openclaw

# 安装依赖
pnpm install

# 启动 Gateway
pnpm start
```

**相关资源：**
- **GitHub 仓库：** https://github.com/openclaw/openclaw
- **官方文档：** https://docs.openclaw.ai
- **Discord 社区：** https://discord.gg/clawd

**步骤 2：配置连接方式为 LAN**

在 Gateway 配置中设置连接方式为 LAN（局域网）：

```bash
# 编辑 Gateway 配置
# (根据安装方式编辑相应配置文件)

# 设置连接方式为 LAN
connection.mode = "lan"
```

**步骤 3：添加设备 IP 到允许源头**

在 Gateway 的允许源头列表中添加运行 Deck Swift 的设备 IP：

```bash
# 查看当前设备 IP
# macOS
ipconfig getifaddr en0

# 或在 Gateway 配置中添加
allowed_origins = [
  "192.168.1.xxx",  # 替换为实际 IP
  "127.0.0.1"       # 本地回环
]
```

**步骤 4：配对同意**

首次连接时需要配对同意：

```bash
# 查看待配对设备
openclaw pairing list

# 同意配对
openclaw pairing approve <device-id>

# 或查看配对帮助
openclaw pairing --help
```

**步骤 5：测试连接**

```bash
# 测试 Gateway 是否可访问
curl ws://127.0.0.1:18789

# 或在 Deck Swift 应用中尝试连接
```

**常见问题：**

| 问题 | 解决方法 |
|------|---------|
| 无法连接 Gateway | 检查 Gateway 是否启动 |
| 配对失败 | 重启 Gateway 后重试 |
| IP 地址变化 | 使用静态 IP 或更新配置 |

---

### 1.1 系统要求

| 平台 | 最低版本 | 推荐版本 |
|------|---------|---------|
| macOS | 15.0+ | 15.3+ |
| iPadOS | 18.0+ | 18.3+ |
| iOS | 18.0+ | 18.3+ |

**硬件要求：**
- 内存：4GB 以上
- 存储空间：100MB 可用空间
- 网络：需要访问 OpenClaw Gateway

### 1.2 安装步骤

**方式 A：Xcode 编译（推荐开发者）**

```bash
# 1. 克隆项目
cd ~/Projects
git clone <repository-url> openclaw-deck-swift

# 2. 打开项目
open openclaw-deck-swift/openclaw-deck-swift.xcodeproj

# 3. 在 Xcode 中选择目标平台
#    - macOS: My Mac
#    - iPadOS: iPad Simulator 或真实设备

# 4. 编译运行 (Cmd+R)
```

**方式 B：直接运行已编译应用**

```bash
# 找到编译好的应用
open ~/Projects/openclaw-deck-swift/build/Debug/openclaw-deck-swift.app
```

### 1.3 首次配置

**启动应用后：**

1. **配置 Gateway URL**
   - 默认：`ws://127.0.0.1:18789`
   - 如果 Gateway 在远程服务器，填写服务器地址

2. **配置 Token（可选）**
   - 如果 Gateway 需要认证，输入 Token
   - 本地 Gateway 通常不需要 Token

3. **点击"连接"**
   - 等待连接成功提示
   - 成功后自动创建 Welcome Session

### 1.4 连接 Gateway

**连接状态指示：**
- ✅ **已连接** - 可以发送消息
- ⏳ **连接中** - 正在建立连接
- ❌ **连接失败** - 检查 Gateway 是否运行

**检查 Gateway 是否运行：**

```bash
# 本地 Gateway
ps aux | grep openclaw

# 或者检查端口
lsof -i :18789
```

---

## 2. 功能说明

### 2.1 多 Session 管理

**什么是 Session？**
- 每个 Session 是一个独立的聊天会话
- 类似微信的不同聊天窗口
- 每个 Session 有独立的消息历史

**创建 Session：**
1. 点击顶部工具栏的 `+` 按钮
2. 输入 Session 名称（可选）
3. 自动创建并开始新会话

**切换 Session：**
- 横向滚动 Session 列
- 点击任意 Session 切换到该会话

**删除 Session：**
1. 点击 Session 顶部的菜单按钮（三个点）
2. 选择"Delete Session"
3. 确认删除

**注意：**
- 删除 Session 只删除本地显示
- 消息历史仍保存在 Gateway
- 重新创建同名 Session 会加载历史消息

### 2.2 发送消息

**文本消息：**
1. 在底部输入框输入文字
2. 按 Enter 键或点击发送按钮
3. 消息立即显示，AI 开始回复

**语音输入（macOS/iOS）：**
1. 点击麦克风图标
2. 开始说话
3. 点击麦克风停止
4. 语音自动转为文字并发送

**消息显示：**
- ✅ **单条消息显示** - AI 回复显示为一条完整消息
- ✅ **流式更新** - 实时看到 AI 回复内容
- ✅ **段落分隔** - 长消息用空行分隔段落

### 2.3 设置配置

**打开设置：**
- 点击顶部工具栏的齿轮图标 ⚙️

**可配置项：**

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| Gateway URL | WebSocket 地址 | `ws://127.0.0.1:18789` |
| Token | 认证 Token | 空 |
| 自动连接 | 启动时自动连接 | 开启 |

**保存配置：**
- 配置自动保存
- 下次启动自动加载

---

## 3. 常见问题

### 3.1 Gateway 连接问题

**Q: 显示"连接失败"怎么办？**

**A:** 检查以下步骤：
1. 确认 Gateway 已启动
2. 检查 URL 是否正确
3. 检查防火墙设置
4. 尝试重启应用

**Q: 连接后自动断开？**

**A:** 可能原因：
- Gateway 重启或崩溃
- 网络不稳定
- Token 过期（如果启用认证）

**解决方法：**
1. 检查 Gateway 状态
2. 重新连接
3. 更新 Token（如果需要）

### 3.2 消息问题

**Q: 消息显示为一个大气泡？**

**A:** 这是正常行为！
- 设计为单条消息显示
- 避免消息碎片化
- 段落用空行分隔

**Q: 消息重复显示？**

**A:** 可能原因：
- Gateway 重发消息
- 网络延迟导致重复接收

**解决方法：**
- 已自动去重，如仍有问题重启应用

### 3.3 语音输入问题

**Q: 点击麦克风没反应？**

**A:** 检查权限：
1. macOS: 系统偏好设置 → 安全性与隐私 → 麦克风
2. iOS: 设置 → 隐私 → 麦克风
3. 确保应用有麦克风权限

**Q: 语音转文字不准确？**

**A:** 可能原因：
- 环境噪音大
- 语速过快
- 方言口音

**建议：**
- 在安静环境使用
- 语速适中
- 使用普通话

### 3.4 性能优化

**Q: 应用运行卡顿？**

**A:** 优化建议：
1. 减少 Session 数量（删除不用的）
2. 清理长消息历史
3. 关闭不用的应用

**Q: 内存占用高？**

**A:** 正常现象：
- SwiftUI 应用内存占用较高
- 消息历史缓存在内存中

**优化：**
- 重启应用释放内存
- 减少同时打开的 Session 数

---

## 4. 快捷键

### 4.1 macOS 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Cmd + R` | 重新连接 Gateway |
| `Cmd + N` | 创建新 Session |
| `Cmd + W` | 关闭当前 Session |
| `Cmd + ,` | 打开设置 |
| `Enter` | 发送消息 |
| `Shift + Enter` | 输入框换行 |
| `Cmd + F` | 搜索消息（未来功能） |

### 4.2 常用操作

| 操作 | 方法 |
|------|------|
| 切换 Session | 横向滚动或点击 |
| 删除 Session | 点击顶部菜单 → Delete |
| 打开设置 | 点击齿轮图标 |
| 语音输入 | 点击麦克风图标 |

---

## 5. 故障排除（重点）

### 5.1 连接超时

**症状：**
- 显示"连接超时"
- 一直显示"连接中..."

**可能原因：**
1. Gateway 未启动
2. URL 错误
3. 防火墙阻止
4. 端口被占用

**解决步骤：**

```bash
# 1. 检查 Gateway 是否运行
ps aux | grep openclaw

# 2. 检查端口是否监听
lsof -i :18789

# 3. 测试连接
telnet 127.0.0.1 18789

# 4. 查看 Gateway 日志
# (根据 Gateway 安装位置)
tail -f /var/log/openclaw.log
```

**解决方案：**

| 问题 | 解决方法 |
|------|---------|
| Gateway 未启动 | 启动 Gateway |
| URL 错误 | 更正 Gateway URL |
| 防火墙阻止 | 添加防火墙规则 |
| 端口被占用 | 更改 Gateway 端口 |

### 5.2 消息合并问题

**症状：**
- 多条消息显示成一个气泡
- 消息内容重复

**原因：**
- Gateway 发送的是累积文本
- 客户端设计为单条消息显示

**解决方案：**

**方案 A：接受当前设计（推荐）**
- 单条消息更清晰
- 段落用空行分隔
- 避免消息碎片化

**方案 B：修改 Gateway（需要开发）**
- 每个 block 发送独立 text
- 或添加 blockId 字段
- 需要修改 Gateway 代码

### 5.3 语音输入失败

**症状：**
- 点击麦克风无反应
- 语音无法转文字
- 权限请求不显示

**解决步骤：**

**macOS:**
```bash
# 1. 检查麦克风权限
tccutil reset Microphone com.openclaw.deck

# 2. 重新授权
# 系统偏好设置 → 安全性与隐私 → 麦克风

# 3. 重启应用
```

**iOS/iPadOS:**
```
1. 设置 → 隐私 → 麦克风
2. 找到应用，开启权限
3. 重启应用
```

**常见问题：**

| 问题 | 解决方法 |
|------|---------|
| 权限已开启但仍失败 | 重置权限后重启 |
| 语音识别不可用 | 检查网络连接 |
| 转文字错误 | 检查语言设置 |

### 5.4 应用崩溃

**症状：**
- 应用突然关闭
- 启动时崩溃
- 特定操作时崩溃

**诊断步骤：**

**macOS:**
```bash
# 查看崩溃日志
open ~/Library/Logs/DiagnosticReports/

# 查找 openclaw-deck-swift 相关日志
ls -lt ~/Library/Logs/DiagnosticReports/ | grep openclaw
```

**常见崩溃原因：**

| 崩溃场景 | 可能原因 | 解决方法 |
|---------|---------|---------|
| 启动时崩溃 | 配置文件损坏 | 删除配置文件重启 |
| 连接时崩溃 | Gateway 响应异常 | 检查 Gateway 日志 |
| 发送消息崩溃 | 消息内容过大 | 减少消息长度 |
| 随机崩溃 | 内存不足 | 关闭其他应用 |

**解决方案：**

```bash
# 1. 删除配置（会重置设置）
rm -rf ~/Library/Preferences/com.openclaw.deck.plist

# 2. 清除缓存
rm -rf ~/Library/Caches/com.openclaw.deck

# 3. 重新安装
# 重新编译或下载最新版本
```

### 5.5 日志查看方法

**应用日志位置：**

**macOS:**
```bash
# 控制台应用
open /Applications/Utilities/Console.app

# 或直接查看文件
tail -f ~/Library/Logs/OpenClaw\ Deck/*.log
```

**iOS/iPadOS:**
```
1. 连接设备到电脑
2. 打开 Xcode
3. Window → Devices and Simulators
4. 选择设备 → View Device Logs
```

**关键日志关键字：**

| 关键字 | 说明 |
|--------|------|
| `GatewayClient` | Gateway 连接相关 |
| `DeckViewModel` | Session 管理相关 |
| `SpeechRecognizer` | 语音输入相关 |
| `ERROR` | 错误信息 |
| `WARNING` | 警告信息 |

**调试技巧：**

```bash
# 实时查看日志
tail -f ~/Library/Logs/OpenClaw\ Deck/*.log | grep -E "ERROR|WARNING"

# 查找特定问题
grep "connection" ~/Library/Logs/OpenClaw\ Deck/*.log
```

---

## 6. 技术细节

### 6.1 项目结构

```
openclaw-deck-swift/
├── docs/                      # 文档
│   ├── introduction.md        # 项目介绍
│   └── USER_GUIDE.md          # 使用说明书（本文件）
├── openclaw-deck-swift/       # Xcode 项目
│   ├── Models/                # 数据模型
│   ├── Views/                 # UI 组件
│   ├── ViewModels/            # 视图模型
│   └── Services/              # 服务层
└── script/                    # 构建脚本
```

### 6.2 数据流

```
用户操作 → View → ViewModel → GatewayClient → Gateway
                                        ↓
用户界面 ← View ← ViewModel ← GatewayClient ← Gateway 事件
```

### 6.3 与 Gateway 通信协议

**WebSocket 连接：**
```
ws://<gateway-host>:18789
```

**主要事件类型：**

| 事件 | 方向 | 说明 |
|------|------|------|
| `agent` | Gateway → Client | AI 回复内容 |
| `agent.done` | Gateway → Client | 回复完成 |
| `agent.error` | Gateway → Client | 回复错误 |
| `tick` | Gateway → Client | 保活心跳 |
| `health` | Gateway → Client | 健康检查 |

**消息格式：**

```json
{
  "runId": "agent-123-ABC",
  "seq": 46,
  "stream": "assistant",
  "data": {
    "text": "AI 回复内容"
  },
  "sessionKey": "agent:main:session-id"
}
```

### 6.4 消息显示逻辑

**设计决策：**
- ✅ **单条消息显示** - 避免碎片化
- ✅ **流式更新** - 实时显示 AI 回复
- ✅ **累积文本** - Gateway 发送完整文本

**原因：**
- Gateway 发送的是累积文本（每条包含前面所有内容）
- 无法可靠分割成多条消息
- 单条消息更清晰易读

### 6.5 性能考虑

**内存管理：**
- 消息历史缓存在内存中
- Session 切换时不重新加载
- 应用重启后从 Gateway 重新加载

**优化建议：**
- 保持 Session 数量 < 10
- 定期清理不用的 Session
- 长消息会自动分段显示

---

## 附录

### A. 相关资源

- **项目仓库：** [GitHub](https://github.com/openclaw/openclaw)
- **官方文档：** [OpenClaw Docs](https://docs.openclaw.ai)
- **问题反馈：** [GitHub Issues](https://github.com/openclaw/openclaw/issues)

### B. 版本历史

| 版本 | 日期 | 更新内容 |
|------|------|---------|
| 1.0 | 2026-02-26 | 初始版本 |

### C. 联系方式

- **开发者：** Alex
- **AI 助手：** 贾维斯 (Jarvis)

---

**文档结束**

如有问题，请查看 [故障排除](#5-故障排除) 章节或提交 Issue。
