// GatewayClient.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import CryptoKit
import Foundation
import os

private let logger = Logger(subsystem: "com.openclaw.deck", category: "Gateway")

// MARK: - Types

/// 待处理请求
struct PendingRequest {
    let continuation: CheckedContinuation<GatewayResponse, Error>
    let timeout: Task<Void, Never>
}

// MARK: - Gateway Session Status

/// 网关会话状态（从网关查询）
struct GatewaySessionStatus: Identifiable, Hashable {
    let key: String
    let sessionId: String
    let kind: String
    let updatedAt: Date
    let totalTokens: Int?
    let totalTokensFresh: Bool
    let model: String
    let contextTokens: Int
    let abortedLastRun: Bool
    let systemSent: Bool

    /// 会话 ID（用于 Identifiable）
    var id: String {
        sessionId
    }

    /// 是否正在处理中（推断）
    var isProcessing: Bool {
        // 如果最近有活动且没有系统发送，可能正在处理
        !systemSent && !abortedLastRun
    }

    /// 从网关返回的 JSON 创建
    init?(from json: [String: Any]) {
        guard let key = json["key"] as? String,
              let sessionId = json["sessionId"] as? String,
              let kind = json["kind"] as? String,
              let updatedAtMs = json["updatedAt"] as? Double,
              let model = json["model"] as? String,
              let contextTokens = json["contextTokens"] as? Int
        else {
            return nil
        }

        self.key = key
        self.sessionId = sessionId
        self.kind = kind
        updatedAt = Date(timeIntervalSince1970: updatedAtMs / 1000)
        totalTokens = json["totalTokens"] as? Int
        totalTokensFresh = json["totalTokensFresh"] as? Bool ?? false
        self.model = model
        self.contextTokens = contextTokens
        abortedLastRun = json["abortedLastRun"] as? Bool ?? false
        systemSent = json["systemSent"] as? Bool ?? false
    }
}

// MARK: - GatewayClient

/// Gateway 客户端（WebSocket 连接管理）
@MainActor
@Observable
class GatewayClient: GatewayClientProtocol {
    // Fix for Swift 6 @Observable + @MainActor crash in XCTest
    // See: https://github.com/swiftlang/swift/issues/87316
    nonisolated deinit {}

    // MARK: - Configuration

    /// Gateway WebSocket URL
    let url: URL

    /// 认证 Token（用户手动输入，不持久化存储）
    let token: String?

    /// 是否为模拟模式（用于测试）
    private let isMock: Bool

    // MARK: - State

    /// 连接状态（是否已连接）
    private(set) var connected: Bool = false

    /// 连接错误信息
    private(set) var connectionError: String?

    /// 是否正在连接
    private(set) var isConnecting: Bool = false

    /// WebSocket 任务（用于连接和通信）
    private var webSocket: URLSessionWebSocketTask?

    /// 待处理请求字典
    private var pendingRequests: [String: PendingRequest] = [:]

    /// 消息计数器（用于生成唯一 ID）
    private var messageCounter: Int = 0

    /// Connect nonce from challenge
    private var connectNonce: String?

    /// Whether connect request was sent
    private var connectSent: Bool = false

    /// Callback for waiting on connect challenge
    private var challengeCallback: ((String) -> Void)?

    /// Timeout timer for challenge
    private var challengeTimeoutTimer: Timer?

    /// Whether challenge has been completed (success or timeout)
    private var challengeCompleted: Bool = false

    // MARK: - Callbacks

    /// 事件回调（接收来自 Gateway 的事件）
    var onEvent: ((GatewayEvent) -> Void)?

    /// 连接状态回调（通知连接状态变化）
    var onConnection: ((Bool) -> Void)?

    // MARK: - Constants

    private let requestTimeout: TimeInterval = 60
    private let connectChallengeTimeout: TimeInterval = 15
    private let operatorScopes = ["operator.read", "operator.write", "operator.admin"]
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
        guard !isMock else {
            connected = true
            connectionError = nil
            isConnecting = false
            onConnection?(true)
            return
        }

        guard !isConnecting else {
            return
        }

        isConnecting = true
        connectionError = nil
        connectNonce = nil
        connectSent = false

        let session = URLSession.shared
        var request = URLRequest(url: url)
        // Set Origin header - required by Gateway CORS policy
        let origin = url.absoluteString
            .replacingOccurrences(of: "ws://", with: "http://")
            .replacingOccurrences(of: "wss://", with: "https://")
        request.setValue(origin, forHTTPHeaderField: "Origin")
        webSocket = session.webSocketTask(with: request)
        webSocket?.resume()

        // 开始接收消息
        await receiveMessage()

        // 等待 750ms 让网络稳定（给 TCP 和 WebSocket 握手缓冲时间）
        try? await Task.sleep(nanoseconds: 750_000_000)

        // Wait for connect challenge before sending request
        do {
            try await waitForChallenge()
        } catch {
            logger.error("Failed to receive connect challenge: \(error.localizedDescription)")
            connectionError = error.localizedDescription
            isConnecting = false
            onConnection?(false)
            disconnect()
            return
        }

        // Send connect request with nonce
        await sendConnect()
    }

    /// Wait for connect.challenge event from Gateway
    private func waitForChallenge() async throws {
        // If we already have a nonce (from retry), don't wait
        if connectNonce != nil {
            return
        }

        // Reset challenge completed flag
        challengeCompleted = false

        _ = try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<String, Error>) in
            var resumed = false

            // Set callback to resume continuation when challenge is received
            self.challengeCallback = { [weak self] nonce in
                guard let self else { return }
                Task { @MainActor in
                    guard !resumed, !self.challengeCompleted else { return }
                    resumed = true
                    self.challengeCompleted = true
                    self.challengeTimeoutTimer?.invalidate()
                    self.challengeTimeoutTimer = nil
                    self.challengeCallback = nil
                    continuation.resume(returning: nonce)
                }
            }

            // Timeout after 6 seconds
            _ = Timer.scheduledTimer(withTimeInterval: self.connectChallengeTimeout, repeats: false) {
                [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    guard !resumed, !self.challengeCompleted else { return }
                    resumed = true
                    self.challengeCompleted = true
                    self.challengeCallback = nil
                    self.challengeTimeoutTimer = nil
                    continuation.resume(
                        throwing: NSError(
                            domain: "GatewayClient",
                            code: -10,
                            userInfo: [NSLocalizedDescriptionKey: "Connect challenge timeout"]
                        )
                    )
                }
            }
        }
    }

    /// 断开连接
    func disconnect() {
        let wasConnected = connected
        connected = false
        isConnecting = false

        // 取消 WebSocket
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil

        // 拒绝所有待处理请求
        for (_, pending) in pendingRequests {
            pending.continuation.resume(
                throwing: NSError(
                    domain: "GatewayClient",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Connection closed"]
                )
            )
        }
        pendingRequests.removeAll()

        // 只通知如果之前已连接
        if wasConnected {
            onConnection?(false)
        }
    }

    /// 重置设备身份（清除旧的 device identity，下次连接时会生成新的）
    func resetDeviceIdentity() {
        UserDefaults.standard.removeObject(forKey: deviceIdentityStorageKey)
        // Also clear device token
        let deviceTokenKey = "\(deviceTokenStorageKeyPrefix)\(url.absoluteString)"
        UserDefaults.standard.removeObject(forKey: deviceTokenKey)
        // Device identity reset
    }

    /// 清除错误状态
    func clearError() {
        connectionError = nil
    }

    /// 发送请求并等待响应
    func request(method: String, params: [String: Any]? = nil) async throws -> GatewayResponse {
        // 允许 mock 模式、已连接状态、或 connect 握手请求
        guard isMock || connected || method == "connect" else {
            throw NSError(
                domain: "GatewayClient",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Gateway not connected"]
            )
        }

        if isMock {
            let id = nextId()
            return GatewayResponse(
                id: id,
                ok: true,
                payload: ["status": "success", "mock": true],
                error: nil
            )
        }

        let id = nextId()

        return try await withCheckedThrowingContinuation { continuation in
            // 设置超时
            let timeout = Task {
                try? await Task.sleep(nanoseconds: UInt64(requestTimeout * 1_000_000_000))
                await self.handleTimeout(id: id, method: method)
            }

            pendingRequests[id] = PendingRequest(continuation: continuation, timeout: timeout)

            // 发送请求
            let frame = GatewayRequest(id: id, method: method, params: params)
            send(frame: frame)
        }
    }

    /// 执行 Agent 轮次
    func runAgent(
        agentId: String,
        message: String,
        sessionKey: String? = nil
    ) async throws -> (runId: String, status: String) {
        if isMock {
            _ = try await request(
                method: "agent", params: ["agentId": agentId, "message": message]
            )
            return ("mock-run-\(nextId())", "success")
        }

        let idempotencyKey = "agent-\(Date().timeIntervalSince1970)-\(UUID().uuidString.prefix(6))"

        var params: [String: Any] = [
            "agentId": agentId,
            "message": message,
            "idempotencyKey": idempotencyKey,
        ]

        if let sessionKey {
            params["sessionKey"] = sessionKey
        }

        let result = try await request(method: "agent", params: params)

        // 解析响应
        guard let payload = result.payload as? [String: Any],
              let runId = payload["runId"] as? String,
              let status = payload["status"] as? String
        else {
            throw NSError(
                domain: "GatewayClient",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response format"]
            )
        }

        return (runId, status)
    }

    /// 中断当前对话
    func abortChat(sessionKey: String, runId: String? = nil) async throws {
        var params: [String: Any] = ["sessionKey": sessionKey]
        if let runId {
            params["runId"] = runId
        }
        _ = try await request(
            method: "chat.abort",
            params: params
        )
    }

    /// 获取 Session 历史消息
    func getSessionHistory(sessionKey: String) async throws -> [ChatMessage]? {
        let result = try await request(
            method: "chat.history", params: ["sessionKey": sessionKey]
        )

        guard let payload = result.payload as? [String: Any],
              let messagesData = payload["messages"] as? [[String: Any]]
        else {
            return nil
        }

        // 解析消息 - 只显示 user 和 assistant 消息
        var messages: [ChatMessage] = []
        for data in messagesData {
            guard let roleString = data["role"] as? String else {
                continue
            }

            // 从 content 数组中提取文本（只处理 text 类型）
            var text = ""
            if let content = data["content"] as? [[String: Any]] {
                for item in content {
                    let type = item["type"] as? String ?? ""
                    // 只提取 text 类型，忽略 thinking、toolCall 等
                    if type == "text", let itemText = item["text"] as? String {
                        text += itemText
                    }
                }
            }

            // 如果 content 为空，尝试直接从 text 字段获取
            if text.isEmpty {
                text = data["text"] as? String ?? ""
            }

            // 跳过 Gateway 注入的消息（子代理通知、系统消息等）
            if let model = data["model"] as? String,
               model == "gateway-injected"
            {
                continue
            }

            // 只处理 user 和 assistant 角色
            let roleLower = roleString.lowercased()
            if roleLower == "user" || roleLower == "assistant" {
                // 过滤 assistant 空消息（user 消息即使是空也保留）
                if roleLower == "assistant", text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    continue
                }

                let role = MessageRole(rawValue: roleLower) ?? .assistant
                let timestamp = Date(timeIntervalSince1970: (data["timestamp"] as? Double ?? 0) / 1000)

                messages.append(
                    ChatMessage(
                        id: data["id"] as? String ?? UUID().uuidString,
                        role: role,
                        text: text,
                        timestamp: timestamp
                    )
                )
            }
        }
        return messages
    }

    // MARK: - Session Status Query

    /// 主动查询会话状态列表
    /// - Parameter activeMinutes: 只返回最近活跃的会话（默认 60 分钟）
    /// - Returns: 会话状态列表
    func fetchSessions(activeMinutes: Int = 60) async throws -> [GatewaySessionStatus] {
        var params: [String: Any] = [:]
        params["activeMinutes"] = activeMinutes

        let result = try await request(method: "sessions.list", params: params)

        guard let payload = result.payload as? [String: Any],
              let sessions = payload["sessions"] as? [[String: Any]]
        else {
            return []
        }

        // 解析会话状态
        let statuses = sessions.compactMap { GatewaySessionStatus(from: $0) }
        logger.debug("查询到 \(statuses.count) 个活跃会话")
        return statuses
    }

    // MARK: - Private Methods

    /// 接收消息循环
    private func receiveMessage() async {

        // 等待 750ms 让网络稳定（给 TCP 和 WebSocket 握手缓冲时间）
        try? await Task.sleep(nanoseconds: 750_000_000)
        webSocket?.receive { [weak self] result in
            guard let self else { return }

            switch result {
            case let .success(message):
                switch message {
                case let .data(data):
                    Task { @MainActor in
                        self.handleData(data)
                    }
                case let .string(string):
                    Task { @MainActor in
                        self.handleString(string)
                    }
                @unknown default:
                    break
                }

                // 继续接收下一条消息
                Task { @MainActor in
                    await self.receiveMessage()

        // 等待 750ms 让网络稳定（给 TCP 和 WebSocket 握手缓冲时间）
        try? await Task.sleep(nanoseconds: 750_000_000)
                }

            case let .failure(error):
                logger.error("Receive error: \(error.localizedDescription)")
                Task { @MainActor in
                    self.handleDisconnect()
                }
            }
        }
    }

    /// 处理字符串消息
    private func handleString(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        handleData(data)
    }

    /// 处理数据消息
    private func handleData(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String
        else {
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

    /// 处理响应
    private func handleResponse(_ json: [String: Any]) {
        // 打印所有响应的完整 JSON 日志
        if let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8)
        {
            logger.info("📥 [Response] \(jsonString)")
        }

        guard let id = json["id"] as? String,
              let pending = pendingRequests.removeValue(forKey: id)
        else {
            return
        }

        // 取消超时任务
        pending.timeout.cancel()

        let ok = json["ok"] as? Bool ?? false

        if ok {
            let response = GatewayResponse(
                id: id,
                ok: ok,
                payload: json["payload"],
                error: nil
            )
            pending.continuation.resume(returning: response)
        } else {
            let errorMsg =
                (json["error"] as? [String: Any])?["message"] as? String ?? "Request failed"
            let error = NSError(
                domain: "GatewayClient",
                code: -4,
                userInfo: [NSLocalizedDescriptionKey: errorMsg]
            )
            pending.continuation.resume(throwing: error)
        }
    }

    /// 处理事件
    private func handleEvent(_ json: [String: Any]) {
        guard let event = json["event"] as? String else { return }

        // 打印所有事件的完整 JSON 日志
        if let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8)
        {
            logger.info("📩 [Event] \(jsonString)")
        }

        // Handle connect.challenge event for device auth
        if event == "connect.challenge", let payload = json["payload"] as? [String: Any],
           let nonce = payload["nonce"] as? String
        {
            // Received connect challenge

            // Call the challenge callback to resume waiting code
            if let callback = challengeCallback {
                challengeCallback = nil
                challengeTimeoutTimer?.invalidate()
                challengeTimeoutTimer = nil
                callback(nonce)
            }

            connectNonce = nonce
            connectSent = false

            // ⚠️ 注意：不再自动调用 sendConnect()
            // connect() 方法中会在 waitForChallenge() 返回后显式调用

            return
        }

        let gatewayEvent = GatewayEvent.fromJSON(json)
        onEvent?(gatewayEvent)
    }

    /// 发送帧
    private func send(frame: GatewayRequest) {
        guard let webSocket else {
            return
        }

        guard webSocket.state == .running else {
            return
        }

        do {
            let data = try encodeRequest(frame)
            guard let string = String(data: data, encoding: .utf8) else {
                return
            }

            // 打印所有发送请求的完整 JSON 日志
            if let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8)
            {
                logger.info("📤 [Request] \(prettyString)")
            }

            webSocket.send(.string(string)) { [weak self] error in
                if let error {
                    logger.error("Send error: \(error.localizedDescription)")
                    Task { @MainActor in
                        self?.handleDisconnect()
                    }
                }
            }
        } catch {
            logger.error("Encode error: \(error.localizedDescription)")
        }
    }

    /// 编码请求帧
    private func encodeRequest(_ request: GatewayRequest) throws -> Data {
        var json: [String: Any] = [
            "type": request.type,
            "id": request.id,
            "method": request.method,
        ]
        if let params = request.params {
            json["params"] = params
        }
        return try JSONSerialization.data(withJSONObject: json)
    }

    /// 发送 connect 握手
    private func sendConnect() async {
        if connectSent {
            return
        }
        connectSent = true

        do {
            // Build device identity with nonce if available
            var device: [String: Any]? = nil
            do {
                device = try await buildSignedDeviceIdentity(nonce: connectNonce)
            } catch {
                // Device identity unavailable
            }

            var params: [String: Any] = [
                "client": [
                    "id": "gateway-client",
                    "version": "2026.2.16",
                    "platform": "web",
                    "mode": "webchat",
                ],
                "minProtocol": 3,
                "maxProtocol": 3,
                "role": "operator",
                "scopes": operatorScopes,
            ]

            // Add device identity if available
            if let device {
                params["device"] = device
            }

            // Add auth token if available
            let authToken = getPreferredAuthToken()
            if !authToken.isEmpty {
                params["auth"] = ["token": authToken]
            }

            let result = try await request(method: "connect", params: params)

            // Check for device token in response
            if let payload = result.payload as? [String: Any],
               let auth = payload["auth"] as? [String: Any],
               let deviceToken = auth["deviceToken"] as? String
            {
                storeDeviceToken(deviceToken)
            }

            connected = true
            connectionError = nil
            isConnecting = false
            onConnection?(true)

        } catch {
            logger.error("❌ connect 握手失败：\(error.localizedDescription)")
            connectionError = error.localizedDescription
            isConnecting = false
            onConnection?(false)
            disconnect()
        }
    }

    /// Build signed device identity
    private func buildSignedDeviceIdentity(nonce: String?) async throws -> [String: Any] {
        let identity = try loadOrCreateDeviceIdentity()
        let signedAt = Date().timeIntervalSince1970 * 1000 // milliseconds

        // Use v2 protocol if nonce is provided
        let version = nonce != nil ? "v2" : "v1"
        // Building device identity

        let payload = buildDeviceAuthPayload(
            version: version,
            deviceId: identity["id"] as! String,
            clientId: "gateway-client",
            clientMode: "webchat",
            role: "operator",
            scopes: operatorScopes,
            signedAtMs: Int(signedAt),
            token: getPreferredAuthToken().isEmpty ? nil : getPreferredAuthToken(),
            nonce: nonce
        )

        // Sign the payload using Ed25519
        // privateKeySeed is stored as base64Url encoded 32-byte seed
        guard let privateKeySeedBase64 = identity["privateKeySeedBase64"] as? String,
              let privateKeySeed = base64UrlDecode(privateKeySeedBase64)
        else {
            throw NSError(
                domain: "GatewayClient", code: -5,
                userInfo: [NSLocalizedDescriptionKey: "Failed to decode private key seed"]
            )
        }

        // Ensure we have exactly 32 bytes (Ed25519 seed size)
        guard privateKeySeed.count == 32 else {
            throw NSError(
                domain: "GatewayClient", code: -6,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Incorrect private key seed size: \(privateKeySeed.count) bytes, expected 32",
                ]
            )
        }

        let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeySeed)
        let signatureData = try privateKey.signature(for: Array(payload.utf8))

        // Build result dictionary - only include nonce if provided
        var result: [String: Any] = [
            "id": identity["id"] as! String,
            "publicKey": identity["publicKey"] as! String,
            "signature": base64UrlEncode(signatureData),
            "signedAt": Int(signedAt),
        ]
        if let nonce {
            result["nonce"] = nonce
        }
        // Device identity signature generated
        return result
    }

    /// Load or create device identity using Ed25519
    private func loadOrCreateDeviceIdentity() throws -> [String: Any] {
        // Try to load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: deviceIdentityStorageKey),
           let identity = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           identity["id"] != nil, identity["publicKey"] != nil
        {
            // Check for new format (privateKeySeedBase64)
            if identity["privateKeySeedBase64"] != nil {
                // Validate the key size
                if let seedBase64 = identity["privateKeySeedBase64"] as? String,
                   let seedData = base64UrlDecode(seedBase64)
                {
                    if seedData.count == 32 {
                        return identity
                    }
                    // Invalid seed size, recreate identity
                    // Invalid seed size, recreating identity
                }
            }

            // Migrate old format (privateKeyBase64) to new format
            // Old format may have stored standard base64 instead of base64url
            if let oldPrivateKeyBase64 = identity["privateKeyBase64"] as? String {
                // Try base64url decode first
                var privateKeyData = base64UrlDecode(oldPrivateKeyBase64)

                // If base64url decode failed or produced invalid size, try standard base64
                if privateKeyData == nil || (privateKeyData!.count != 32 && privateKeyData!.count != 64) {
                    // Try standard base64 decode
                    var base64 = oldPrivateKeyBase64
                    // Add padding if needed
                    while base64.count % 4 != 0 {
                        base64.append("=")
                    }
                    privateKeyData = Data(base64Encoded: base64)
                }

                if let privateKeyData {
                    // If old key was 64 bytes, extract just the 32-byte seed
                    if privateKeyData.count == 64 {
                        let seedData = privateKeyData.subdata(in: 0 ..< 32)
                        var newIdentity = identity
                        newIdentity["privateKeySeedBase64"] = base64UrlEncode(seedData)

                        // Save migrated identity
                        if let newData = try? JSONSerialization.data(withJSONObject: newIdentity) {
                            UserDefaults.standard.set(newData, forKey: deviceIdentityStorageKey)
                        }
                        return newIdentity
                    } else if privateKeyData.count == 32 {
                        // Old key was already 32 bytes, just rename the key
                        var newIdentity = identity
                        newIdentity["privateKeySeedBase64"] = base64UrlEncode(privateKeyData)

                        if let newData = try? JSONSerialization.data(withJSONObject: newIdentity) {
                            UserDefaults.standard.set(newData, forKey: deviceIdentityStorageKey)
                        }
                        return newIdentity
                    }
                    // Invalid size, fall through to recreate
                }
            }

            // Migration failed, create new identity
            // Failed to migrate old identity, creating new one
        }

        // Create new Ed25519 identity
        let privateKey = Curve25519.Signing.PrivateKey()
        let publicKey = privateKey.publicKey

        // Raw representation is 32 bytes for Ed25519 (the seed)
        let publicKeyData = publicKey.rawRepresentation
        let privateKeySeed = privateKey.rawRepresentation

        // Debug: log key sizes
        logger.debug(
            "Creating new identity - publicKey: \(publicKeyData.count) bytes, privateKeySeed: \(privateKeySeed.count) bytes"
        )

        // Generate device ID from public key hash (SHA-256, then hex)
        let digest = SHA256.hash(data: publicKeyData)
        let id = digest.compactMap { String(format: "%02x", $0) }.joined()

        let identity: [String: Any] = [
            "id": id,
            "publicKey": base64UrlEncode(publicKeyData),
            "privateKeySeedBase64": base64UrlEncode(privateKeySeed),
        ]

        // Save to UserDefaults
        if let data = try? JSONSerialization.data(withJSONObject: identity) {
            UserDefaults.standard.set(data, forKey: deviceIdentityStorageKey)
        }

        return identity
    }

    /// Build device auth payload string
    private func buildDeviceAuthPayload(
        version: String,
        deviceId: String,
        clientId: String,
        clientMode: String,
        role: String,
        scopes: [String],
        signedAtMs: Int,
        token: String?,
        nonce: String?
    ) -> String {
        let scopesString = scopes.joined(separator: ",")
        let tokenString = token ?? ""
        var base = [
            version,
            deviceId,
            clientId,
            clientMode,
            role,
            scopesString,
            String(signedAtMs),
            tokenString,
        ]
        if version == "v2" {
            base.append(nonce ?? "")
        }
        return base.joined(separator: "|")
    }

    /// Get preferred auth token (device token or user token)
    private func getPreferredAuthToken() -> String {
        let deviceToken = getStoredDeviceToken()
        if !deviceToken.isEmpty {
            return deviceToken
        }
        return token ?? ""
    }

    /// Get stored device token
    private func getStoredDeviceToken() -> String {
        let key = "\(deviceTokenStorageKeyPrefix)\(url.absoluteString)"
        return UserDefaults.standard.string(forKey: key) ?? ""
    }

    /// Store device token
    private func storeDeviceToken(_ token: String) {
        let key = "\(deviceTokenStorageKeyPrefix)\(url.absoluteString)"
        UserDefaults.standard.set(token, forKey: key)
    }

    /// 处理断开连接
    private func handleDisconnect() {
        let wasConnected = connected
        connected = false
        isConnecting = false

        if wasConnected {
            onConnection?(false)
        }

        // 拒绝所有待处理请求
        for (_, pending) in pendingRequests {
            pending.continuation.resume(
                throwing: NSError(
                    domain: "GatewayClient",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Connection closed"]
                )
            )
        }
        pendingRequests.removeAll()
    }

    /// 处理请求超时
    private func handleTimeout(id: String, method: String) async {
        if let pending = pendingRequests.removeValue(forKey: id) {
            pending.continuation.resume(
                throwing: NSError(
                    domain: "GatewayClient",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "Request \(method) timed out"]
                )
            )
        }
    }

    /// 生成下一个消息 ID
    private func nextId() -> String {
        messageCounter += 1
        return "deck-\(messageCounter)-\(Int(Date().timeIntervalSince1970 * 1000))"
    }

    /// Base64URL encode (without padding)
    private func base64UrlEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// Base64URL decode (handles missing padding)
    private func base64UrlDecode(_ string: String) -> Data? {
        var base64 =
            string
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
        // Add padding if needed
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        return Data(base64Encoded: base64)
    }

    /// Mask token for logging (show first 4 and last 4 characters)
    private func maskToken(_ token: String) -> String {
        guard token.count > 8 else {
            return String(repeating: "*", count: token.count)
        }
        let prefix = token.prefix(4)
        let suffix = token.suffix(4)
        let masked = String(repeating: "*", count: token.count - 8)
        return "\(prefix)\(masked)\(suffix)"
    }
}
