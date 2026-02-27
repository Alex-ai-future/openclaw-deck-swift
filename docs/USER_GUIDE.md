# OpenClaw Deck Swift - 使用说明书

**版本：** 1.2  
**最后更新：** 2026-02-27  
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

**输入框自动增长：**
- 输入框会根据文本内容自动调整高度
- 最小高度：36pt（单行）
- 最大高度：150pt（约 7 行）
- 超过最大高度后自动内部滚动
- 背景容器跟随输入框高度，无空白区域

**语音输入（macOS/iOS）：**
1. 点击麦克风图标
2. 开始说话
3. 点击麦克风停止
4. 语音自动转为文字并发送

**消息显示：**
- ✅ **单条消息显示** - AI 回复显示为一条完整消息
- ✅ **流式更新** - 实时看到 AI 回复内容
- ✅ **段落分隔** - 长消息用空行分隔段落

### 2.3 滚动控制

**滚动到底部按钮：**
- 位置：聊天界面右下角
- 图标：向下箭头 ↓
- 功能：快速滚动到最新消息
- 使用场景：查看历史消息后快速返回

### 2.4 Session 排序

**功能说明**
- 通过拖拽方式重新排列 Session 顺序
- 自定义 Session 的显示顺序
- 排序结果自动保存

**使用方法**
1. 点击工具栏的排序按钮（↕️ 图标）
2. 在弹出的排序视图中，按住 Session 行拖拽到新位置
3. 点击 "Done" 保存排序结果

**界面说明**
- **拖拽手柄：** 每行左侧的 ≡ 图标
- **Session 名称：** 显示 Session ID
- **消息数量：** 右侧徽章显示该 Session 的消息总数

**注意事项**
- 排序会自动保存，下次启动应用时保持顺序
- 新建的 Session 会添加到列表末尾

### 2.5 设置配置

**打开设置：**
- macOS：点击工具栏的齿轮图标 ⚙️
- iOS/iPadOS：点击顶部导航栏的设置按钮

**可配置项：**

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| Gateway URL | WebSocket 地址 | `ws://127.0.0.1:18789` |
| Token | 认证 Token | 空 |

**操作按钮：**

| 按钮 | 功能 | 说明 |
|------|------|------|
| Apply & Reconnect | 应用并重连 | 保存配置并重新连接 Gateway |
| Reset Device Identity | 重置设备身份 | 清除存储的身份和 Token |
| Disconnect | 断开连接 | 返回欢迎界面 |

**保存配置：**
- 配置自动保存
- 下次启动自动加载

**关闭设置：** 点击右上角"Done"按钮或按 `Esc` 键

### 2.5 对话状态识别

**每个对话列顶部显示状态指示器（彩色圆点）：**

| 颜色 | 状态 | 说明 |
|------|------|------|
| 🟠 **橙色** | 处理中 | AI 正在处理消息（等待回复中） |
| 🟢 **绿色** | 未读消息 | AI 已完成回复，但用户未查看 |
| 🔵 **蓝色** | 空闲 | 无正在进行的操作，所有消息已读 |

**状态含义：**

**🟠 处理中（橙色）**
- AI 正在思考或生成回复
- 消息正在发送中
- 等待 Gateway 响应
- **用户操作：** 等待即可，无需操作

**🟢 未读消息（绿色）**
- AI 已完成回复
- 用户尚未查看（未滚动到底部）
- **用户操作：** 滚动到底部查看消息，状态自动变为蓝色

**🔵 空闲（蓝色）**
- 无正在进行的操作
- 所有消息已读
- 可以发送新消息

**如何切换到其他对话：**
1. **横向滚动** - 左右滑动切换不同对话列
2. **点击对话** - 点击任意对话列激活该对话
3. **创建新对话** - 点击顶部 `+` 按钮

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

### 5.6 Token Mismatch 问题

**症状：**
- 显示错误：`unauthorized: gateway token mismatch (open the dashboard URL and paste the token in Control UI settings)`
- 使用同样的 Token 在其他客户端可以连接，但 Deck Swift 无法连接
- 之前可以正常连接，突然无法连接

**原因：**
Deck Swift 会自动保存 Gateway 返回的 **Device Token**，后续连接时优先使用 Device Token 而不是用户输入的 Token。

**认证流程：**
```
首次连接：
用户输入 Token → Gateway 验证 → 成功 → Gateway 返回 Device Token → 保存到本地

后续连接：
读取保存的 Device Token → 发送给 Gateway → 验证失败 → Token Mismatch 错误
```

**为什么 Device Token 会失效：**
1. Gateway 重启后 Device Token 记录丢失
2. Gateway 配置变更，Device Token 被撤销
3. Device Token 过期或被轮换

**解决方案：**

**方法一：通过 UI 重置（推荐）**

1. 在 Welcome 界面点击右上角的 ⚙️ 设置按钮
2. 进入 Settings 界面
3. 点击 "Reset Device Identity" 按钮
4. 确认重置
5. 应用会清除保存的 Device Token，并使用你输入的 Token 重新连接

**方法二：命令行清除**

```bash
# 在 Xcode 控制台运行以下 Swift 代码
UserDefaults.standard.removeObject(forKey: "openclaw.deck.deviceToken.v1:ws://你的 Gateway 地址")
UserDefaults.standard.removeObject(forKey: "openclaw.deck.deviceIdentity.v1")
```

**方法三：删除应用数据**

```bash
# macOS - 删除应用配置
rm -rf ~/Library/Preferences/com.openclaw.deck.plist
rm -rf ~/Library/Application\ Support/com.openclaw.deck

# 然后重新打开应用
```

**预防措施：**

1. **记录 Token 变化** - 如果 Gateway 的 Token 发生变化，先重置 Device Identity
2. **Gateway 重启后注意** - Gateway 重启后可能需要重置 Device Identity
3. **使用固定 Token** - 在 Gateway 配置中设置固定的 `gateway.auth.token`

**调试日志：**

应用已添加详细日志，可以在 Xcode 控制台查看：

```
🔑 [AuthToken] Using device token: abcd********wxyz
🔍 [Connect Request] Sending connect request to Gateway
🔍 [Connect Request] Auth token (source: device): abcd********wxyz
🔐 [DeviceAuth] Built device auth payload: v2|device-id|...
📤 [WebSocket] Sending CONNECT frame: {"type":"req","id":"...","method":"connect",...}
```

- `source: device` - 使用的是保存的 Device Token
- `source: user` - 使用的是用户输入的 Token

如果看到 `source: device` 但连接失败，需要重置 Device Identity。

**相关配置位置：**

```
# Gateway 配置 (config.yaml)
gateway:
  auth:
    mode: token
    token: your-fixed-token  # 固定 Token，避免 Device Token 失效
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
