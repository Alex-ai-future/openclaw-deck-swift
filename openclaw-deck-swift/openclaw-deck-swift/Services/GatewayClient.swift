// GatewayClient.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation

/// Gateway 客户端（WebSocket 连接管理）
@MainActor
@Observable
class GatewayClient {
    /// Gateway WebSocket URL
    let url: URL

    /// 认证 Token（用户手动输入，不持久化存储）
    let token: String?

    /// 连接状态（是否已连接）
    private(set) var connected: Bool = false

    /// WebSocket 任务（用于连接和通信）
    private var webSocket: URLSessionWebSocketTask?

    /// 事件回调（接收来自 Gateway 的事件）
    var onEvent: ((GatewayEvent) -> Void)?

    /// 连接状态回调（通知连接状态变化）
    var onConnection: ((Bool) -> Void)?

    /// 初始化 GatewayClient
    init(url: URL, token: String? = nil) {
        self.url = url
        self.token = token
    }

    /// 建立连接并完成握手
    func connect() async {
        // 实现连接逻辑
        print("[GatewayClient] Connecting to \(url)")

        // 模拟连接成功
        connected = true
        onConnection?(true)
    }

    /// 断开连接
    func disconnect() {
        print("[GatewayClient] Disconnecting")

        let wasConnected = connected
        connected = false
        
        // Only notify if was actually connected
        if wasConnected {
            onConnection?(false)
        }
    }

    /// 发送请求并等待响应
    func request(method: String, params: [String: String]? = nil) async throws -> GatewayResponse {
        guard connected else {
            throw NSError(
                domain: "GatewayClient",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Gateway not connected"]
            )
        }

        // 模拟请求
        let id = GatewayRequest.generateId()
        print("[GatewayClient] Sending request: \(method) with id: \(id)")

        // 返回模拟响应
        return GatewayResponse(
            id: id,
            ok: true,
            payload: "{\"status\": \"success\"}",
            error: nil
        )
    }

    /// 执行 Agent 轮次
    func runAgent(
        agentId: String,
        message: String,
        sessionKey: String? = nil
    ) async throws -> (runId: String, status: String) {
        let idempotencyKey = "agent-\(Date().timeIntervalSince1970)-\(UUID().uuidString.prefix(6))"

        var params: [String: String] = [
            "agentId": agentId,
            "message": message,
            "idempotencyKey": idempotencyKey
        ]

        if let sessionKey = sessionKey {
            params["sessionKey"] = sessionKey
        }

        let result = try await request(method: "agent", params: params)

        // 解析响应
        guard let payload = result.payload,
              let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let runId = json["runId"] as? String,
              let status = json["status"] as? String else {
            throw NSError(
                domain: "GatewayClient",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response format"]
            )
        }

        return (runId, status)
    }
}
