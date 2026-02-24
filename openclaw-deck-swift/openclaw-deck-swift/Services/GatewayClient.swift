// GatewayClient.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation
import CryptoKit

// MARK: - Types

/// 待处理请求
struct PendingRequest {
    let continuation: CheckedContinuation<GatewayResponse, Error>
    let timeout: Task<Void, Never>
}

// MARK: - GatewayClient

/// Gateway 客户端（WebSocket 连接管理）
@MainActor
@Observable
class GatewayClient {

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

    // MARK: - Callbacks

    /// 事件回调（接收来自 Gateway 的事件）
    var onEvent: ((GatewayEvent) -> Void)?

    /// 连接状态回调（通知连接状态变化）
    var onConnection: ((Bool) -> Void)?

    // MARK: - Constants

    private let requestTimeout: TimeInterval = 30
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
        guard !isMock else {
            connected = true
            connectionError = nil
            isConnecting = false
            onConnection?(true)
            print("[GatewayClient] Mock connected")
            return
        }

        guard !isConnecting else {
            print("[GatewayClient] Already connecting")
            return
        }

        isConnecting = true
        connectionError = nil
        connectNonce = nil
        connectSent = false

        print("[GatewayClient] Connecting to \(url)")

        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.setValue("http://127.0.0.1", forHTTPHeaderField: "Origin")
        webSocket = session.webSocketTask(with: request)
        webSocket?.resume()

        print("[GatewayClient] WebSocket state after resume: \(webSocket?.state ?? .suspended)")

        // 开始接收消息
        receiveMessage()

        // 延迟发送 connect 请求，等待可能的 challenge
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            Task { @MainActor in
                await self?.sendConnect()
            }
        }
    }

    /// 断开连接
    func disconnect() {
        print("[GatewayClient] Disconnecting")

        let wasConnected = connected
        connected = false
        isConnecting = false

        // 取消 WebSocket
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil

        // 拒绝所有待处理请求
        for (_, pending) in pendingRequests {
            pending.continuation.resume(throwing: NSError(
                domain: "GatewayClient",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Connection closed"]
            ))
        }
        pendingRequests.removeAll()

        // 只通知如果之前已连接
        if wasConnected {
            onConnection?(false)
        }
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
            print("[GatewayClient] Mock sending request: \(method) with id: \(id)")
            return GatewayResponse(
                id: id,
                ok: true,
                payload: ["status": "success", "mock": true],
                error: nil
            )
        }

        print("[GatewayClient] Sending request: \(method)")

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
            let result = try await request(method: "agent", params: ["agentId": agentId, "message": message])
            return ("mock-run-\(nextId())", "success")
        }
        
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

        // 解析响应
        guard let payload = result.payload as? [String: Any],
              let runId = payload["runId"] as? String,
              let status = payload["status"] as? String else {
            throw NSError(
                domain: "GatewayClient",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response format"]
            )
        }

        return (runId, status)
    }
    
    /// 获取 Session 历史消息
    func getSessionHistory(sessionKey: String) async throws -> [ChatMessage]? {
        let result = try await request(method: "sessions_history", params: ["sessionKey": sessionKey])
        
        guard let payload = result.payload as? [String: Any],
              let messagesData = payload["messages"] as? [[String: Any]] else {
            return nil
        }
        
        // 解析消息
        return messagesData.compactMap { data -> ChatMessage? in
            guard let roleString = data["role"] as? String,
                  let text = data["text"] as? String else {
                return nil
            }
            
            let role = MessageRole(rawValue: roleString) ?? .user
            let timestamp = Date(timeIntervalSince1970: (data["timestamp"] as? Double ?? 0) / 1000)
            
            return ChatMessage(
                id: data["id"] as? String ?? UUID().uuidString,
                role: role,
                text: text,
                timestamp: timestamp
            )
        }
    }
    
    /// 列出所有活跃 Sessions
    func listSessions() async throws -> [String] {
        let result = try await request(method: "sessions_list", params: [:])
        
        guard let payload = result.payload as? [String: Any],
              let sessions = payload["sessions"] as? [String] else {
            return []
        }
        
        return sessions
    }

    // MARK: - Private Methods

    /// 接收消息循环
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    Task { @MainActor in
                        self.handleData(data)
                    }
                case .string(let string):
                    Task { @MainActor in
                        self.handleString(string)
                    }
                @unknown default:
                    break
                }

                // 继续接收下一条消息
                self.receiveMessage()

            case .failure(let error):
                print("[GatewayClient] Receive error: \(error)")
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

    /// 处理响应
    private func handleResponse(_ json: [String: Any]) {
        guard let id = json["id"] as? String,
              let pending = pendingRequests.removeValue(forKey: id) else {
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
            let errorMsg = (json["error"] as? [String: Any])?["message"] as? String ?? "Request failed"
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
        
        // Handle connect.challenge event for device auth
        if event == "connect.challenge", let payload = json["payload"] as? [String: Any], let nonce = payload["nonce"] as? String {
            print("[GatewayClient] Received connect challenge, signing with nonce...")
            self.connectNonce = nonce
            self.connectSent = false
            // Retry connect with nonce after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                Task { @MainActor in
                    await self?.sendConnect()
                }
            }
            return
        }

        let gatewayEvent = GatewayEvent.fromJSON(json)
        onEvent?(gatewayEvent)
    }

    /// 发送帧
    private func send(frame: GatewayRequest) {
        guard let webSocket = webSocket else {
            print("[GatewayClient] Cannot send: WebSocket is nil")
            return
        }

        guard webSocket.state == .running else {
            print("[GatewayClient] Cannot send: WebSocket state is \(webSocket.state)")
            return
        }

        do {
            let data = try encodeRequest(frame)
            guard let string = String(data: data, encoding: .utf8) else {
                print("[GatewayClient] Failed to convert data to string")
                return
            }

            print("[GatewayClient] Sending: \(frame.method) id=\(frame.id)")
            webSocket.send(.string(string)) { error in
                if let error = error {
                    print("[GatewayClient] Send error: \(error)")
                } else {
                    print("[GatewayClient] Sent successfully")
                }
            }
        } catch {
            print("[GatewayClient] Encode error: \(error)")
        }
    }

    /// 编码请求帧
    private func encodeRequest(_ request: GatewayRequest) throws -> Data {
        var json: [String: Any] = [
            "type": request.type,
            "id": request.id,
            "method": request.method
        ]
        if let params = request.params {
            json["params"] = params
        }
        return try JSONSerialization.data(withJSONObject: json)
    }

    /// 发送 connect 握手
    private func sendConnect() async {
        guard !connectSent else {
            print("[GatewayClient] Connect already sent, skipping")
            return
        }
        connectSent = true

        print("[GatewayClient] Sending connect request, nonce: \(connectNonce ?? "nil")")

        do {
            // Build device identity with nonce if available
            var device: [String: Any]? = nil
            do {
                device = try await buildSignedDeviceIdentity(nonce: connectNonce)
                print("[GatewayClient] Device identity built successfully")
            } catch {
                print("[GatewayClient] Device identity unavailable: \(error)")
            }
            
            var params: [String: Any] = [
                "client": [
                    "id": "gateway-client",
                    "version": "2026.2.16",
                    "platform": "ios",
                    "mode": "webchat"
                ],
                "minProtocol": 3,
                "maxProtocol": 3,
                "role": "operator",
                "scopes": operatorScopes
            ]
            
            // Add device identity if available
            if let device = device {
                params["device"] = device
            }

            // 添加 token 认证（用户手动输入）
            let authToken = getPreferredAuthToken()
            if !authToken.isEmpty {
                params["auth"] = ["token": authToken]
            }

            let result = try await request(method: "connect", params: params)
            
            // Check for device token in response
            if let payload = result.payload as? [String: Any],
               let auth = payload["auth"] as? [String: Any],
               let deviceToken = auth["deviceToken"] as? String {
                storeDeviceToken(deviceToken)
            }

            if result.ok {
                connected = true
                connectionError = nil
                isConnecting = false
                onConnection?(true)
                print("[GatewayClient] Connected to gateway")
            } else {
                let errorMsg = result.error?.message ?? "Handshake failed"
                connectionError = errorMsg
                isConnecting = false
                print("[GatewayClient] Handshake failed: \(errorMsg)")
                disconnect()
            }

        } catch {
            connectionError = error.localizedDescription
            isConnecting = false
            print("[GatewayClient] Handshake failed: \(error)")
            disconnect()
        }
    }
    
    /// Build signed device identity
    private func buildSignedDeviceIdentity(nonce: String?) async throws -> [String: Any] {
        let identity = try loadOrCreateDeviceIdentity()
        let signedAt = Int(Date().timeIntervalSince1970 * 1000)  // Integer milliseconds

        // Use v2 protocol if nonce is provided
        let version = nonce != nil ? "v2" : "v1"

        print("[GatewayClient] Building device identity: version=\(version), nonce=\(nonce ?? "nil"), signedAt=\(signedAt)")

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
        let privateKeyData = Data(base64Encoded: identity["privateKeyBase64"] as! String)!
        let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyData)
        let signatureData = try privateKey.signature(for: Array(payload.utf8))

        // Build result dictionary - only include nonce if provided
        var result: [String: Any] = [
            "id": identity["id"] as! String,
            "publicKey": identity["publicKey"] as! String,
            "signature": base64UrlEncode(signatureData),
            "signedAt": Int(signedAt)
        ]
        if let nonce = nonce {
            result["nonce"] = nonce
        }
        return result
    }

    /// Load or create device identity using Ed25519
    private func loadOrCreateDeviceIdentity() throws -> [String: Any] {
        // Try to load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: deviceIdentityStorageKey),
           let identity = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           identity["id"] != nil, identity["publicKey"] != nil, identity["privateKeyBase64"] != nil {
            return identity
        }

        // Create new Ed25519 identity
        let privateKey = Curve25519.Signing.PrivateKey()
        let publicKey = privateKey.publicKey

        // Raw representation is 32 bytes for Ed25519
        let publicKeyData = publicKey.rawRepresentation
        let privateKeyData = privateKey.rawRepresentation

        // Generate device ID from public key hash (SHA-256, then hex)
        let digest = SHA256.hash(data: publicKeyData)
        let id = digest.compactMap { String(format: "%02x", $0) }.joined()

        let identity: [String: Any] = [
            "id": id,
            "publicKey": base64UrlEncode(publicKeyData),
            "privateKeyBase64": base64UrlEncode(privateKeyData)
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

        var parts = [
            version,
            deviceId,
            clientId,
            clientMode,
            role,
            scopesString,
            String(signedAtMs),
            tokenString
        ]

        print("[GatewayClient] Payload parts: \(parts)")

        // Add nonce for v2 protocol
        if version == "v2" {
            parts.append(nonce ?? "")
            print("[GatewayClient] Adding nonce to payload")
        }

        let payload = parts.joined(separator: "|")
        print("[GatewayClient] Final payload: \(payload)")
        return payload
    }
    
    /// Get preferred auth token (device token or user token)
    private func getPreferredAuthToken() -> String {
        let deviceToken = getStoredDeviceToken()
        return deviceToken.isEmpty ? (token ?? "") : deviceToken
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
            pending.continuation.resume(throwing: NSError(
                domain: "GatewayClient",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Connection closed"]
            ))
        }
        pendingRequests.removeAll()
    }

    /// 处理请求超时
    private func handleTimeout(id: String, method: String) async {
        if pendingRequests[id] != nil {
            pendingRequests.removeValue(forKey: id)
            print("[GatewayClient] Request \(method) timed out")
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
}
