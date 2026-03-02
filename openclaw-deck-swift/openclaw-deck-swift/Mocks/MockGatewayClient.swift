// MockGatewayClient.swift
// OpenClaw Deck Swift
//
// Mock Gateway 客户端 - 用于 UI 测试

import Foundation

/// Mock Gateway 客户端
@MainActor
class MockGatewayClient: GatewayClientProtocol {
    var connected: Bool = true
    var connectionError: String?
    var onEvent: ((GatewayEvent) -> Void)?
    var onConnection: ((Bool) -> Void)?

    /// 模拟延迟（秒）
    var simulatedDelay: Double = 0.0

    /// 模拟消息历史
    var mockHistory: [ChatMessage] = []

    func connect() async {
        if simulatedDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
        connected = true
        await MainActor.run {
            onConnection?(true)
        }
    }

    func disconnect() {
        connected = false
        onConnection?(false)
    }

    func clearError() {
        connectionError = nil
    }

    func resetDeviceIdentity() {
        // Mock 实现
    }

    func getSessionHistory(sessionKey _: String) async throws -> [ChatMessage]? {
        if simulatedDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
        return mockHistory
    }

    func runAgent(
        agentId _: String,
        message _: String,
        sessionKey: String?
    ) async throws -> (runId: String, status: String) {
        if simulatedDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }

        let runId = "mock-run-\(UUID().uuidString.prefix(8))"

        // 模拟 lifecycle.start 事件
        let startEvent = GatewayEvent(
            event: "agent",
            payload: [
                "runId": runId,
                "stream": "lifecycle",
                "sessionKey": sessionKey ?? "test",
                "data": ["phase": "start"],
            ]
        )
        onEvent?(startEvent)

        // 模拟 lifecycle.end 事件
        let endEvent = GatewayEvent(
            event: "agent",
            payload: [
                "runId": runId,
                "stream": "lifecycle",
                "sessionKey": sessionKey ?? "test",
                "data": ["phase": "end"],
            ]
        )
        onEvent?(endEvent)

        return (runId, "success")

        func abortChat(sessionKey _: String, runId _: String) async throws {
            // Mock 实现，什么都不做
        }
    }
}
