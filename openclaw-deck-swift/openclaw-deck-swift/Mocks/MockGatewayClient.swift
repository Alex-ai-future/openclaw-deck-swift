@testable import openclaw_deck_swift

// MockGatewayClient.swift
// OpenClaw Deck Swift
//
// Mock Gateway 客户端 - 用于 UI 测试

import Foundation

/// Mock Gateway 客户端
@MainActor
public class MockGatewayClient: GatewayClientProtocol {
    public var connected: Bool = true
    public var connectionError: String?
    public var onEvent: ((GatewayEvent) -> Void)?
    public var onConnection: ((Bool) -> Void)?

    /// 模拟延迟（秒）
    public var simulatedDelay: Double = 0.0

    /// 模拟消息历史
    public var mockHistory: [ChatMessage] = []

    public func connect() async {
        if simulatedDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
        connected = true
        await MainActor.run {
            onConnection?(true)
        }
    }

    public func disconnect() {
        connected = false
        onConnection?(false)
    }

    public func clearError() {
        connectionError = nil
    }

    public func resetDeviceIdentity() {
        // Mock 实现
    }

    public func getSessionHistory(sessionKey _: String) async throws -> [ChatMessage]? {
        if simulatedDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
        return mockHistory
    }

    public func runAgent(
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
    }

    public func abortChat(sessionKey _: String, runId _: String?) async throws {
        // Mock 实现，什么都不做
    }
}
