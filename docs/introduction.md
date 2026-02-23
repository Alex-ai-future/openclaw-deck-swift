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
| 最低支持版本 | iPadOS 18.0 |

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
│   │   connect()              │                            │             │
│   │ ───────────────────────► │                            │             │
│   │                          │   WebSocket Connect        │             │
│   │                          │ ──────────────────────────►│             │
│   │                          │                            │             │
│   │                          │   event: connect.challenge │             │
│   │                          │ ◄────────────────────────── │             │
│   │                          │   { nonce: "xxx" }         │             │
│   │                          │                            │             │
│   │                          │   req: connect             │             │
│   │                          │   (with device signature)  │             │
│   │                          │ ──────────────────────────►│             │
│   │                          │                            │             │
│   │                          │   res: connect             │             │
│   │                          │ ◄────────────────────────── │             │
│   │                          │   { auth: { deviceToken }} │             │
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

struct DeviceIdentity: Codable {
    let id: String
    let publicKey: String      // base64url encoded
    let privateKey: Data       // encrypted storage
}

// MARK: - GatewayClient

@Observable
class GatewayClient {
    
    // MARK: - Configuration
    
    let url: URL
    var token: String?
    
    // MARK: - State
    
    private(set) var connected: Bool = false
    private var webSocket: URLSessionWebSocketTask?
    private var pendingRequests: [String: PendingRequest] = [:]
    private var messageCounter: Int = 0
    private var connectNonce: String?
    private var connectSent: Bool = false
    private var deviceIdentity: DeviceIdentity?
    
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
        self.deviceIdentity = loadOrCreateDeviceIdentity()
    }
    
    // MARK: - Public Methods
    
    /// 建立连接并完成握手
    func connect() async {
        connectNonce = nil
        connectSent = false
        
        let session = URLSession.shared
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        
        // 开始接收消息
        receiveMessage()
        
        // 等待一小段时间后发送 connect
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
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
            pending.continuation.resume(returning: json["payload"])
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
        guard let event = json["event"] as? String else { return }
        
        // 处理 connect.challenge
        if event == "connect.challenge" {
            if let payload = json["payload"] as? [String: Any],
               let nonce = payload["nonce"] as? String {
                connectNonce = nonce
                connectSent = false
                Task {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                    await sendConnect()
                }
            }
            return
        }
        
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
        guard !connectSent else { return }
        connectSent = true
        
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
            
            // 添加 token 认证
            if let token = getPreferredAuthToken(), !token.isEmpty {
                params["auth"] = ["token": token]
            }
            
            // 添加设备签名
            if let device = try await buildSignedDeviceIdentity() {
                params["device"] = device
            }
            
            let response = try await request(method: "connect", params: params)
            
            // 存储 deviceToken
            if let resp = response as? [String: Any],
               let auth = resp["auth"] as? [String: Any],
               let deviceToken = auth["deviceToken"] as? String {
                storeDeviceToken(deviceToken)
            }
            
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
    
    // MARK: - Device Identity
    
    private func loadOrCreateDeviceIdentity() -> DeviceIdentity? {
        // 从 Keychain 加载或创建新的 Ed25519 密钥对
        // 实现略...
        return nil
    }
    
    private func buildSignedDeviceIdentity() async throws -> [String: Any]? {
        guard let identity = deviceIdentity else { return nil }
        
        let signedAt = Int(Date().timeIntervalSince1970 * 1000)
        let version = connectNonce != nil ? "v2" : "v1"
        
        // 构建签名载荷
        let payload = buildDeviceAuthPayload(
            version: version,
            deviceId: identity.id,
            signedAt: signedAt,
            nonce: connectNonce
        )
        
        // 使用 Ed25519 签名
        // 实现略...
        
        return [
            "id": identity.id,
            "publicKey": identity.publicKey,
            "signature": "signature_here",
            "signedAt": signedAt,
            "nonce": connectNonce
        ]
    }
    
    private func buildDeviceAuthPayload(
        version: String,
        deviceId: String,
        signedAt: Int,
        nonce: String?
    ) -> String {
        var parts = [
            version,
            deviceId,
            "openclaw-deck-swift",
            "webchat",
            "operator",
            operatorScopes.joined(separator: ","),
            String(signedAt),
            getPreferredAuthToken() ?? ""
        ]
        
        if version == "v2" {
            parts.append(nonce ?? "")
        }
        
        return parts.joined(separator: "|")
    }
    
    // MARK: - Token Management
    
    private func getPreferredAuthToken() -> String? {
        // 优先使用存储的 deviceToken，其次使用配置的 token
        // 实现略...
        return token
    }
    
    private func storeDeviceToken(_ token: String) {
        // 存储到 Keychain
        // 实现略...
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

### 设备认证流程

```
┌─────────────────────────────────────────────────────────────────┐
│                     Device Authentication                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. 首次启动：生成 Ed25519 密钥对                                  │
│     ├─ privateKey: 存储到 Keychain（加密）                        │
│     ├─ publicKey: base64url 编码                                 │
│     └─ id: SHA-256(publicKey) 作为设备 ID                        │
│                                                                  │
│  2. 连接时：构建签名载荷                                          │
│     payload = version|deviceId|clientId|clientMode|role|         │
│               scopes|signedAt|token|nonce                        │
│                                                                  │
│  3. 签名载荷                                                      │
│     signature = Ed25519.sign(payload, privateKey)                │
│                                                                  │
│  4. 发送 connect 请求                                             │
│     { device: { id, publicKey, signature, signedAt, nonce } }    │
│                                                                  │
│  5. Gateway 返回 deviceToken                                      │
│     存储到 Keychain 供下次使用                                    │
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

### Keychain 服务

```swift
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private let deviceIdentityKey = "openclaw.deck.deviceIdentity.v1"
    private let deviceTokenKey = "openclaw.deck.deviceToken.v1"
    
    // MARK: - Device Identity
    
    func saveDeviceIdentity(_ identity: DeviceIdentity) throws {
        let data = try JSONEncoder().encode(identity)
        try save(key: deviceIdentityKey, data: data)
    }
    
    func loadDeviceIdentity() throws -> DeviceIdentity? {
        guard let data = try load(key: deviceIdentityKey) else { return nil }
        return try JSONDecoder().decode(DeviceIdentity.self, from: data)
    }
    
    // MARK: - Device Token
    
    func saveDeviceToken(_ token: String, for gatewayURL: String) throws {
        let key = "\(deviceTokenKey):\(gatewayURL)"
        try save(key: key, data: token.data(using: .utf8)!)
    }
    
    func loadDeviceToken(for gatewayURL: String) throws -> String? {
        let key = "\(deviceTokenKey):\(gatewayURL)"
        guard let data = try load(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Private
    
    private func save(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: "KeychainService", code: Int(status))
        }
    }
    
    private func load(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
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