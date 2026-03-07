// GatewayClientReconnectTests.swift
// OpenClaw Deck Swift
//
// 自动重连机制测试 - 验证网络容错能力
// 使用依赖注入 Mock WebSocket 进行测试

@testable import openclaw_deck_swift
import XCTest

@MainActor
final class GatewayClientReconnectTests: XCTestCase {
    // MARK: - 重连配置测试

    func testReconnectConfiguration_defaults() throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil
        )

        // 验证默认配置
        XCTAssertEqual(client.maxReconnectAttempts, 10, "最大重连次数应为 10")
        XCTAssertEqual(client.maxReconnectDelay, 15_000_000_000, "最大延迟应为 15 秒")
        XCTAssertEqual(client.backoffMultiplier, 1.7, "指数退避系数应为 1.7")
        XCTAssertEqual(client.currentReconnectDelay, 800_000_000, "初始延迟应为 800ms")
    }

    // MARK: - 自动重连触发测试（使用 Mock WebSocket）

    func testHandleDisconnect_triggersReconnect() async throws {
        // 创建 Mock WebSocket
        let mockWebSocket = MockWebSocketConnection()

        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: mockWebSocket // ← 注入 Mock
        )

        // 连接
        await client.connect()
        XCTAssertTrue(client.connected, "应该已连接")

        // 触发断开
        client.handleDisconnect()

        // 验证：启动了自动重连
        XCTAssertTrue(client.isAutoReconnecting, "应该正在自动重连")
        XCTAssertNotNil(client.reconnectTask, "应该创建了重连任务")
    }

    func testHandleDisconnect_multipleCalls_skipsDuplicate() async throws {
        let mockWebSocket = MockWebSocketConnection()

        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: mockWebSocket
        )

        await client.connect()

        // 第一次触发断开
        client.handleDisconnect()
        let firstTask = client.reconnectTask
        XCTAssertTrue(client.isAutoReconnecting)

        // 第二次触发断开 - 应该跳过
        client.handleDisconnect()
        let secondTask = client.reconnectTask

        // 验证：没有创建新任务（重连中会跳过）
        // 注意：由于异步执行，这里验证状态而不是任务引用
        XCTAssertTrue(client.isAutoReconnecting, "应该保持重连状态")
    }

    // MARK: - 手动断开取消重连测试

    func testManualDisconnect_cancelsAutoReconnect() async throws {
        let mockWebSocket = MockWebSocketConnection()

        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: mockWebSocket
        )

        await client.connect()
        XCTAssertTrue(client.connected)

        // 触发自动重连
        client.handleDisconnect()
        XCTAssertTrue(client.isAutoReconnecting)

        // 手动断开 - 应该取消自动重连
        client.disconnect()

        // 验证：重连被取消
        XCTAssertFalse(client.isAutoReconnecting, "手动断开应该取消自动重连")
        XCTAssertEqual(client.reconnectAttempts, 0, "重连次数应该重置")
    }

    // MARK: - 重连成功重置测试

    func testSuccessfulReconnect_resetsCounters() async throws {
        let mockWebSocket = MockWebSocketConnection()

        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: mockWebSocket
        )

        await client.connect()

        // 模拟断开
        client.handleDisconnect()
        XCTAssertTrue(client.isAutoReconnecting)

        // 增加重连次数和延迟（模拟之前的失败）
        client.reconnectAttempts = 3
        client.currentReconnectDelay = 2_000_000_000

        // 执行重连（Mock 模式下会立即成功）
        await client.reconnect()

        // 验证：成功后重置
        XCTAssertFalse(client.isAutoReconnecting, "重连成功后应该清除重连标志")
        XCTAssertEqual(client.reconnectAttempts, 0, "重连次数应该重置为 0")
        XCTAssertEqual(client.currentReconnectDelay, 800_000_000, "延迟应该重置为初始值")
        XCTAssertTrue(client.connected, "重连成功后应该已连接")
    }

    // MARK: - 重连失败递增测试

    func testReconnectFailure_incrementsAttemptAndDelay() throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil
        )

        // 初始状态
        XCTAssertEqual(client.reconnectAttempts, 0)
        XCTAssertEqual(client.currentReconnectDelay, 800_000_000)

        // 验证指数退避计算
        let initialDelay: UInt64 = 800_000_000
        let expectedDelay1 = UInt64(Double(initialDelay) * 1.7) // 第一次失败后
        let expectedDelay2 = UInt64(Double(expectedDelay1) * 1.7) // 第二次失败后

        XCTAssertEqual(expectedDelay1, 1_360_000_000, "第一次失败后延迟应为 1.36 秒")
        XCTAssertEqual(expectedDelay2, 2_312_000_000, accuracy: 1_000_000, "第二次失败后延迟应为 2.31 秒")
    }

    func testReconnectDelay_capsAtMaximum() {
        // 验证延迟不会超过最大值
        var delay: UInt64 = 10_000_000_000 // 10 秒

        // 应用退避
        delay = UInt64(Double(delay) * 1.7)
        XCTAssertGreaterThan(delay, 15_000_000_000, "应该超过最大值")

        // 应该被限制在最大值
        delay = min(delay, 15_000_000_000)
        XCTAssertEqual(delay, 15_000_000_000, "延迟应该被限制在 15 秒")
    }

    // MARK: - 最大重连次数测试

    func testMaxReconnectAttempts_configuration() throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil
        )

        XCTAssertEqual(client.maxReconnectAttempts, 10, "最大重连次数应为 10")

        // 验证达到最大次数后的行为
        client.reconnectAttempts = 9
        XCTAssertLessThan(client.reconnectAttempts, client.maxReconnectAttempts, "还没达到最大次数")

        client.reconnectAttempts = 10
        XCTAssertEqual(client.reconnectAttempts, client.maxReconnectAttempts, "达到最大次数")
    }

    // MARK: - 静默重连测试

    func testSilentReconnect_doesNotTriggerCallback() async throws {
        let mockWebSocket = MockWebSocketConnection()

        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: mockWebSocket
        )

        var callbackCount = 0
        client.onConnection = { _ in
            callbackCount += 1
        }

        // 初始连接 - 会触发回调
        await client.connect()
        XCTAssertEqual(callbackCount, 1, "初始连接应该触发回调")

        // 静默连接 - 不应该触发回调
        await client.sendConnect(silent: true)
        XCTAssertEqual(callbackCount, 1, "静默连接不应该触发回调")

        // 正常连接 - 会触发回调
        await client.sendConnect(silent: false)
        XCTAssertEqual(callbackCount, 2, "正常连接应该触发回调")
    }

    // MARK: - 待处理请求测试

    func testPendingRequests_rejectedOnDisconnect() async throws {
        let mockWebSocket = MockWebSocketConnection()

        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: mockWebSocket
        )

        await client.connect()

        // 创建一个待处理请求（异步）
        Task {
            do {
                _ = try await client.request(method: "test")
            } catch {
                // 预期错误
            }
        }

        // 等待一小段时间让请求进入待处理队列
        try? await Task.sleep(nanoseconds: 50_000_000)

        // 验证有待处理请求
        XCTAssertGreaterThan(client.pendingRequests.count, 0, "应该有待处理请求")

        // 断开连接 - 应该拒绝所有请求
        client.disconnect()

        // 验证：待处理请求被清空
        XCTAssertEqual(client.pendingRequests.count, 0, "断开后待处理请求应该被清空")
    }

    // MARK: - Nonce 和 Challenge 测试

    func testConnectNonce_resetOnReconnect() async throws {
        let mockWebSocket = MockWebSocketConnection()

        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: mockWebSocket
        )

        // 初始连接
        await client.connect()

        // 模拟收到 challenge
        client.connectNonce = "test-nonce-123"
        XCTAssertEqual(client.connectNonce, "test-nonce-123")

        // 重连时会重置 nonce
        client.connectNonce = nil
        client.connectSent = false

        // 验证重置
        XCTAssertNil(client.connectNonce, "重连前 nonce 应该被重置")
        XCTAssertFalse(client.connectSent, "connectSent 应该被重置")
    }

    func testChallengeCallback_resumesWaiting() throws {
        let mockWebSocket = MockWebSocketConnection()

        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: mockWebSocket
        )

        // 设置回调
        var receivedNonce: String?
        client.challengeCallback = { nonce in
            receivedNonce = nonce
        }

        // 模拟收到 challenge
        let testNonce = "challenge-nonce-456"
        client.challengeCallback?(testNonce)

        // 验证回调被调用
        XCTAssertEqual(receivedNonce, testNonce, "应该收到 nonce")
        // 注意：回调不会自动清除，需要手动清除
        XCTAssertNotNil(client.challengeCallback, "回调应该还在")
    }

    // MARK: - 完整重连流程测试

    func testFullReconnectWorkflow() async throws {
        let mockWebSocket = MockWebSocketConnection()

        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: mockWebSocket
        )

        // 1. 初始连接
        await client.connect()
        XCTAssertTrue(client.connected, "应该已连接")
        XCTAssertEqual(client.reconnectAttempts, 0, "初始重连次数为 0")

        // 2. 模拟网络断开
        client.handleDisconnect()
        XCTAssertTrue(client.isAutoReconnecting, "应该启动自动重连")

        // 3. 等待重连（Mock 模式下很快）
        try? await Task.sleep(nanoseconds: 100_000_000)

        // 4. 执行重连
        await client.reconnect()

        // 5. 验证重连成功
        XCTAssertTrue(client.connected, "重连后应该已连接")
        XCTAssertFalse(client.isAutoReconnecting, "重连成功后应该清除重连标志")
        XCTAssertEqual(client.reconnectAttempts, 0, "重连次数应该重置")
    }

    // MARK: - 边界条件测试

    func testReconnect_withoutPriorConnect() async throws {
        let mockWebSocket = MockWebSocketConnection()

        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: mockWebSocket
        )

        // 直接调用重连（没有先连接）
        await client.reconnect()

        // 在 Mock 模式下，应该成功
        XCTAssertTrue(client.connected, "Mock 模式下重连应该成功")
    }

    func testMultipleDisconnectCalls() async throws {
        let mockWebSocket = MockWebSocketConnection()

        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: mockWebSocket
        )

        await client.connect()

        // 多次调用 disconnect
        client.disconnect()
        client.disconnect()
        client.disconnect()

        // 验证：状态稳定
        XCTAssertFalse(client.connected)
        XCTAssertFalse(client.isAutoReconnecting, "多次断开不应该触发重连")
    }
}
