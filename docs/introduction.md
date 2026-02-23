# OpenClaw Deck Swift

一款用于管理多个 OpenClaw Agent 的 iPadOS 应用，提供多列聊天界面，实时与 AI Agent 交互。

## 项目简介

OpenClaw Deck Swift 是 [openclaw-deck](../openclaw-deck) 的 Swift 原生实现版本。主要面向 iPadOS 平台，提供流畅的多 Agent 聊天体验，未来计划支持 iOS 和 macOS。

### 核心价值

- **原生体验**：使用 SwiftUI 构建，完美适配 iPadOS 界面规范
- **多任务处理**：单页面多列布局，同时与多个 Agent 交互
- **实时通信**：通过 WebSocket 与 OpenClaw Gateway 实时连接
- **轻量设计**：数据不本地保存，全部同步自 Gateway

---

## 功能特性

### 1. 多 Agent 管理

- 在单个页面中以多列布局展示多个 Agent
- 每列独立管理一个 Agent 会话
- 支持添加、删除、重命名 Agent
- 可配置 Agent 的模型、上下文等参数

### 2. 实时聊天

- 发送消息并接收 Agent 流式响应
- 支持 Markdown 渲染（代码高亮、列表、标题等）
- 消息实时滚动显示
- 支持清空当前会话

### 3. Verbose 日志

- 显示 Agent 执行过程的详细信息
- 便于调试和了解 Agent 行为
- 可展开/收起日志详情

### 4. Gateway 配置

- 配置 Gateway WebSocket URL
- 配置认证 Token
- 支持连接状态实时显示
- 自动重连机制

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
| 数据持久化 | 无（全部来自 Gateway） |
| 最低支持版本 | iPadOS 16.0 |

### 项目结构

```
openclaw-deck-swift/
├── App/
│   ├── OpenClawDeckApp.swift       # 应用入口
│   └── ContentView.swift           # 主视图
├── Models/
│   ├── GatewayFrame.swift          # WebSocket 帧模型
│   ├── AgentConfig.swift           # Agent 配置模型
│   ├── AgentSession.swift          # 会话状态模型
│   └── ChatMessage.swift           # 消息模型
├── ViewModels/
│   ├── DeckViewModel.swift         # 主界面状态管理
│   └── AgentColumnViewModel.swift  # 单列状态管理
├── Views/
│   ├── DeckView.swift              # 多列布局视图
│   ├── AgentColumnView.swift       # 单列 Agent 视图
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
│  │ DeckView    │  │ AgentColumn │  │ SettingsView│          │
│  │ (多列布局)   │  │ View (单列) │  │ (配置页面)   │          │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘          │
│         │                │                │                  │
│         ▼                ▼                ▼                  │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    ViewModels                            ││
│  │  DeckViewModel ◄─── AgentColumnViewModel(s)              ││
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
│  │  • 自动重连                                            │   │
│  └─────────────────────────┬───────────────────────────┘   │
└────────────────────────────┼────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │ OpenClaw Gateway │
                    │ WebSocket API    │
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
| `agents.create` | 创建新 Agent | id, name, model, context |
| `agents.update` | 更新 Agent 配置 | id, name?, model?, context? |
| `agents.delete` | 删除 Agent | agentId |
| `health` | 获取 Gateway 健康状态 | - |

### 事件类型

| 事件 | 说明 |
|------|------|
| `agent.content` | Agent 回复内容（流式） |
| `agent.thinking` | Agent 思考过程 |
| `agent.tool_use` | 工具调用信息 |
| `agent.done` | Agent 轮次完成 |
| `agent.error` | Agent 错误 |

---

## 数据模型

### AgentConfig - Agent 配置

```swift
struct AgentConfig: Codable, Identifiable {
    let id: String
    let name: String
    let icon: String
    let accent: String          // 主题色（十六进制）
    var workspace: String?
    var model: String?          // 模型覆盖
    let context: String         // Agent 角色描述
    var shell: String?          // Agent 运行时 shell
}
```

### AgentSession - 会话状态

```swift
struct AgentSession: ObservableObject {
    let agentId: String
    var status: AgentStatus     // idle, streaming, thinking, error, disconnected
    var messages: [ChatMessage]
    var activeRunId: String?
    var tokenCount: Int
    var connected: Bool
    var usage: SessionUsage?
}

enum AgentStatus: String, Codable {
    case idle
    case streaming
    case thinking
    case toolUse = "tool_use"
    case error
    case disconnected
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

### DeckConfig - 应用配置

```swift
struct DeckConfig: Codable {
    var gatewayUrl: String      // 默认: ws://127.0.0.1:18789
    var token: String?
    var agents: [AgentConfig]
}
```

---

## UI 设计

### 主界面布局

```
┌────────────────────────────────────────────────────────────────┐
│  [☰] OpenClaw Deck                              [⚙️] [+]       │  ← 顶部栏
├────────────────────────────────────────────────────────────────┤
│ ● Connected to ws://127.0.0.1:18789                            │  ← 状态栏
├──────────────┬──────────────┬──────────────┬──────────────────┤
│   Agent 1    │   Agent 2    │   Agent 3    │   Agent 4        │
│   🤖 Claude  │   🔷 GPT     │   🟢 Custom  │   + Add Agent    │
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
└──────────────┴──────────────┴──────────────┴──────────────────┘
```

### 单列视图结构

```
┌──────────────────────┐
│ 🤖 Agent Name    [x] │  ← Agent 头部（图标、名称、关闭按钮）
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
│ [📎] [🎤]      [发送] │  ← 工具栏
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
│  [Test Connection]                 │
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
- [ ] 发送消息功能
- [ ] 流式接收响应
- [ ] 基本设置页面

### 第二阶段：增强功能

- [ ] Markdown 渲染
- [ ] 代码语法高亮
- [ ] Tool Use 信息展示
- [ ] Thinking 过程显示
- [ ] Verbose 日志面板
- [ ] Agent 配置管理

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