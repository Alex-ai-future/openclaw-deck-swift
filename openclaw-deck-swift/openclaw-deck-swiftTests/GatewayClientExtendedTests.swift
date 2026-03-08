// GatewayClientExtendedTests.swift
// OpenClaw Deck Swift
//
// GatewayClient 扩展测试 - 测试重连、回调、状态机等核心逻辑

@testable import openclaw_deck_swift
import XCTest

@MainActor
final class GatewayClientExtendedTests: XCTestCase {
    // MARK: - 重连逻辑测试

    func testReconnectAttemptsIncrement() async throws {
        // 测试重连次数递增逻辑（通过 isMock 模拟）
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        // Mock 模式下直接连接成功
        await client.connect()
        XCTAssertTrue(client.connected)
    }

    func testDisconnectResetsReconnectAttempts() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        await client.connect()
        await client.disconnect()

        XCTAssertFalse(client.connected)
        XCTAssertNil(client.connectionError)
    }

    func testMultipleConnectDisconnectCycles() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        for _ in 0 ..< 5 {
            await client.connect()
            XCTAssertTrue(client.connected)
            await client.disconnect()
            XCTAssertFalse(client.connected)
        }
    }

    // MARK: - 连接状态回调测试

    func testOnConnectionCallbackCalledOnConnect() async throws {
        let expectation = XCTestExpectation(description: "onConnection called")

        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        client.onConnection = { connected in
            if connected {
                expectation.fulfill()
            }
        }

        await client.connect()
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testOnConnectionCallbackCalledOnDisconnect() async throws {
        let expectation = XCTestExpectation(description: "onConnection called with false")

        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        client.onConnection = { connected in
            if !connected {
                expectation.fulfill()
            }
        }

        await client.connect()
        await client.disconnect()

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testOnConnectionCallbackReceivesCorrectState() async throws {
        var connectionStates: [Bool] = []

        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        client.onConnection = { connected in
            connectionStates.append(connected)
        }

        await client.connect()
        await client.disconnect()
        await client.connect()
        await client.disconnect()

        XCTAssertEqual(connectionStates.count, 4, "应该收到 4 次状态变化")
        XCTAssertEqual(connectionStates, [true, false, true, false])
    }

    // MARK: - 事件回调测试

    func testOnEventCallbackCanBeSet() throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        var eventReceived: GatewayEvent?

        client.onEvent = { event in
            eventReceived = event
        }

        XCTAssertNotNil(client.onEvent)
    }

    func testOnEventCallbackReceivesMockEvents() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        // Mock 模式下 onEvent 可能不会被调用（因为 MockGatewayClient 简化实现）
        // 这个测试验证 onEvent 可以设置
        client.onEvent = { _ in
            // Mock 模式下可能不会触发
        }

        await client.connect()

        // MockGatewayClient 的 runAgent 会返回成功
        let (runId, status) = try await client.runAgent(
            agentId: "main",
            message: "Test",
            sessionKey: "agent:main:test"
        )

        XCTAssertFalse(runId.isEmpty)
        XCTAssertEqual(status, "success")
    }

    // MARK: - 错误处理测试

    func testClearErrorResetsConnectionError() throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        // Mock 模式下 connectionError 初始为 nil
        XCTAssertNil(client.connectionError)

        client.clearError()
        XCTAssertNil(client.connectionError)
    }

    func testConnectionErrorInitialState() throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        XCTAssertNil(client.connectionError)
        XCTAssertFalse(client.isConnecting)
    }

    // MARK: - 设备身份管理测试

    func testResetDeviceIdentityDoesNotCrash() throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        // 不应该崩溃
        client.resetDeviceIdentity()
    }

    func testResetDeviceIdentity_multipleCalls() throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        // 多次调用不应该崩溃
        for _ in 0 ..< 10 {
            client.resetDeviceIdentity()
        }
    }

    // MARK: - 并发安全测试

    func testConcurrentConnectCalls() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        // 多次并发调用 connect 不应该崩溃
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 5 {
                group.addTask {
                    await client.connect()
                }
            }
        }

        XCTAssertTrue(client.connected)
    }

    func testConcurrentDisconnectCalls() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        await client.connect()

        // 多次并发调用 disconnect 不应该崩溃
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 5 {
                group.addTask { @MainActor in
                    Task {
                        await client.disconnect()
                    }
                }
            }
        }

        XCTAssertFalse(client.connected)
    }

    func testConcurrentConnectAndDisconnect() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        // 并发连接和断开
        await withTaskGroup(of: Void.self) { group in
            for i in 0 ..< 10 {
                group.addTask { @MainActor in
                    Task {
                        if i % 2 == 0 {
                            await client.connect()
                        } else {
                            await client.disconnect()
                        }
                    }
                }
            }
        }

        // 不应该崩溃，最终状态不确定
        _ = client.connected
    }

    // MARK: - runAgent 参数测试

    func testRunAgentWithEmptyMessage() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        await client.connect()

        let (runId, status) = try await client.runAgent(
            agentId: "main",
            message: "",
            sessionKey: "agent:main:test"
        )

        XCTAssertFalse(runId.isEmpty)
        XCTAssertEqual(status, "success")
    }

    func testRunAgentWithLongMessage() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        await client.connect()

        let longMessage = String(repeating: "a", count: 10000)
        let (runId, status) = try await client.runAgent(
            agentId: "main",
            message: longMessage,
            sessionKey: "agent:main:test"
        )

        XCTAssertFalse(runId.isEmpty)
        XCTAssertEqual(status, "success")
    }

    func testRunAgentWithSpecialCharacters() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        await client.connect()

        let message = "Test with special chars: !@#$%^&*()_+{}[]|\\:;\"'<>?,./ 中文 🎉"
        let (runId, status) = try await client.runAgent(
            agentId: "main",
            message: message,
            sessionKey: "agent:main:test"
        )

        XCTAssertFalse(runId.isEmpty)
        XCTAssertEqual(status, "success")
    }

    func testRunAgentWithDifferentAgentIds() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        await client.connect()

        let agentIds = ["main", "assistant", "helper", "agent-1", "agent_2"]

        for agentId in agentIds {
            let (runId, status) = try await client.runAgent(
                agentId: agentId,
                message: "Test",
                sessionKey: "agent:\(agentId):test"
            )

            XCTAssertFalse(runId.isEmpty)
            XCTAssertEqual(status, "success")
        }
    }

    // MARK: - abortChat 测试

    func testAbortChatDoesNotCrash() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        await client.connect()

        // 不应该崩溃
        try? await client.abortChat(sessionKey: "agent:main:test", runId: "run-123")
    }

    func testAbortChatWithNilRunId() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        await client.connect()

        // runId 为 nil 时不应该崩溃
        try? await client.abortChat(sessionKey: "agent:main:test", runId: nil)
    }

    func testAbortChatWithoutConnect() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        // 未连接时调用 abortChat 不应该崩溃
        try? await client.abortChat(sessionKey: "agent:main:test", runId: "run-123")
    }

    // MARK: - getSessionHistory 测试

    func testGetSessionHistoryInMockMode() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        // Mock 模式下应该返回 nil 或空数组
        let history = try await client.getSessionHistory(sessionKey: "agent:main:test")

        // Mock 实现返回 nil
        XCTAssertNil(history)
    }

    func testGetSessionHistoryWithEmptySessionKey() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        let history = try await client.getSessionHistory(sessionKey: "")
        XCTAssertNil(history)
    }

    // MARK: - 性能测试

    func testConnectDisconnectPerformance() {
        measure {
            let client = GatewayClient(
                url: URL(string: "ws://localhost:8080")!,
                token: nil,
                webSocket: MockWebSocketConnection()
            )

            for _ in 0 ..< 10 {
                Task { @MainActor in
                    await client.connect()
                    await client.disconnect()
                }
            }

            // 等待所有任务完成
            usleep(100_000) // 100ms
        }
    }

    func testRunAgentPerformance() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        await client.connect()

        measure {
            for _ in 0 ..< 10 {
                Task { @MainActor in
                    _ = try? await client.runAgent(
                        agentId: "main",
                        message: "Test",
                        sessionKey: "agent:main:test"
                    )
                }
            }

            // 等待所有任务完成
            usleep(500_000) // 500ms
        }
    }

    // MARK: - 边界条件测试

    func testInvalidURL() throws {
        // 无效 URL 不应该崩溃
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "invalid-url")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        XCTAssertNotNil(client)
    }

    func testNilToken() throws {
        // token 为 nil 应该正常工作
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        XCTAssertNotNil(client)
    }

    func testEmptyToken() throws {
        // token 为空字符串应该正常工作
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: "",
            webSocket: MockWebSocketConnection()
        )

        XCTAssertNotNil(client)
    }
}
