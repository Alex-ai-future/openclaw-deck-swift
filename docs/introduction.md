# OpenClaw Deck Swift

一款用于管理多个 OpenClaw Agent Session 的 iPadOS 应用，提供多列聊天界面，实时与 AI Agent 交互。

## 项目简介

OpenClaw Deck Swift 是 [openclaw-deck](../openclaw-deck) 的 Swift 原生实现版本。主要面向 iPadOS 平台，提供流畅的多 Session 聊天体验，未来计划支持 iOS 和 macOS。

### 核心价值

- **原生体验**：使用 SwiftUI 构建，完美适配 iPadOS 界面规范
- **多任务处理**：单页面多列布局，同时管理多个 Session
- **实时通信**：通过 WebSocket 与 OpenClaw Gateway 实时连接
- **数据同步**：所有数据存储在 Gateway，本地仅管理 Session Key

### 设计原则

- **单一 Agent**：使用固定的 Main Agent，不涉及多 Agent 管理
- **无本地持久化**：消息、状态等数据全部存储在 Gateway，避免数据冲突
- **Session 即会话**：每个 Session 代表一个独立的聊天会话

---

## 功能特性

### 1. 多 Session 管理

- 在单个页面中以多列布局展示多个 Session
- 每列独立管理一个聊天会话
- **创建 Session**：生成新的 sessionKey，开始新会话
- **删除 Session**：永久删除会话，**不可恢复**
- Session Key 由本地生成，消息历史存储在 Gateway

### 2. 实时聊天

- 发送消息并接收 Agent 流式响应
- 支持 Markdown 渲染（代码高亮、列表、标题等）
- 消息实时滚动显示

### 3. Verbose 日志

- 通过 `/verbose on` 命令开启 verbose 模式
- 当 Gateway 推送 verbose 信息时显示
- 通过 `/verbose off` 关闭

### 4. Gateway 配置

- 配置 Gateway WebSocket URL
- 配置认证 Token
- 连接状态实时显示
- 手动刷新按钮实现重连（无自动重连）

### 5. 未来功能

- [ ] Tool Use 信息展示
- [ ] Thinking 过程显示
- [ ] iOS 设备支持
- [ ] macOS 支持

---

## 技术架构

### 技术选型

| 组件 | 技术方案 |
|------|----------|
| UI 框架 | SwiftUI |
| 网络层 | URLSessionWebSocketTask（原生） |
| 架构模式 | MVVM |
| 状态管理 | @Observable / @StateObject |
| 数据持久化 | 仅 Session Key（其他数据在 Gateway） |
| 最低支持版本 | iPadOS 16.0 |

### 项目结构

```
openclaw-deck-swift/
├── App/
│   ├── OpenClawDeckApp.swift       # 应用入口
│   └── ContentView.swift           # 主视图
├── Models/
│   ├── GatewayFrame.swift          # WebSocket 帧模型
│   ├── SessionConfig.swift         # Session 配置模型
│   └── ChatMessage.swift           # 消息模型
├── ViewModels/
│   ├── DeckViewModel.swift         # 主界面状态管理
│   └── SessionColumnViewModel.swift # 单列状态管理
├── Views/
│   ├── DeckView.swift              # 多列布局视图
│   ├── SessionColumnView.swift     # 单列 Session 视图
│   ├── ChatInputView.swift         # 输入框组件
│   ├── MessageView.swift           # 消息显示组件
│   ├── SettingsView.swift          # 设置页面
│   └── Components/                 # 可复用组件
├── Services/
│   ├── GatewayClient.swift         # WebSocket 客户端
│   └── KeychainService.swift       # Token 安全存储
├── Utils/
│   └── Extensions.swift            # 扩展工具
├── Resources/
│   └── Assets.xcassets             # 资源文件
└── docs/
    └── introduction.md             # 本文档
```

### 架构图

```
┌─────────────────────────────────────────────────────────────┐
│                         SwiftUI Views                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │ DeckView    │  │ SessionColumn│  │ SettingsView│          │
│  │ (多列布局)   │  │ View (单列) │  │ (配置页面)   │          │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘          │
│         │                │                │                  │
│         ▼                ▼                ▼                  │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    ViewModels                            ││
│  │  DeckViewModel ◄─── SessionColumnViewModel(s)            ││
│  │  • 管理 Session Key 列表                                 ││
│  │  • 创建/删除 Session                                     ││
│  └─────────────────────────┬───────────────────────────────┘│
└────────────────────────────┼────────────────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────┐
│                       Services                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 GatewayClient                         │   │
│  │  • WebSocket 连接管理                                  │   │
│  │  • 请求/响应关联                                        │   │
│  │  • 事件流订阅                                          │   │
│  │  • 手动重连                                            │   │
│  └─────────────────────────┬───────────────────────────┘   │
└────────────────────────────┼────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │ OpenClaw Gateway │
                    │ Main Agent       │
                    │ (消息/状态存储)   │
                    └────────────────┘
```

---

## 通信协议

应用通过 WebSocket 与 OpenClaw Gateway 通信，协议参考：[OpenClaw Architecture](https://docs.openclaw.ai/concepts/architecture)

### 帧格式

```swift
// 请求帧
struct GatewayRequest: Codable {
    let type: String = "req"
    let id: String
    let method: String
    let params: [String: Any]?
}

// 响应帧
struct GatewayResponse: Codable {
    let type: String = "res"
    let id: String
    let ok: Bool
    let payload: Any?
    let error: GatewayError?
}

// 事件帧
struct GatewayEvent: Codable {
    let type: String = "event"
    let event: String
    let payload: Any?
    let seq: Int?
    let stateVersion: Int?
}
```

### 主要 API 方法

| 方法 | 说明 | 参数 |
|------|------|------|
| `connect` | 建立连接握手 | client, scopes, auth |
| `agent` | 执行 Agent 轮次 | agentId, message, sessionKey |

### 事件类型

| 事件 | 说明 |
|------|------|
| `agent.content` | Agent 回复内容（流式） |
| `agent.thinking` | Agent 思考过程 |
| `agent.tool_use` | 工具调用信息 |
| `agent.done` | Agent 轮次完成 |
| `agent.error` | Agent 错误 |
| `agent.verbose` | Verbose 日志信息（需 `/verbose on`） |

### 斜杠命令

| 命令 | 说明 |
|------|------|
| `/verbose on` | 开启 verbose 模式，显示 Gateway 推送的详细日志 |
| `/verbose off` | 关闭 verbose 模式 |

---

## 数据模型

### SessionConfig - Session 配置

```swift
struct SessionConfig: Identifiable {
    let id: String              // 本地生成的唯一标识
    let sessionKey: String      // 用于 Gateway 的 session key
    let createdAt: Date
    var name: String?           // 可选的用户自定义名称
}
```

### ChatMessage - 聊天消息

```swift
struct ChatMessage: Codable, Identifiable {
    let id: String
    let role: MessageRole       // user, assistant, system
    let text: String
    let timestamp: Date
    var streaming: Bool?
    var thinking: Bool?
    var toolUse: ToolUseInfo?
    var runId: String?
}

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}
```

### AppConfig - 应用配置

```swift
struct AppConfig: Codable {
    var gatewayUrl: String      // 默认: ws://127.0.0.1:18789
    var token: String?
    let mainAgentId: String     // 固定的 Main Agent ID
}

// 默认配置
extension AppConfig {
    static let `default` = AppConfig(
        gatewayUrl: "ws://127.0.0.1:18789",
        token: nil,
        mainAgentId: "main"  // 或其他固定值
    )
}
```

### DeckState - 应用状态

```swift
@Observable
class DeckState {
    var config: AppConfig
    var sessions: [SessionConfig]   // 本地管理的 Session 列表
    var gatewayConnected: Bool
    
    // 每个 Session 的消息从 Gateway 实时获取
    // 不在本地存储
}
```

---

## UI 设计

### 主界面布局

```
┌────────────────────────────────────────────────────────────────┐
│  OpenClaw Deck                               [🔄] [⚙️]          │  ← 顶部栏（刷新、设置）
├────────────────────────────────────────────────────────────────┤
│ ● Connected to ws://127.0.0.1:18789                            │  ← 状态栏
├──────────────┬──────────────┬──────────────┬──────────────────┤
│  Session 1   │  Session 2   │  Session 3   │  + New Session   │
│              │              │              │                  │
│  ┌─────────┐ │  ┌─────────┐ │  ┌─────────┐ │                  │
│  │ Message │ │  │ Message │ │  │ Message │ │                  │
│  │ Message │ │  │ Message │ │  │ Message │ │                  │
│  │ Message │ │  │ Message │ │  │         │ │                  │
│  └─────────┘ │  └─────────┘ │  └─────────┘ │                  │
│              │              │              │                  │
│  ┌─────────┐ │  ┌─────────┐ │  ┌─────────┐ │                  │
│  │ Input   │ │  │ Input   │ │  │ Input   │ │                  │
│  └─────────┘ │  └─────────┘ │  └─────────┘ │                  │
│      [x]     │      [x]     │      [x]     │                  │  ← 删除按钮
└──────────────┴──────────────┴──────────────┴──────────────────┘
```

### 单列视图结构

```
┌──────────────────────┐
│ Session 1        [x] │  ← Session 头部（名称、删除按钮）
├──────────────────────┤
│                      │
│   消息滚动区域        │  ← ScrollView
│                      │
│   User: 你好         │
│   ┌────────────────┐ │
│   │ Agent 回复      │ │  ← Markdown 渲染
│   │ 支持代码高亮    │ │
│   └────────────────┘ │
│                      │
├──────────────────────┤
│ ┌──────────────────┐ │
│ │ 输入消息...       │ │  ← 输入框
│ └──────────────────┘ │
│              [发送]   │  ← 发送按钮
└──────────────────────┘
```

### 设置页面

```
┌────────────────────────────────────┐
│         Settings                   │
├────────────────────────────────────┤
│                                    │
│  Gateway Configuration             │
│  ┌──────────────────────────────┐  │
│  │ URL: ws://127.0.0.1:18789    │  │
│  └──────────────────────────────┘  │
│  ┌──────────────────────────────┐  │
│  │ Token: ••••••••••••          │  │
│  └──────────────────────────────┘  │
│                                    │
│  Connection Status                 │
│  ● Connected                       │
│                                    │
│  [Refresh Connection]              │  ← 手动刷新按钮
│                                    │
├────────────────────────────────────┤
│  Main Agent                        │
│  ID: main (fixed)                  │  ← 固定显示
│                                    │
├────────────────────────────────────┤
│  About                             │
│  Version: 1.0.0                    │
│  OpenClaw Deck Swift               │
└────────────────────────────────────┘
```

---

## 开发路线

### 第一阶段：核心功能 (MVP)

- [ ] 项目结构搭建
- [ ] GatewayClient WebSocket 实现
- [ ] 基本数据模型
- [ ] 多列布局 UI
- [ ] Session 创建/删除功能
- [ ] 发送消息功能
- [ ] 流式接收响应
- [ ] 设置页面（URL、Token、手动刷新）

### 第二阶段：增强功能

- [ ] Markdown 渲染
- [ ] 代码语法高亮
- [ ] Tool Use 信息展示
- [ ] Thinking 过程显示
- [ ] Verbose 日志面板（`/verbose on`）

### 第三阶段：跨平台

- [ ] iOS 适配
- [ ] iPhone 界面优化
- [ ] macOS 支持
- [ ] Catalyst 适配

### 第四阶段：高级功能

- [ ] 深色/浅色主题
- [ ] 多语言支持
- [ ] 快捷键支持
- [ ] Split View 优化

---

## 相关链接

- [OpenClaw 官网](https://openclaw.ai)
- [OpenClaw 文档](https://docs.openclaw.ai)
- [openclaw-deck (TypeScript 版本)](../openclaw-deck)
- [ClawHub 社区](https://clawhub.com)

---

## 参考资源

### Swift WebSocket

- [URLSessionWebSocketTask | Apple Developer](https://developer.apple.com/documentation/foundation/urlsessionwebsockettask)
- [SwiftUI 网络编程最佳实践](https://developer.apple.com/documentation/swiftui/managing-user-interface-state)

### 架构模式

- [MVVM with SwiftUI](https://developer.apple.com/documentation/swiftui/managing-user-interface-state)
- [Observable Framework](https://developer.apple.com/documentation/observation)

### OpenClaw 协议

- [Gateway Protocol](https://docs.openclaw.ai/concepts/architecture)
- [WebSocket Frame Format](https://docs.openclaw.ai/reference/websocket)