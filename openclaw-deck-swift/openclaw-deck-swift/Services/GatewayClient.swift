// GatewayClient.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation

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

    /// WebSocket 任务（用于连接和通信）
    private var webSocket: URLSessionWebSocketTask?

    /// 待处理请求字典
    private var pendingRequests: [String: PendingRequest] = [:]

    /// 消息计数器（用于生成唯一 ID）
    private var messageCounter: Int = 0

    // MARK: - Callbacks

    /// 事件回调（接收来自 Gateway 的事件）
    var onEvent: ((GatewayEvent) -> Void)?

    /// 连接状态回调（通知连接状态变化）
    var onConnection: ((Bool) -> Void)?

    // MARK: - Constants

    private let requestTimeout: TimeInterval = 30
    private let operatorScopes = ["operator.read", "operator.write"]

    // MARK: - Initialization

    init(url: URL, token: String? = nil, isMock: Bool = false) {
        self.url = url
        self.token = token
        self.isMock = isMock
    }

    // MARK: - Public Methods

    /// 建立连接并完成握手
    func connect() async {
        print("[GatewayClient] Connecting to \(url)")

        // 模拟模式下直接设置连接成功
        if isMock {
            connected = true
            onConnection?(true)
            print("[GatewayClient] Mock connected")
            return
        }

        let session = URLSession.shared
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()

        // 开始接收消息
        receiveMessage()

        // 发送 connect 握手请求
        await sendConnect()
    }

    /// 断开连接
    func disconnect() {
        print("[GatewayClient] Disconnecting")

        let wasConnected = connected
        connected = false

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

    /// 发送请求并等待响应
    func request(method: String, params: [String: Any]? = nil) async throws -> GatewayResponse {
        // 模拟模式下返回模拟响应
        if isMock {
            guard connected else {
                throw NSError(
                    domain: "GatewayClient",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Gateway not connected"]
                )
            }

            let id = nextId()
            print("[GatewayClient] Mock sending request: \(method) with id: \(id)")

            // 返回模拟响应
            return GatewayResponse(
                id: id,
                ok: true,
                payload: ["status": "success", "mock": true],
                error: nil
            )
        }

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
        // 模拟模式下返回模拟响应
        if isMock {
            let result = try await request(method: "agent", params: ["agentId": agentId, "message": message])
            guard let payload = result.payload as? [String: Any],
                  let runId = payload["runId"] as? String ?? (payload["mock"] as? Bool).map { _ in "mock-run-\(nextId())" },
                  let status = payload["status"] as? String else {
                return ("mock-run-\(nextId())", "success")
            }
            return (runId, status)
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
        let event = GatewayEvent.fromJSON(json)
        onEvent?(event)
    }

    /// 发送帧
    private func send(frame: GatewayRequest) {
        do {
            let encoder = JSONEncoder()
            // 使用自定义编码策略处理 Any 类型
            let data = try encodeRequest(frame)
            guard let string = String(data: data, encoding: .utf8) else {
                print("[GatewayClient] Failed to convert data to string")
                return
            }

            webSocket?.send(.string(string)) { error in
                if let error = error {
                    print("[GatewayClient] Send error: \(error)")
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

            let response = try await request(method: "connect", params: params)

            if response.ok {
                connected = true
                onConnection?(true)
                print("[GatewayClient] Connected to gateway")
            } else {
                print("[GatewayClient] Handshake failed: \(response.error?.message ?? "Unknown error")")
                disconnect()
            }

        } catch {
            print("[GatewayClient] Handshake failed: \(error)")
            disconnect()
        }
    }

    /// 处理断开连接
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
}
