# OpenClaw Deck Swift

一款用于管理多个 OpenClaw Agent Session 的 iPadOS 应用，提供多列聊天界面，实时与 AI Agent 交互。

## 项目简介

OpenClaw Deck Swift 是 [openclaw-deck](../openclaw-deck) 的 Swift 原生实现版本。主要面向 iPadOS 平台，提供流畅的多 Session 聊天体验，未来计划支持 iOS 和 macOS。

### 核心价值

- **原生体验**：使用 SwiftUI 构建，完美适配 iPadOS 界面规范
- **多任务处理**：单页面多列布局，同时管理多个 Session
- **实时通信**：通过 WebSocket 与 OpenClaw Gateway 实时连接
- **数据同步**：所有数据存储在 Gateway，本地仅管理 Session Key

### 平台支持

| 平台 | 状态 | 说明 |
|------|------|------|
| iPadOS | ✅ 主要目标 | 完整支持，UI 优化 |
| macOS | ✅ 已支持 | 可运行，代码已编译通过 |
| iOS | 🔜 未来支持 | 计划中 |

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

### 3. Gateway 配置

- 配置 Gateway WebSocket URL
- 配置认证 Token
- 连接状态实时显示
- 手动刷新按钮实现重连（无自动重连）

### 4. 语音输入

- 点击麦克风按钮开始语音识别
- 支持 iOS/iPadOS/macOS 语音识别权限管理
- 实时转录语音为文本
- **自动停止机制**：发送消息时自动停止听写，防止状态冲突
- **状态保护**：使用 `isStopping` 标志防止 cancel 后的回调污染输入框
- **跨平台支持**：SpeechRecognizer 提升到 SessionColumnView 层级，统一管理

### 5. 未来功能

- [ ] iOS 设备支持（iPhone 适配）
- [ ] macOS UI 优化（菜单栏、快捷键）
- [ ] 自动重连机制
- [ ] Session 归档功能

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
| Markdown 渲染 | [MarkdownView](https://github.com/liyanan2004/MarkdownView) |
| 最低支持版本 | iPadOS 18.0 / macOS 15.0 |

### 项目结构

```
openclaw-deck-swift/
├── .gitignore                      # Git 忽略文件（Xcode 相关）
├── openclaw-deck-swift/            # Xcode 项目主目录
│   ├── openclaw-deck-swift/        # App 目标
│   │   ├── openclaw_deck_swiftApp.swift   # 应用入口
│   │   ├── ContentView.swift       # 主视图
│   │   ├── Models/                 # 数据模型
│   │   │   ├── AppConfig.swift     # 应用配置
│   │   │   ├── ChatMessage.swift   # 聊天消息模型
│   │   │   ├── GatewayFrame.swift  # Gateway 帧格式
│   │   │   ├── SessionConfig.swift # Session 配置
│   │   │   └── SessionState.swift  # Session 运行时状态
│   │   ├── ViewModels/             # 视图模型
│   │   │   └── DeckViewModel.swift # 主 ViewModel（管理多 Session）
│   │   ├── Views/                  # 视图组件
│   │   │   ├── ContentView.swift   # 主容器视图
│   │   │   ├── DeckView.swift      # 多列布局容器
│   │   │   ├── SessionColumnView.swift # 单列聊天视图
│   │   │   ├── SettingsView.swift  # 设置页面
│   │   │   └── DictationButton.swift # 语音输入按钮
│   │   ├── Services/               # 服务层
│   │   │   ├── GatewayClient.swift # WebSocket 客户端
│   │   │   └── SpeechRecognizer.swift # 语音识别服务
│   │   ├── Utils/                  # 工具类
│   │   │   └── UserDefaultsStorage.swift # UserDefaults 存储
│   │   └── Assets.xcassets         # 资源文件
│   ├── openclaw-deck-swift.xcodeproj/  # Xcode 项目文件
│   ├── openclaw-deck-swiftTests/       # 单元测试
│   │   └── SessionConfigTests.swift    # SessionConfig 测试
│   └── openclaw-deck-swiftUITests/     # UI 测试
├── script/
│   ├── build_ipados.sh           # iPadOS 构建脚本
│   ├── build_macos.sh            # macOS 构建脚本
│   └── run_unit_tests.sh         # 单元测试脚本
└── docs/
    └── introduction.md             # 本文档
```

### 架构图

```
┌─────────────────────────────────────────────────────────────┐
│                         SwiftUI Views                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │ ContentView │  │ DeckView    │  │ SessionColumn│          │
│  │ (主容器)     │  │ (多列布局)   │  │ View (单列)  │          │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘          │
│         │                │                │                  │
│         ▼                ▼                ▼                  │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    ViewModels                            ││
│  │              DeckViewModel (统一管理)                     ││
│  │  • 管理 Session Key 列表                                 ││
│  │  • 创建/删除 Session                                     ││
│  │  • 发送消息/处理事件                                     ││
│  │  • 加载历史消息                                          ││
│  └─────────────────────────┬───────────────────────────────┘│
└────────────────────────────┼────────────────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────┐
│                       Services                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 GatewayClient                         │   │
│  │  • WebSocket 连接管理                                  │   │
│  │  • 挑战握手认证（nonce 验证）                           │   │
│  │  • 请求/响应关联                                        │   │
│  │  • 事件流订阅                                          │   │
│  │  • 设备 Identity/Token 管理                            │   │
│  └─────────────────────────┬───────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              SpeechRecognizer                         │   │
│  │  • 语音识别服务                                        │   │
│  │  • 麦克风权限管理                                      │   │
│  └─────────────────────────────────────────────────────┘   │
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
| `sessions_history` | 获取 Session 历史消息 | sessionKey |
| `sessions_list` | 列出活跃的 Sessions | - |
| `session_status` | 获取 Session 状态 | sessionKey |

### 事件类型

| 事件 | 说明 |
|------|------|
| `agent` | Agent 事件（新格式：runId, stream, data, sessionKey） |
| `agent.content` | Agent 回复内容（流式，旧格式兼容） |
| `agent.thinking` | Agent 思考过程（忽略） |
| `agent.tool_use` | 工具调用信息（忽略） |
| `agent.done` | Agent 轮次完成 |
| `agent.error` | Agent 错误 |

> **注意**：Verbose 相关功能通过 OpenClaw 原生命令（如 `/verbose on`）控制，由用户自行输入。

---

## 通信实现逻辑

### 整体通信流程

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           连接建立流程                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  App                    GatewayClient                  Gateway          │
│   │                          │                            │             │
│   │   connect(url, token)    │                            │             │
│   │ ───────────────────────► │                            │             │
│   │                          │   WebSocket Connect        │             │
│   │                          │ ──────────────────────────►│             │
│   │                          │                            │             │
│   │                          │   req: connect             │             │
│   │                          │   { auth: { token } }      │             │
│   │                          │ ──────────────────────────►│             │
│   │                          │                            │             │
│   │                          │   res: connect             │             │
│   │                          │ ◄────────────────────────── │             │
│   │                          │   { ok: true }             │             │
│   │                          │                            │             │
│   │   onConnection(true)     │                            │             │
│   │ ◄─────────────────────── │                            │             │
│   │                          │                            │             │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                           发送消息流程                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  App                    GatewayClient                  Gateway          │
│   │                          │                            │             │
│   │   runAgent(msg, sessionKey)                          │             │
│   │ ───────────────────────► │                            │             │
│   │                          │   req: agent               │             │
│   │                          │   { agentId, message,      │             │
│   │                          │     sessionKey, idempotencyKey }         │
│   │                          │ ──────────────────────────►│             │
│   │                          │                            │             │
│   │                          │   res: agent               │             │
│   │                          │ ◄────────────────────────── │             │
│   │                          │   { runId, status }        │             │
│   │                          │                            │             │
│   │                          │   event: agent.content     │             │
│   │                          │ ◄────────────────────────── │             │
│   │   onEvent(content)       │   (streaming...)           │             │
│   │ ◄─────────────────────── │                            │             │
│   │                          │                            │             │
│   │                          │   event: agent.done        │             │
│   │                          │ ◄────────────────────────── │             │
│   │   onEvent(done)          │                            │             │
│   │ ◄─────────────────────── │                            │             │
│   │                          │                            │             │
└─────────────────────────────────────────────────────────────────────────┘
```

### GatewayClient 类设计

```swift
import Foundation
import CryptoKit

// MARK: - Types

struct PendingRequest {
    let continuation: CheckedContinuation<GatewayResponse, Error>
    let timeout: Task<Void, Never>
}

// MARK: - GatewayClient

@MainActor
@Observable
class GatewayClient {

    // MARK: - Configuration

    let url: URL
    let token: String?              // 用户手动输入，不存储
    private let isMock: Bool

    // MARK: - State

    private(set) var connected: Bool = false
    private(set) var connectionError: String?
    private(set) var isConnecting: Bool = false
    private var webSocket: URLSessionWebSocketTask?
    private var pendingRequests: [String: PendingRequest] = [:]
    private var messageCounter: Int = 0
    private var connectNonce: String?
    private var connectSent: Bool = false
    private var challengeCallback: ((String) -> Void)?
    private var challengeCompleted: Bool = false

    // MARK: - Callbacks

    var onEvent: ((GatewayEvent) -> Void)?
    var onConnection: ((Bool) -> Void)?

    // MARK: - Constants

    private let requestTimeout: TimeInterval = 30
    private let connectChallengeTimeout: TimeInterval = 6
    private let operatorScopes = ["operator.read", "operator.write"]
    private let deviceIdentityStorageKey = "openclaw.deck.deviceIdentity.v1"
    private let deviceTokenStorageKeyPrefix = "openclaw.deck.deviceToken.v1:"

    // MARK: - Initialization

    init(url: URL, token: String? = nil, isMock: Bool = false) {
        self.url = url
        self.token = token
        self.isMock = isMock
    }

    // MARK: - Public Methods

    /// 建立连接并完成握手
    func connect() async {
        // 实现细节见源代码
    }

    /// 断开连接
    func disconnect() {
        // 实现细节见源代码
    }

    /// 发送请求并等待响应
    func request(method: String, params: [String: Any]? = nil) async throws -> GatewayResponse {
        // 实现细节见源代码
    }

    /// 执行 Agent 轮次
    func runAgent(agentId: String, message: String, sessionKey: String? = nil) async throws -> (runId: String, status: String) {
        // 实现细节见源代码
    }

    /// 获取 Session 历史消息
    func getSessionHistory(sessionKey: String) async throws -> [ChatMessage]? {
        // 实现细节见源代码
    }
}
```

### 请求/响应关联机制

```
┌─────────────────────────────────────────────────────────────────┐
│                      Request/Response Flow                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. 生成唯一 ID                                                   │
│     id = "deck-{counter}-{timestamp}"                            │
│                                                                  │
│  2. 创建 PendingRequest 并存入 Map                                │
│     pendingRequests[id] = PendingRequest(                        │
│         continuation: continuation,                              │
│         timeout: 30s                                             │
│     )                                                            │
│                                                                  │
│  3. 发送请求帧                                                    │
│     { type: "req", id: "deck-1-xxx",                             │
│       method: "agent", params: {...} }                           │
│                                                                  │
│  4. 等待响应                                                      │
│     ├─ 成功：pendingRequests[id].resolve(payload)                │
│     ├─ 失败：pendingRequests[id].reject(error)                   │
│     └─ 超时：删除 pendingRequest，reject timeout error           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 事件处理

```swift
// 事件类型定义
struct GatewayEvent {
    let type: String = "event"
    let event: String
    let payload: Any?
    let seq: Int?
    let stateVersion: Int?

    init(from json: [String: Any]) {
        self.event = json["event"] as? String ?? ""
        self.payload = json["payload"]
        self.seq = json["seq"] as? Int
        self.stateVersion = json["stateVersion"] as? Int
    }
}

// 新格式 agent 事件处理
func handleAgentEvent(_ event: GatewayEvent) {
    guard let payload = event.payload as? [String: Any],
          let runId = payload["runId"] as? String,
          let stream = payload["stream"] as? String,
          let sessionKey = payload["sessionKey"] as? String
    else {
        print("Invalid agent event payload")
        return
    }

    switch stream {
    case "assistant":
        // 流式内容：{ data: { delta: "..." } } 或 { data: { text: "..." } }
        if let data = payload["data"] as? [String: Any] {
            if let delta = data["delta"] as? String {
                appendToAssistantMessage(runId: runId, text: delta)
            } else if let text = data["text"] as? String {
                replaceAssistantMessage(runId: runId, text: text)
            }
        }

    case "lifecycle":
        // 生命周期：{ data: { phase: "start" | "end" } }
        if let data = payload["data"] as? [String: Any],
           let phase = data["phase"] as? String {
            switch phase {
            case "start": status = .thinking
            case "end": status = .idle
            default: break
            }
        }

    case "tool_use":
        // 忽略工具调用事件
        break

    default:
        break
    }
}
```

---

## 数据模型

### SessionConfig - Session 配置

```swift
struct SessionConfig: Codable, Identifiable {
    let id: String              // 本地生成的唯一标识
    let sessionKey: String      // 用于 Gateway 的 session key
    let createdAt: Date
    var name: String?           // 可选的用户自定义名称
    var icon: String?           // 图标（可选）
    var accentColor: String?    // 主题色（可选）
    var context: String?        // 上下文描述（可选）
}

// Session ID 生成工具
extension SessionConfig {
    /// 从名称生成 Session ID（小写，替换特殊字符为连字符）
    static func generateId(from name: String) -> String {
        let sanitized = name
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        return sanitized.isEmpty ? "session-\(Date().timeIntervalSince1970)" : sanitized
    }

    /// 从 Session ID 生成 Session Key（格式：agent:main:{sessionId}）
    static func generateSessionKey(sessionId: String) -> String {
        return "agent:main:\(sessionId)"
    }
}
```

### SessionState - Session 运行时状态

```swift
@Observable
class SessionState {
    let sessionId: String
    let sessionKey: String          // "agent:main:{sessionId}"

    // 消息列表（从 Gateway 加载 + 流式更新）
    var messages: [ChatMessage] = []

    // 加载状态
    var historyLoaded: Bool = false
    var isHistoryLoading: Bool = false

    // 当前状态
    var status: SessionStatus = .idle
    var activeRunId: String?        // 当前活跃的 runId（用于关联流式响应）

    // 计算属性
    var lastMessageAt: Date? { messages.last?.timestamp }
    var messageCount: Int { messages.count }

    init(sessionId: String, sessionKey: String) {
        self.sessionId = sessionId
        self.sessionKey = sessionKey
    }

    // 消息管理方法
    func appendMessage(_ message: ChatMessage) { ... }
    func updateLastMessage(text: String) { ... }
    func appendToLastMessage(text: String) { ... }
    func clearMessages() { ... }
}

enum SessionStatus: Equatable {
    case idle           // 空闲
    case thinking       // 思考中
    case streaming      // 流式输出中
    case error(String)  // 错误状态
}
```

### ChatMessage - 聊天消息

```swift
struct ChatMessage: Codable, Identifiable {
    let id: String
    let role: MessageRole       // user, assistant, system
    let text: String
    let timestamp: Date
    var streaming: Bool?        // 是否正在流式输出
    var thinking: Bool?         // 是否在思考中
    var toolUse: ToolUseInfo?   // 工具调用信息
    var runId: String?          // 关联的 runId
    var isLoaded: Bool          // 是否已加载（区分历史消息和新消息）
}

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
    case tool          // 工具调用
    case status        // 状态消息
    case parameter     // 参数消息
    case thinking      // 思考内容
}

struct ToolUseInfo: Codable {
    let toolName: String      // 工具名称
    let input: String         // 输入参数
    let output: String?       // 输出结果
    let status: String        // 执行状态
}
```

### AppConfig - 应用配置

```swift
struct AppConfig: Codable {
    var gatewayUrl: String          // 默认：ws://127.0.0.1:18789
    var token: String?              // 用户手动输入，不持久化存储
    let mainAgentId: String         // 固定的 Main Agent ID
    let minSupportedVersion: String // 最低支持版本

    static let `default` = AppConfig(
        gatewayUrl: "ws://127.0.0.1:18789",
        token: nil,
        mainAgentId: "main",
        minSupportedVersion: "18.0"
    )

    // 验证属性
    var isValidGatewayUrl: Bool { ... }
    var isValidToken: Bool { ... }
    var isComplete: Bool { ... }
    var isDefault: Bool { ... }
}
```

> **注意**：Token 由用户在设置页面手动输入，通过 UserDefaults 存储，应用重启后会自动加载。

---

## Messages 管理逻辑

### 数据存储架构

```
┌─────────────────────────────────────────────────────────────────┐
│                      消息数据存储位置                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  OpenClaw Gateway（持久化）       本地 App（内存缓存）            │
│  ├─ 完整消息历史                   ├─ SessionState.messages      │
│  ├─ Session 状态                   ├─ 当前会话的消息缓存          │
│  ├─ Token 统计                     └─ App 关闭后清空             │
│  └─ 跨设备同步                                                  │
│                                                                  │
│  优势：                          优势：                          │
│  • 数据不丢失                    • 快速访问                      │
│  • 多设备同步                    • 流式更新                      │
│  • 无本地存储冲突                • 实时 UI 更新                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 启动时加载历史消息

```
┌─────────────────────────────────────────────────────────────────┐
│                       应用启动流程                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. 用户输入 Gateway URL 和 Token                                │
│                     │                                            │
│                     ▼                                            │
│  2. GatewayClient.connect()                                      │
│                     │                                            │
│                     ▼                                            │
│  3. WebSocket 连接成功                                           │
│                     │                                            │
│                     ▼                                            │
│  4. 为每个 Session 调用 sessions_history                         │
│     ┌────────────────────────────────────────┐                  │
│     │ 请求：                                  │                  │
│     │ {                                      │                  │
│     │   "type": "req",                       │                  │
│     │   "id": "deck-1-xxx",                  │                  │
│     │   "method": "sessions_history",        │                  │
│     │   "params": {                          │                  │
│     │     "sessionKey": "agent:main:session1"│                  │
│     │   }                                    │                  │
│     │ }                                      │                  │
│     └────────────────────────────────────────┘                  │
│                     │                                            │
│                     ▼                                            │
│  5. 响应历史消息                                                  │
│     ┌────────────────────────────────────────┐                  │
│     │ {                                      │                  │
│     │   "type": "res",                       │                  │
│     │   "id": "deck-1-xxx",                  │                  │
│     │   "ok": true,                          │                  │
│     │   "payload": {                         │                  │
│     │     "messages": [                      │                  │
│     │       { "role": "user", "text": "..." },│                 │
│     │       { "role": "assistant", "text": "..." }│             │
│     │     ]                                  │                  │
│     │   }                                    │                  │
│     │ }                                      │                  │
│     └────────────────────────────────────────┘                  │
│                     │                                            │
│                     ▼                                            │
│  6. 将历史消息填充到 SessionState.messages                       │
│                     │                                            │
│                     ▼                                            │
│  7. UI 显示历史消息                                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### SessionState 完整设计

```swift
@Observable
class SessionState {
    let sessionId: String
    let sessionKey: String          // "agent:main:{sessionId}"

    // 消息列表（从 Gateway 加载 + 流式更新）
    var messages: [ChatMessage] = []

    // 当前状态
    var status: SessionStatus = .idle
    var activeRunId: String?

    // 连接状态
    var connected: Bool = false

    // Token 使用统计（从 Gateway 获取）
    var tokenCount: Int = 0
    var usage: SessionUsage?

    // 历史消息是否已加载
    var historyLoaded: Bool = false
    var isHistoryLoading: Bool = false

    init(sessionId: String, sessionKey: String) {
        self.sessionId = sessionId
        self.sessionKey = sessionKey
    }
}

enum SessionStatus: Equatable {
    case idle           // 空闲
    case thinking       // 思考中
    case streaming      // 流式输出中
    case error(String)  // 错误状态
}
```

### 流式消息更新流程

```
┌─────────────────────────────────────────────────────────────────┐
│                      流式消息更新流程                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. 用户发送消息                                                 │
│     ├─ 创建 user 消息 { role: "user", text }                     │
│     └─ 立即添加到 messages 数组                                  │
│                                                                  │
│  2. 调用 runAgent()                                              │
│     ├─ 返回 runId                                                │
│     └─ 创建 assistant 占位消息                                   │
│        { role: "assistant", text: "", streaming: true, runId }   │
│                                                                  │
│  3. 接收流式事件                                                  │
│     │                                                            │
│     ├─ event: "agent" → stream: "assistant"                      │
│     │   └─ data.delta 追加到 text                                │
│     │      messages[index].text += delta                         │
│     │      (SwiftUI 自动更新 UI)                                  │
│     │                                                            │
│     ├─ event: "agent" → stream: "lifecycle" → phase: "end"       │
│     │   └─ messages[index].streaming = false                     │
│     │      status = .idle                                        │
│     │                                                            │
│     └─ event: "agent" → stream: "tool_use"                       │
│         └─ status = .toolUse                                     │
│                                                                  │
│  4. 通过 sessionKey 关联 Session                                 │
│     └─ sessionKey: "agent:main:{sessionId}"                      │
│         从中提取 sessionId 更新对应 Session                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### GatewayClient 扩展 - 加载历史

```swift
extension GatewayClient {

    /// 获取 Session 历史消息
    func getSessionHistory(sessionKey: String) async throws -> [ChatMessage]? {
        let result = try await request(
            method: "sessions_history",
            params: ["sessionKey": sessionKey]
        )

        guard let dict = result as? [String: Any],
              let messagesData = dict["messages"] as? [[String: Any]] else {
            return []
        }

        return messagesData.compactMap { try? ChatMessage(from: $0) }
    }
}
```

---

## Views 组件

### ContentView - 主容器

```swift
struct ContentView: View {
    @State private var viewModel = DeckViewModel()
    @State private var showingSettings = false
    @State private var gatewayUrl = "ws://127.0.0.1:18789"
    @State private var token = ""

    var body: some View {
        Group {
            if viewModel.gatewayConnected {
                DeckView(...)
            } else if viewModel.isInitializing {
                ConnectingView()
            } else {
                WelcomeView(...)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(...)
        }
    }
}
```

### DeckView - 多列布局

```swift
struct DeckView: View {
    @Bindable var viewModel: DeckViewModel
    @Binding var showingSettings: Bool
    @Binding var showingNewSessionSheet: Bool

    var body: some View {
        NavigationStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(viewModel.sessionOrder, id: \.self) { sessionId in
                        if let session = viewModel.sessions[sessionId] {
                            SessionColumnView(...)
                                .frame(width: 400)
                        }
                    }
                }
            }
            .navigationTitle("OpenClaw Deck")
            .toolbar {
                Button { showingNewSessionSheet = true }
                label: { Image(systemName: "plus") }

                Button { showingSettings = true }
                label: { Image(systemName: "gear") }
            }
        }
    }
}
```

### SessionColumnView - 单列聊天

```swift
struct SessionColumnView: View {
    @Bindable var session: SessionState
    @Bindable var viewModel: DeckViewModel
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var inputText = ""
    @State private var showingDeleteAlert = false

    var body: some View {
        ZStack {
            messageList
            chatInput
        }
        .overlay(alignment: .top) {
            topStatusBar
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack {
                    ForEach(session.messages) { message in
                        MessageView(message: message)
                    }
                }
            }
        }
    }

    private var chatInput: some View {
        HStack {
            DictationButton(text: $inputText)
            TextField("Message", text: $inputText)
            Button("Send") { sendMessage() }
        }
    }
}
```

### MessageView - 消息视图

```swift
struct MessageView: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            VStack(alignment: message.role == .user ? .trailing : .leading) {
                if message.role == .assistant && message.text.isEmpty && (message.streaming ?? false) {
                    HStack {
                        ProgressView()
                        Text("Thinking...")
                    }
                } else if message.role == .assistant {
                    MarkdownView(message.text)
                } else {
                    Text(message.text)
                }
            }
            .padding()
            .background(message.role == .user ? Color.blue : Color.adaptiveSecondaryBackground)
            .cornerRadius(18)

            if message.role == .assistant {
                Spacer()
            }
        }
    }
}
```

### DictationButton - 语音输入

```swift
struct DictationButton: View {
    @Binding var text: String
    @ObservedObject var speechRecognizer: SpeechRecognizer  // 从父组件接收
    @State private var errorMessage: String?
    @State private var showingPermissionAlert = false

    var body: some View {
        Button {
            if speechRecognizer.isListening {
                speechRecognizer.stopListening()
            } else {
                guard speechRecognizer.isAvailable else {
                    errorMessage = "Speech recognizer is not available"
                    return
                }
                Task {
                    do {
                        try await speechRecognizer.startListening { newText in
                            text = newText
                        }
                        errorMessage = nil
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        } label: {
            Image(systemName: speechRecognizer.isListening ? "mic.fill" : "mic")
                .foregroundStyle(speechRecognizer.isListening ? .red : .accentColor)
        }
        .buttonStyle(.glass)
    }
}
```

**设计说明：**
- `SpeechRecognizer` 由 `SessionColumnView` 统一管理（`@StateObject`）
- `DictationButton` 接收外部的 `SpeechRecognizer`（`@ObservedObject`）
- 这样可以在发送消息时自动停止听写，避免状态冲突

---

## 测试标准

### 测试框架

- **单元测试**：使用 Swift Testing 框架（Xcode 15+）
- **代码覆盖率目标**：> 70%

### 现有测试

```swift
// SessionConfigTests.swift
import Testing

struct SessionConfigTests {

    @Test
    func testGenerateId_withNormalName() {
        let sessionId = SessionConfig.generateId(from: "Research Agent")
        #expect(sessionId == "research-agent")
    }

    @Test
    func testGenerateId_withSpecialCharacters() {
        let sessionId = SessionConfig.generateId(from: "Test @#$% Agent")
        #expect(sessionId == "test-agent")
    }

    @Test
    func testGenerateId_withEmptyName() {
        let sessionId = SessionConfig.generateId(from: "")
        #expect(sessionId.hasPrefix("session-"))
    }

    @Test
    func testGenerateSessionKey() {
        let sessionKey = SessionConfig.generateSessionKey(sessionId: "test-agent")
        #expect(sessionKey == "agent:main:test-agent")
    }
}
```

### 待编写测试

- [ ] `ChatMessage` 序列化/反序列化测试
- [ ] `AppConfig` 验证逻辑测试
- [ ] `GatewayClient` 连接/请求测试（Mock）
- [ ] `DeckViewModel` Session 管理测试
- [ ] `SessionState` 消息管理测试

---

## 构建脚本

### iPadOS 构建

```bash
# script/build_ipados.sh
bash script/build_ipados.sh
```

### macOS 构建

```bash
# script/build_macos.sh
bash script/build_macos.sh
```

---

## 当前状态

### 已完成功能

- [x] 数据模型（AppConfig, SessionConfig, SessionState, ChatMessage, GatewayFrame）
- [x] Gateway 客户端（WebSocket 连接、请求/响应关联、事件处理）
- [x] ViewModel（DeckViewModel - Session 管理、消息发送、历史加载）
- [x] 基础 UI（ContentView, WelcomeView, DeckView, SessionColumnView, SettingsView, MessageView）
- [x] 语音输入（DictationButton + SpeechRecognizer）
- [x] 数据持久化（UserDefaults 存储 Session 和配置）
- [x] 平台支持（iPadOS + macOS 条件编译）
- [x] 构建脚本（build_ipados.sh, build_macos.sh）

### 已修复的 Bug

- [x] 语音输入关闭时清空输入框（2026-02-26）
  - **原因**：`stopListening()` 调用 `task.cancel()` 后，回调仍触发并清空 transcript
  - **修复**：添加 `isStopping` 标志，在 cancel 前设置，回调中检查该标志
- [x] 发送消息后输入框文字消失（2026-02-26）
  - **原因**：发送消息时听写服务仍在运行，回调继续更新输入框导致状态混乱
  - **修复**：将 `SpeechRecognizer` 提升到 `SessionColumnView`，发送消息前自动停止听写
- [x] 占位符与光标对齐问题（2026-02-26）
  - **原因**：占位符 padding 重复设置（28pt vs 14pt）
  - **修复**：统一占位符与 TextEditor 的 padding 为 14pt

### 技术债务

- [ ] 单元测试覆盖率低（目前只有 SessionConfigTests）
- [ ] WebSocket 断线自动重连（目前需手动刷新）
- [ ] 错误处理与用户友好提示

### 平台支持状态

| 平台 | 构建状态 | 说明 |
|------|---------|------|
| iPadOS | ✅ 已完成 | 完整支持，UI 优化完成 |
| macOS | ✅ 已支持 | 可运行，编译通过 |
| iOS | 🔜 计划中 | 需要 iPhone 适配 |

---

## 开发计划

### 第一阶段：基础架构 ✅

- [x] 数据模型定义
- [x] Gateway 客户端实现
- [x] 基本 ViewModel

### 第二阶段：UI 实现 ✅

- [x] 主容器视图
- [x] 多列布局
- [x] 单列聊天视图
- [x] 消息视图（Markdown 渲染）

### 第三阶段：功能完善 ✅

- [x] 消息发送/接收
- [x] 流式显示
- [x] 历史消息加载
- [x] 语音输入

### 第四阶段：增强功能 🔜

- [ ] 单元测试完善（目标覆盖率 > 70%）
- [ ] WebSocket 自动重连
- [ ] 错误处理与用户友好提示
- [ ] Session 管理增强（重命名、搜索、归档）
- [ ] macOS UI 优化（菜单栏、快捷键）
- [ ] iOS 支持（iPhone 适配）

---

## 后续开发优先级

### 高优先级 🔴

1. **完善单元测试** - 技术债务（2-3 天）
2. **错误处理与恢复** - 自动重连、重试机制（1-2 天）
3. **用户体验优化** - Enter 发送、长按复制、字数限制（2-3 天）

### 中优先级 🟡

4. **Session 管理增强** - 重命名、搜索、归档（1-2 天）
5. **设置页面完善** - 主题色、字体大小、清除缓存（1 天）
6. **通知与提醒** - 回复完成通知、未读消息计数（1-2 天）

### 低优先级 🟢

7. **性能优化** - 虚拟滚动、附件支持（2-3 天）
8. **iOS 支持** - iPhone 适配、横竖屏切换（2-3 天）
9. **高级功能** - 多 Agent 切换、自定义 System Prompt（3-5 天）
