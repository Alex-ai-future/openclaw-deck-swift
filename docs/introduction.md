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
| macOS | ✅ 必须兼容 | 可运行，不做 UI 优化 |
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

### 4. 未来功能

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
| Markdown 渲染 | [MarkdownView](https://github.com/liyanan2004/MarkdownView) |
| 最低支持版本 | iPadOS 18.0 / macOS 15.0 |

### 项目结构

```
openclaw-deck-swift/
├── .gitignore                      # Git 忽略文件（Xcode 相关）
├── openclaw-deck-swift/            # Xcode 项目主目录
│   ├── openclaw-deck-swift/        # App 目标
│   │   ├── OpenClawDeckApp.swift   # 应用入口
│   │   ├── ContentView.swift       # 主视图
│   │   ├── Models/                 # 数据模型
│   │   │   ├── GatewayFrame.swift
│   │   │   ├── SessionConfig.swift
│   │   │   └── ChatMessage.swift
│   │   ├── ViewModels/             # 视图模型
│   │   │   ├── DeckViewModel.swift
│   │   │   └── SessionColumnViewModel.swift
│   │   ├── Views/                  # 视图组件
│   │   │   ├── DeckView.swift
│   │   │   ├── SessionColumnView.swift
│   │   │   ├── ChatInputView.swift
│   │   │   ├── MessageView.swift
│   │   │   ├── SettingsView.swift
│   │   │   └── Components/
│   │   ├── Services/               # 服务层
│   │   │   └── GatewayClient.swift
│   │   ├── Utils/                  # 工具类
│   │   │   └── Extensions.swift
│   │   └── Resources/              # 资源文件
│   │       └── Assets.xcassets
│   ├── openclaw-deck-swift.xcodeproj/  # Xcode 项目文件
│   ├── openclaw-deck-swiftTests/       # 单元测试
│   └── openclaw-deck-swiftUITests/     # UI 测试
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
| `sessions_history` | 获取 Session 历史消息 | sessionKey |
| `sessions_list` | 列出活跃的 Sessions | - |
| `session_status` | 获取 Session 状态 | sessionKey |

### 事件类型

| 事件 | 说明 |
|------|------|
| `agent.content` | Agent 回复内容（流式） |
| `agent.thinking` | Agent 思考过程 |
| `agent.tool_use` | 工具调用信息 |
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

// MARK: - Types

struct PendingRequest {
    let continuation: CheckedContinuation<Any, Error>
    let timeout: Task<Void, Never>
}

// MARK: - GatewayClient

@Observable
class GatewayClient {
    
    // MARK: - Configuration
    
    let url: URL
    let token: String?              // 用户手动输入，不存储
    
    // MARK: - State
    
    private(set) var connected: Bool = false
    private var webSocket: URLSessionWebSocketTask?
    private var pendingRequests: [String: PendingRequest] = [:]
    private var messageCounter: Int = 0
    
    // MARK: - Callbacks
    
    var onEvent: ((GatewayEvent) -> Void)?
    var onConnection: ((Bool) -> Void)?
    
    // MARK: - Constants
    
    private let requestTimeout: TimeInterval = 30
    private let operatorScopes = ["operator.read", "operator.write"]
    
    // MARK: - Initialization
    
    init(url: URL, token: String? = nil) {
        self.url = url
        self.token = token
    }
    
    // MARK: - Public Methods
    
    /// 建立连接并完成握手
    func connect() async {
        let session = URLSession.shared
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        
        // 开始接收消息
        receiveMessage()
        
        // 发送 connect 请求
        await sendConnect()
    }
    
    /// 断开连接
    func disconnect() {
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
        connected = false
        
        // 拒绝所有待处理请求
        for (_, pending) in pendingRequests {
            pending.continuation.resume(throwing: NSError(
                domain: "GatewayClient",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Connection closed"]
            ))
        }
        pendingRequests.removeAll()
        
        onConnection?(false)
    }
    
    /// 发送请求并等待响应
    func request(method: String, params: [String: Any]? = nil) async throws -> Any {
        guard let webSocket = webSocket, webSocket.state == .running else {
            throw NSError(
                domain: "GatewayClient",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Gateway not connected"]
            )
        }
        
        let id = nextId()
        
        return try await withCheckedThrowingContinuation { continuation in
            // 设置超时
            let timeout = Task {
                try? await Task.sleep(nanoseconds: UInt64(requestTimeout * 1_000_000_000))
                if pendingRequests[id] != nil {
                    pendingRequests.removeValue(forKey: id)
                    continuation.resume(throwing: NSError(
                        domain: "GatewayClient",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "Request \(method) timed out"]
                    ))
                }
            }
            
            pendingRequests[id] = PendingRequest(continuation: continuation, timeout: timeout)
            
            // 发送请求
            let frame: [String: Any] = [
                "type": "req",
                "id": id,
                "method": method,
                "params": params ?? [:]
            ]
            send(frame: frame)
        }
    }
    
    /// 执行 Agent 轮次
    func runAgent(
        agentId: String,
        message: String,
        sessionKey: String? = nil
    ) async throws -> (runId: String, status: String) {
        let idempotencyKey = "agent-\(Date().timeIntervalSince1970)-\(UUID().uuidString.prefix(6))"
        
        var params: [String: Any] = [
            "agentId": agentId,
            "message": message,
            "idempotencyKey": idempotencyKey
        ]
        
        if let sessionKey = sessionKey {
            params["sessionKey"] = sessionKey
        }
        
        let result = try await request(method: "agent", params: params)
        
        guard let dict = result as? [String: Any],
              let runId = dict["runId"] as? String,
              let status = dict["status"] as? String else {
            throw NSError(
                domain: "GatewayClient",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response format"]
            )
        }
        
        return (runId, status)
    }
    
    // MARK: - Private Methods
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    self.handleData(data)
                case .string(let string):
                    self.handleString(string)
                @unknown default:
                    break
                }
                
                // 继续接收下一条消息
                self.receiveMessage()
                
            case .failure(let error):
                print("[GatewayClient] Receive error: \(error)")
                self.handleDisconnect()
            }
        }
    }
    
    private func handleString(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        handleData(data)
    }
    
    private func handleData(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            print("[GatewayClient] Failed to parse frame")
            return
        }
        
        switch type {
        case "res":
            handleResponse(json)
        case "event":
            handleEvent(json)
        default:
            break
        }
    }
    
    private func handleResponse(_ json: [String: Any]) {
        guard let id = json["id"] as? String,
              let pending = pendingRequests.removeValue(forKey: id) else {
            return
        }
        
        let ok = json["ok"] as? Bool ?? false
        
        if ok {
            pending.continuation.resume(returning: json["payload"] ?? [:])
        } else {
            let errorMsg = (json["error"] as? [String: Any])?["message"] as? String ?? "Request failed"
            pending.continuation.resume(throwing: NSError(
                domain: "GatewayClient",
                code: -4,
                userInfo: [NSLocalizedDescriptionKey: errorMsg]
            ))
        }
    }
    
    private func handleEvent(_ json: [String: Any]) {
        // 传递给事件处理器
        onEvent?(GatewayEvent(from: json))
    }
    
    private func send(frame: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: frame),
              let string = String(data: data, encoding: .utf8) else {
            return
        }
        
        webSocket?.send(.string(string)) { error in
            if let error = error {
                print("[GatewayClient] Send error: \(error)")
            }
        }
    }
    
    private func sendConnect() async {
        do {
            var params: [String: Any] = [
                "client": [
                    "id": "openclaw-deck-swift",
                    "version": "1.0.0",
                    "platform": "ios",
                    "mode": "webchat"
                ],
                "minProtocol": 3,
                "maxProtocol": 3,
                "role": "operator",
                "scopes": operatorScopes
            ]
            
            // 添加 token 认证（用户手动输入）
            if let token = token, !token.isEmpty {
                params["auth"] = ["token": token]
            }
            
            _ = try await request(method: "connect", params: params)
            
            connected = true
            onConnection?(true)
            print("[GatewayClient] Connected to gateway")
            
        } catch {
            print("[GatewayClient] Handshake failed: \(error)")
            disconnect()
        }
    }
    
    private func handleDisconnect() {
        let wasConnected = connected
        connected = false
        
        if wasConnected {
            onConnection?(false)
        }
        
        // 拒绝所有待处理请求
        for (_, pending) in pendingRequests {
            pending.continuation.resume(throwing: NSError(
                domain: "GatewayClient",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Connection closed"]
            ))
        }
        pendingRequests.removeAll()
    }
    
    private func nextId() -> String {
        messageCounter += 1
        return "deck-\(messageCounter)-\(Int(Date().timeIntervalSince1970 * 1000))"
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
│     { type: "req", id: "deck-1-1708123456789",                   │
│       method: "agent", params: {...} }                           │
│                                                                  │
│  4. 等待响应                                                      │
│     ├─ 成功: pendingRequests[id].resolve(payload)                │
│     ├─ 失败: pendingRequests[id].reject(error)                   │
│     └─ 超时: 删除 pendingRequest，reject timeout error           │
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

// 事件处理示例
func handleGatewayEvent(_ event: GatewayEvent) {
    switch event.event {
    case "agent.content":
        // 流式内容 - 追加到当前消息
        if let content = event.payload as? [String: Any],
           let text = content["text"] as? String {
            // 更新 UI，追加文本
            appendMessageText(text)
        }
        
    case "agent.thinking":
        // Agent 思考中
        updateStatus(.thinking)
        
    case "agent.tool_use":
        // 工具调用
        if let toolInfo = event.payload as? [String: Any] {
            handleToolUse(toolInfo)
        }
        
    case "agent.done":
        // Agent 完成
        updateStatus(.idle)
        finalizeMessage()
        
    case "agent.error":
        // 错误处理
        if let error = event.payload as? [String: Any],
           let message = error["message"] as? String {
            showError(message)
        }
        
    default:
        break
    }
}
```

---

## 数据模型

### SessionConfig - Session 配置

```swift
struct SessionConfig: Identifiable {
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
    static func generateId(from name: String) -> String {
        let sanitized = name
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        
        return sanitized.isEmpty ? "session-\(Date().timeIntervalSince1970)" : sanitized
    }
    
    static func generateSessionKey(sessionId: String) -> String {
        return "agent:main:\(sessionId)"
    }
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
struct AppConfig {
    var gatewayUrl: String      // 默认: ws://127.0.0.1:18789
    var token: String?          // 用户手动输入，不持久化存储
    let mainAgentId: String     // 固定的 Main Agent ID
    
    static let `default` = AppConfig(
        gatewayUrl: "ws://127.0.0.1:18789",
        token: nil,
        mainAgentId: "main"
    )
}
```

> **注意**：Token 由用户在设置页面手动输入，仅在内存中保存，应用重启后需要重新输入。

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
│     │ 请求:                                  │                  │
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
    
    init(sessionId: String, sessionKey: String) {
        self.sessionId = sessionId
        self.sessionKey = sessionKey
    }
}

enum SessionStatus: String {
    case idle           // 空闲
    case thinking       // 思考中
    case streaming      // 流式输出中
    case toolUse = "tool_use"  // 工具调用
    case error          // 错误
    case disconnected   // 断开连接
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
    func getSessionHistory(sessionKey: String) async throws -> [ChatMessage] {
        let result = try await request(
            method: "sessions_history",
            params: ["sessionKey": sessionKey]
        )
        
        guard let dict = result as? [String: Any],
              let messagesData = dict["messages"] as? [[String: Any]] else {
            return []
        }
        
        // 解析消息
        return messagesData.compactMap { data -> ChatMessage? in
            guard let role = data["role"] as? String,
                  let text = data["text"] as? String else {
                return nil
            }
            
            return ChatMessage(
                id: data["id"] as? String ?? UUID().uuidString,
                role: MessageRole(rawValue: role) ?? .user,
                text: text,
                timestamp: Date(timeIntervalSince1970: (data["timestamp"] as? Double ?? 0) / 1000)
            )
        }
    }
    
    /// 列出所有活跃 Sessions
    func listSessions() async throws -> [String] {
        let result = try await request(method: "sessions_list", params: [:])
        
        guard let dict = result as? [String: Any],
              let sessions = dict["sessions"] as? [String] else {
            return []
        }
        
        return sessions
    }
}
```

### Session 创建流程

```
┌─────────────────────────────────────────────────────────────────┐
│                       Session 创建流程                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. 用户点击 "New Session" 按钮                                   │
│                     │                                            │
│                     ▼                                            │
│  2. 弹出 Session 创建表单                                         │
│     ┌────────────────────────────────────────┐                  │
│     │  New Session                           │                  │
│     │  ┌──────────────────────────────────┐  │                  │
│     │  │ Name: [Research Agent]           │  │                  │
│     │  │ Icon: [R] (optional)             │  │                  │
│     │  │ Color: ████ #a78bfa              │  │                  │
│     │  │ Context: [Deep web research...]  │  │                  │
│     │  └──────────────────────────────────┘  │                  │
│     │  [Cancel]                    [Create]  │                  │
│     └────────────────────────────────────────┘                  │
│                     │                                            │
│                     ▼                                            │
│  3. 生成 Session ID                                              │
│     let sessionId = SessionConfig.generateId(from: name)         │
│     // "research-agent"                                          │
│                     │                                            │
│                     ▼                                            │
│  4. 生成 Session Key                                             │
│     let sessionKey = SessionConfig.generateSessionKey(           │
│         sessionId: sessionId                                     │
│     )                                                            │
│     // "agent:main:research-agent"                               │
│                     │                                            │
│                     ▼                                            │
│  5. 创建 SessionConfig                                           │
│     let config = SessionConfig(                                  │
│         id: sessionId,                                           │
│         sessionKey: sessionKey,                                  │
│         createdAt: Date(),                                       │
│         name: "Research Agent",                                  │
│         icon: "R",                                               │
│         accentColor: "#a78bfa",                                  │
│         context: "Deep web research & synthesis"                 │
│     )                                                            │
│                     │                                            │
│                     ▼                                            │
│  6. 添加到 DeckViewModel.sessions                                │
│                     │                                            │
│                     ▼                                            │
│  7. 如果 Gateway 已连接，加载历史消息                             │
│     await loadSessionHistory(sessionKey)                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### DeckViewModel - Session 管理

```swift
@Observable
class DeckViewModel {
    var gatewayClient: GatewayClient?
    var sessions: [String: SessionState] = [:]
    var sessionOrder: [String] = []
    var gatewayConnected: Bool = false
    
    var config: AppConfig = .default
    
    // MARK: - 初始化
    
    func initialize(url: URL, token: String) async {
        // 创建 GatewayClient
        let client = GatewayClient(url: url, token: token)
        client.onEvent = { [weak self] event in
            self?.handleGatewayEvent(event)
        }
        client.onConnection = { [weak self] connected in
            self?.gatewayConnected = connected
            if connected {
                Task { await self?.loadAllSessionHistory() }
            }
        }
        
        self.gatewayClient = client
        
        // 连接
        await client.connect()
    }
    
    // MARK: - Session 创建
    
    func createSession(
        name: String,
        icon: String? = nil,
        accentColor: String? = nil,
        context: String? = nil
    ) -> SessionConfig {
        // 1. 生成 Session ID
        let sessionId = SessionConfig.generateId(from: name)
        
        // 2. 生成 Session Key
        let sessionKey = SessionConfig.generateSessionKey(sessionId: sessionId)
        
        // 3. 创建 SessionConfig
        let config = SessionConfig(
            id: sessionId,
            sessionKey: sessionKey,
            createdAt: Date(),
            name: name,
            icon: icon ?? String(name.prefix(1)).uppercased(),
            accentColor: accentColor ?? "#a78bfa",
            context: context ?? name
        )
        
        // 4. 创建 SessionState
        let sessionState = SessionState(
            sessionId: sessionId,
            sessionKey: sessionKey
        )
        
        // 5. 添加到 sessions
        sessions[sessionId] = sessionState
        sessionOrder.append(sessionId)
        
        // 6. 如果已连接，加载历史消息
        if gatewayConnected {
            Task {
                await loadSessionHistory(sessionKey: sessionKey)
            }
        }
        
        return config
    }
    
    // MARK: - 删除 Session
    
    func deleteSession(sessionId: String) {
        // 1. 从 sessions 中移除
        sessions.removeValue(forKey: sessionId)
        
        // 2. 从 sessionOrder 中移除
        sessionOrder.removeAll { $0 == sessionId }
        
        // 注意：Gateway 中的消息历史不会被删除
        // Session Key 可以继续使用，下次创建同名 Session 会加载历史
    }
    
    // MARK: - 加载历史消息
    
    func loadAllSessionHistory() async {
        for (sessionId, session) in sessions {
            await loadSessionHistory(sessionKey: session.sessionKey)
        }
    }
    
    func loadSessionHistory(sessionKey: String) async {
        guard let client = gatewayClient, client.connected else { return }
        
        // 从 sessionKey 中提取 sessionId
        let parts = sessionKey.split(separator: ":")
        guard parts.count >= 3 else { return }
        let sessionId = String(parts[2])
        
        do {
            let messages = try await client.getSessionHistory(
                sessionKey: sessionKey
            ) ?? []
            
            // 更新 Session 的消息
            sessions[sessionId]?.messages = messages
            sessions[sessionId]?.historyLoaded = true
        } catch {
            print("[DeckViewModel] Failed to load history for \(sessionId): \(error)")
        }
    }
    
    // MARK: - 发送消息
    
    func sendMessage(sessionId: String, text: String) async {
        guard let client = gatewayClient, client.connected else { return }
        guard let session = sessions[sessionId] else { return }
        
        // 1. 添加用户消息
        let userMsg = ChatMessage(
            id: UUID().uuidString,
            role: .user,
            text: text,
            timestamp: Date()
        )
        sessions[sessionId]?.messages.append(userMsg)
        sessions[sessionId]?.status = .thinking
        
        do {
            // 2. 调用 runAgent
            let (runId, _) = try await client.runAgent(
                agentId: config.mainAgentId,
                message: text,
                sessionKey: session.sessionKey
            )
            
            // 3. 创建 assistant 占位消息
            let assistantMsg = ChatMessage(
                id: UUID().uuidString,
                role: .assistant,
                text: "",
                timestamp: Date(),
                streaming: true,
                runId: runId
            )
            sessions[sessionId]?.messages.append(assistantMsg)
            sessions[sessionId]?.activeRunId = runId
            sessions[sessionId]?.status = .streaming
            
        } catch {
            print("[DeckViewModel] Failed to send message: \(error)")
            sessions[sessionId]?.status = .error
        }
    }
    
    // MARK: - 事件处理
    
    func handleGatewayEvent(_ event: GatewayEvent) {
        // 根据 sessionKey 找到对应的 Session
        // 更新消息内容...
    }
}
```

### Session 持久化

```swift
// Session 配置持久化（仅本地）
class SessionStorage {
    private let sessionsKey = "openclaw.deck.sessions.v1"
    
    func saveSessions(_ sessions: [SessionConfig]) throws {
        let data = try JSONEncoder().encode(sessions)
        UserDefaults.standard.set(data, forKey: sessionsKey)
    }
    
    func loadSessions() throws -> [SessionConfig] {
        guard let data = UserDefaults.standard.data(forKey: sessionsKey) else {
            return []
        }
        return try JSONDecoder().decode([SessionConfig].self, from: data)
    }
    
    func deleteSessions() {
        UserDefaults.standard.removeObject(forKey: sessionsKey)
    }
}
```

### 关键设计决策

1. **Session ID 生成规则**：
   - 基于名称生成：`name.lowercased().replace(/[^a-z0-9]+/g, "-")`
   - 如果为空：`session-${timestamp}`

2. **Session Key 格式**：
   - `agent:main:{sessionId}`
   - 固定使用 "main" Agent，通过 sessionId 区分不同会话

3. **Gateway 交互**：
   - **不需要**调用 Gateway API 创建 Session
   - 直接使用 sessionKey 发送消息
   - Gateway 会自动创建对应的 Session 存储

4. **数据持久化**：
   - 仅本地存储 SessionConfig（ID、名称、颜色等）
   - 消息历史存储在 Gateway
   - 删除 Session 仅删除本地配置，不删除 Gateway 历史

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

### 设计风格

采用 **iPadOS 18 Liquid Glass** 设计语言，使用原生 Glass Effect（毛玻璃效果）：

- `.background(.ultraThinMaterial)` - 超薄材质毛玻璃
- `.background(.thinMaterial)` - 薄材质毛玻璃
- 符合 visionOS 设计风格，带来现代感视觉体验

### App Structure

使用 SwiftUI 原生 `NavigationStack` + `Toolbar` 结构：

```
NavigationStack
├── Toolbar (毛玻璃顶部栏)
│   ├── ToolbarItem(placement: .principal) - Title
│   ├── ToolbarItem(placement: .topBarLeading) - Settings
│   └── ToolbarItem(placement: .topBarTrailing) - Refresh
│
└── Main Content
    ├── ScrollView (.horizontal)
    │   ├── LazyHStack
    │   │   ├── SessionCard (Glass Effect)
    │   │   ├── SessionCard (Glass Effect)
    │   │   └── NewSessionCard (Glass Effect)
    │   └── ...
    └── ...
```

### 主界面布局

```
┌────────────────────────────────────────────────────────────────┐
│ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ │  ← 毛玻璃 Toolbar
│  OpenClaw Deck                               [🔄] [⚙️]          │
├────────────────────────────────────────────────────────────────┤
│ ● Connected                                                    │
├──────────────┬──────────────┬──────────────┬──────────────────┤
│ ┌──────────┐ │ ┌──────────┐ │ ┌──────────┐ │ ┌──────────────┐ │
│ │░░░░░░░░░░│ │ │░░░░░░░░░░│ │ │░░░░░░░░░░│ │ │░░░░░░░░░░░░░░│ │  ← Glass Effect
│ │ Session 1│ │ │ Session 2│ │ │ Session 3│ │ │ + New Session│ │
│ │░░░░░░░░░░│ │ │░░░░░░░░░░│ │ │░░░░░░░░░░│ │ │░░░░░░░░░░░░░░│ │
│ │ Messages │ │ │ Messages │ │ │ Messages │ │ │              │ │
│ │          │ │ │          │ │ │          │ │ │              │ │
│ │ [Input]  │ │ │ [Input]  │ │ │ [Input]  │ │ │              │ │
│ │     [x]  │ │ │     [x]  │ │ │     [x]  │ │ │              │ │
│ └──────────┘ │ └──────────┘ │ └──────────┘ │ └──────────────┘ │
└──────────────┴──────────────┴──────────────┴──────────────────┘
```

### Session Card 结构

```
┌──────────────────────┐
│ ░░░░░░░░░░░░░░░░░░░░ │  ← Glass Effect Container
│ Session 1        [x] │  ← Header (名称、删除按钮)
│ ░░░░░░░░░░░░░░░░░░░░ │
│                      │
│   消息滚动区域        │  ← ScrollView
│                      │
│   User: 你好         │
│   ┌────────────────┐ │
│   │ Agent 回复      │ │  ← Markdown 渲染
│   │ 支持代码高亮    │ │
│   └────────────────┘ │
│                      │
│ ┌──────────────────┐ │
│ │ 输入消息...       │ │  ← 输入框
│ └──────────────────┘ │
│              [发送]   │
└──────────────────────┘
```

### 设置页面（Sheet）

```
┌────────────────────────────────────┐
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │  ← Glass Effect Navigation
│         Settings               [Done]│
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
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
│  [Refresh Connection]              │
│                                    │
├────────────────────────────────────┤
│  Main Agent                        │
│  ID: main (fixed)                  │
│                                    │
├────────────────────────────────────┤
│  About                             │
│  Version: 1.0.0                    │
└────────────────────────────────────┘
```

### 关键 SwiftUI 代码示例

```swift
// 主视图结构
struct DeckView: View {
    var body: some View {
        NavigationStack {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 16) {
                    ForEach(sessions) { session in
                        SessionCardView(session: session)
                    }
                    NewSessionCardView()
                }
                .padding()
            }
            .navigationTitle("OpenClaw Deck")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

// Session Card (Glass Effect)
struct SessionCardView: View {
    var body: some View {
        VStack {
            // ... content
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
```

---

## 开发路线

### 第一阶段：基础架构（1-2周）

**目标**：建立项目基础结构，实现核心数据模型和 Gateway 连接

- [ ] **项目结构重构**
  - [ ] 创建 Models/ 目录：GatewayFrame.swift, SessionConfig.swift, ChatMessage.swift
  - [ ] 创建 ViewModels/ 目录：DeckViewModel.swift, SessionColumnViewModel.swift
  - [ ] 创建 Services/ 目录：GatewayClient.swift
  - [ ] 创建 Views/Components/ 目录

- [ ] **核心数据模型**
  - [ ] GatewayFrame（WebSocket 帧模型）
  - [ ] SessionConfig（Session 配置，包含 ID 生成工具）
  - [ ] ChatMessage（消息模型，支持流式标记）
  - [ ] AppConfig（应用配置，Gateway URL 和 Token）

- [ ] **GatewayClient 实现**
  - [ ] WebSocket 连接管理（URLSessionWebSocketTask）
  - [ ] 请求/响应关联机制（PendingRequest 管理）
  - [ ] 事件处理（agent.content, agent.done 等）
  - [ ] 手动重连功能

### 第二阶段：UI 实现（1-2周）

**目标**：实现主要用户界面，支持多 Session 管理和消息显示

- [ ] **主界面布局**
  - [ ] DeckView（多列水平滚动布局）
  - [ ] SessionColumnView（单列 Session 视图）
  - [ ] Glass Effect 毛玻璃效果（.background(.ultraThinMaterial)）
  - [ ] 响应式布局适配 iPadOS

- [ ] **Session 管理**
  - [ ] 创建 Session 表单（名称、图标、颜色、上下文）
  - [ ] Session 列表显示（卡片式布局）
  - [ ] 删除 Session 功能（仅本地删除，保留 Gateway 历史）
  - [ ] Session 持久化（UserDefaults 存储配置）

- [ ] **消息界面**
  - [ ] MessageView（消息显示组件，区分 user/assistant）
  - [ ] ChatInputView（输入框，支持发送消息）
  - [ ] 消息滚动区域（自动滚动到底部）
  - [ ] Markdown 渲染集成（使用MarkdownView库）

### 第三阶段：功能完善（1周）

**目标**：完善核心功能，实现完整的消息流和设置

- [ ] **设置页面**
  - [ ] Gateway URL 配置（默认 ws://127.0.0.1:18789）
  - [ ] Token 输入（手动输入，不持久化存储）
  - [ ] 连接状态显示（● Connected / ○ Disconnected）
  - [ ] 手动刷新按钮（断开重连）

- [ ] **消息流式显示**
  - [ ] 流式消息更新（实时追加文本）
  - [ ] 历史消息加载（sessions_history API）
  - [ ] 状态指示器（thinking, streaming, tool_use）
  - [ ] 错误处理（网络错误、Gateway 错误）

- [ ] **基础交互**
  - [ ] 键盘适配（输入框自动聚焦）
  - [ ] 滚动优化（新消息自动滚动）
  - [ ] 加载状态（历史消息加载中）

### 第四阶段：增强功能（后续迭代）

**目标**：提升用户体验，增加高级功能

- [ ] **Markdown 渲染集成**
  - [ ] 集成 MarkdownView SPM 依赖
  - [ ] 配置 MarkdownView 组件
  - [ ] 实现代码语法高亮
  - [ ] 支持列表、标题、链接等格式化

- [ ] **Agent 状态显示**
  - [ ] Tool Use 信息展示
  - [ ] Thinking 过程显示
  - [ ] 运行状态指示器

- [ ] **跨平台适配**
  - [ ] iOS 适配（iPhone 界面优化）
  - [ ] macOS 支持（可运行，不做 UI 优化）
  - [ ] Catalyst 适配（可选）

- [ ] **高级功能**
  - [ ] 深色/浅色主题切换
  - [ ] 多语言支持（中英文）
  - [ ] 快捷键支持（Cmd+Enter 发送等）
  - [ ] Split View 优化（iPad 多任务）

### 迭代建议

**迭代 1：基础架构 + 简单 UI**
- 完成第一阶段基础架构
- 实现最简单的消息发送/接收
- 验证 Gateway 连接

**迭代 2：Gateway 连接 + 完整消息流**
- 完善 GatewayClient
- 实现流式消息显示
- 添加历史消息加载

**迭代 3：UI 美化 + 设置功能**
- 实现 Glass Effect 毛玻璃效果
- 完成设置页面
- 优化交互体验

**迭代 4：增强功能**
- Markdown 渲染
- Tool Use 显示
- 跨平台适配

### 技术风险与应对

| 风险 | 影响 | 应对措施 |
|------|------|----------|
| Gateway API 变更 | 高 | 保持协议兼容性，使用可配置的协议版本 |
| WebSocket 稳定性 | 中 | 实现手动重连，添加连接状态监控 |
| 内存管理 | 中 | 使用 SwiftUI 状态管理，及时清理无用数据 |
| 跨平台兼容性 | 低 | 明确平台支持范围，优先保证 iPadOS |

### 成功标准

1. **功能完整**：支持多 Session 管理、消息发送、流式显示
2. **稳定可靠**：Gateway 连接稳定，错误处理完善
3. **用户体验**：界面美观，交互流畅
4. **代码质量**：架构清晰，易于维护扩展

---

## 测试标准

每个开发阶段完成后，需要编写单元测试，并通过反复修改直到所有测试通过。

### 测试框架

- **单元测试**：使用 Swift Testing 框架（Xcode 15+）
- **代码覆盖率目标**：> 70%

---

### 第一阶段：基础架构

**数据模型测试**

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

**ChatMessage 测试**

```swift
// ChatMessageTests.swift
import Testing

struct ChatMessageTests {
    
    @Test
    func testMessageEncoding() throws {
        let message = ChatMessage(
            id: "msg-1",
            role: .user,
            text: "Hello",
            timestamp: Date(timeIntervalSince1970: 1708123456)
        )
        
        let data = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(ChatMessage.self, from: data)
        
        #expect(decoded.id == message.id)
        #expect(decoded.role == message.role)
        #expect(decoded.text == message.text)
    }
}
```

**GatewayClient 测试（使用 Mock）**

```swift
// GatewayClientTests.swift
import Testing

struct GatewayClientTests {
    
    @Test
    func testRequestIdGeneration() {
        let client = GatewayClient(url: URL(string: "ws://localhost:8080")!)
        
        let id1 = client.nextId()
        let id2 = client.nextId()
        
        #expect(id1 != id2)
        #expect(id1.hasPrefix("deck-1-"))
        #expect(id2.hasPrefix("deck-2-"))
    }
    
    @Test
    func testConnectionState() async throws {
        let client = GatewayClient(url: URL(string: "ws://localhost:8080")!)
        
        // 测试初始状态
        #expect(client.connected == false)
    }
}
```

**通过标准**
- [ ] `SessionConfig.generateId()` 所有测试通过
- [ ] `SessionConfig.generateSessionKey()` 所有测试通过
- [ ] `ChatMessage` 序列化/反序列化测试通过
- [ ] `AppConfig` 默认值验证测试通过
- [ ] 代码覆盖率 > 70%

---

### 第二阶段：UI实现

**Session 管理测试**

```swift
// DeckViewModelTests.swift
import Testing

struct DeckViewModelTests {
    
    @Test
    func testCreateSession() {
        let viewModel = DeckViewModel()
        
        let config = viewModel.createSession(
            name: "Research Agent",
            icon: "R",
            accentColor: "#a78bfa"
        )
        
        #expect(config.name == "Research Agent")
        #expect(config.sessionKey == "agent:main:research-agent")
        #expect(viewModel.sessions[config.id] != nil)
    }
    
    @Test
    func testDeleteSession() {
        let viewModel = DeckViewModel()
        
        let config = viewModel.createSession(name: "Test Session")
        viewModel.deleteSession(sessionId: config.id)
        
        #expect(viewModel.sessions[config.id] == nil)
    }
    
    @Test
    func testSessionPersistence() throws {
        let storage = SessionStorage()
        
        let sessions = [
            SessionConfig(
                id: "test-1",
                sessionKey: "agent:main:test-1",
                createdAt: Date(),
                name: "Test"
            )
        ]
        
        try storage.saveSessions(sessions)
        let loaded = try storage.loadSessions()
        
        #expect(loaded.count == 1)
        #expect(loaded[0].id == "test-1")
    }
}
```

**通过标准**
- [ ] Session 创建/删除功能测试通过
- [ ] Session 持久化读写测试通过
- [ ] ViewModel 状态管理测试通过

---

### 第三阶段：功能完善

**消息流测试**

```swift
// MessageTests.swift
import Testing

struct MessageTests {
    
    @Test
    func testSendMessageAddsUserMessage() async {
        let viewModel = DeckViewModel()
        let config = viewModel.createSession(name: "Test")
        
        await viewModel.sendMessage(sessionId: config.id, text: "Hello")
        
        let session = viewModel.sessions[config.id]!
        #expect(session.messages.count >= 1)
        #expect(session.messages.last?.role == .user)
    }
    
    @Test
    func testMessageStatusTransitions() {
        let session = SessionState(
            sessionId: "test",
            sessionKey: "agent:main:test"
        )
        
        // 测试状态转换
        session.status = .thinking
        #expect(session.status == .thinking)
        
        session.status = .streaming
        #expect(session.status == .streaming)
        
        session.status = .idle
        #expect(session.status == .idle)
    }
}
```

**设置功能测试**

```swift
// SettingsTests.swift
import Testing

struct SettingsTests {
    
    @Test
    func testDefaultConfig() {
        let config = AppConfig.default
        
        #expect(config.gatewayUrl == "ws://127.0.0.1:18789")
        #expect(config.mainAgentId == "main")
        #expect(config.token == nil)
    }
    
    @Test
    func testConfigValidation() {
        var config = AppConfig.default
        config.gatewayUrl = "ws://localhost:8080"
        
        let isValidURL = URL(string: config.gatewayUrl) != nil
        #expect(isValidURL == true)
    }
}
```

**通过标准**
- [ ] 消息发送功能测试通过
- [ ] 消息状态转换测试通过
- [ ] 设置配置验证测试通过
- [ ] 错误处理路径测试通过

---

### 第四阶段：增强功能

**Markdown 渲染测试**

```swift
// MarkdownTests.swift
import Testing

struct MarkdownTests {
    
    @Test
    func testPlainTextRendering() {
        let markdown = "Hello World"
        // 测试纯文本渲染
        #expect(!markdown.isEmpty)
    }
    
    @Test
    func testCodeBlockParsing() {
        let markdown = "```swift\nlet x = 1\n```"
        // 测试代码块解析
        #expect(markdown.contains("```swift"))
    }
    
    @Test
    func testListParsing() {
        let markdown = "- Item 1\n- Item 2\n- Item 3"
        // 测试列表解析
        #expect(markdown.hasPrefix("- "))
    }
}
```

**通过标准**
- [ ] Markdown 基础渲染测试通过
- [ ] 代码块解析测试通过
- [ ] 列表/标题格式化测试通过

---

### 测试实施建议

1. **Mock Gateway 服务器**：避免依赖真实 Gateway，使用 Mock 对象
2. **异步测试**：使用 `async/await` 进行异步操作测试
3. **持续集成**：每次提交自动运行测试（GitHub Actions）
4. **测试驱动开发(TDD)**：先写测试，再实现功能

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

### UI 设计

- [iPadOS 18 | Apple Developer](https://developer.apple.com/ipados/)
- [Material Effects | Apple Developer](https://developer.apple.com/documentation/swiftui/material)
- [NavigationStack | Apple Developer](https://developer.apple.com/documentation/swiftui/navigationstack)

### 架构模式

- [MVVM with SwiftUI](https://developer.apple.com/documentation/swiftui/managing-user-interface-state)
- [Observable Framework](https://developer.apple.com/documentation/observation)

### OpenClaw 协议

- [Gateway Protocol](https://docs.openclaw.ai/concepts/architecture)
- [WebSocket Frame Format](https://docs.openclaw.ai/reference/websocket)