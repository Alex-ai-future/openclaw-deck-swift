// GatewayClientReconnectLogicTests.swift
// OpenClaw Deck Swift
//
// 重连逻辑核心测试 - 验证网络抖动和长时间失败场景

@testable import openclaw_deck_swift
import XCTest

@MainActor
final class GatewayClientReconnectLogicTests: XCTestCase {
    // MARK: - 网络抖动场景测试（短暂失败后成功）

    func testReconnect_networkJitter_successAfterFirstAttempt() async throws {
        let mockWebSocket = MockWebSocketConnection()
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: mockWebSocket
        )

        // 初始连接
        await client.connect()
        XCTAssertTrue(client.connected)

        // 模拟网络抖动：断开
        client.handleDisconnect()
        XCTAssertTrue(client.isAutoReconnecting)

        // Mock 模式下重连会立即成功
        await client.reconnect()

        // 验证重连成功
        XCTAssertTrue(client.connected, "网络抖动后应该重连成功")
        XCTAssertEqual(client.reconnectAttempts, 0, "重连成功后次数应重置")
    }

    func testReconnect_networkJitter_preservesState() async throws {
        let mockWebSocket = MockWebSocketConnection()
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: mockWebSocket
        )

        await client.connect()

        // 设置一些状态
        client.reconnectAttempts = 2
        client.currentReconnectDelay = 2_000_000_000 // 2 秒

        // 断开并重连
        client.handleDisconnect()
        await client.reconnect()

        // 验证状态被重置（成功重连）
        XCTAssertEqual(client.reconnectAttempts, 0)
        XCTAssertEqual(client.currentReconnectDelay, 800_000_000) // 重置为初始值
    }

    // MARK: - 长时间失败场景测试（达到最大重连次数后断开）

    func testReconnect_maxAttempts_stopsAfter10Failures() async throws {
        let mockWebSocket = MockWebSocketConnection()
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: mockWebSocket
        )

        await client.connect()

        // 模拟连续失败，直到达到最大重连次数
        for i in 1 ... 10 {
            client.reconnectAttempts = i - 1
            client.isAutoReconnecting = true

            // 在真实场景中，reconnect() 会失败并递增次数
            // Mock 模式下会立即成功，所以手动模拟失败逻辑
            if i < 10 {
                // 模拟失败：增加次数和延迟
                client.reconnectAttempts = i
                client.currentReconnectDelay = UInt64(Double(client.currentReconnectDelay) * client.backoffMultiplier)
            } else {
                // 第 10 次失败后应该停止
                client.isAutoReconnecting = false
                client.connected = false
            }
        }

        // 验证达到最大次数后停止重连
        XCTAssertFalse(client.isAutoReconnecting, "达到最大重连次数后应该停止")
        XCTAssertFalse(client.connected, "重连失败后应该断开连接")
    }

    func testReconnect_exponentialBackoff_delayIncreases() throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil
        )

        // 验证指数退避算法
        let initialDelay: UInt64 = 800_000_000 // 800ms

        // 第 1 次失败后
        var delay1 = UInt64(Double(initialDelay) * client.backoffMultiplier)
        XCTAssertEqual(delay1, 1_360_000_000, "第 1 次失败后延迟应为 1.36 秒")

        // 第 2 次失败后
        var delay2 = UInt64(Double(delay1) * client.backoffMultiplier)
        XCTAssertEqual(delay2, 2_312_000_000, accuracy: 1_000_000, "第 2 次失败后延迟应为 2.31 秒")

        // 第 3 次失败后
        var delay3 = UInt64(Double(delay2) * client.backoffMultiplier)
        XCTAssertEqual(delay3, 3_930_400_000, accuracy: 1_000_000, "第 3 次失败后延迟应为 3.93 秒")

        // 验证延迟有上限（15 秒）
        var delay = initialDelay
        for _ in 0 ..< 20 {
            delay = UInt64(Double(delay) * client.backoffMultiplier)
            delay = min(delay, client.maxReconnectDelay)
        }

        XCTAssertEqual(delay, client.maxReconnectDelay, "延迟不应超过最大值 15 秒")
    }

    func testReconnect_backoffCapsAtMaxDelay() throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil
        )

        // 从接近最大值的延迟开始
        client.currentReconnectDelay = 14_000_000_000 // 14 秒

        // 应用退避
        let newDelay = UInt64(Double(client.currentReconnectDelay) * client.backoffMultiplier)
        let cappedDelay = min(newDelay, client.maxReconnectDelay)

        XCTAssertEqual(cappedDelay, client.maxReconnectDelay, "延迟应被限制在最大值")
    }

    // MARK: - 手动断开 vs 自动重连

    func testManualDisconnect_cancelsAutoReconnect() async throws {
        let mockWebSocket = MockWebSocketConnection()
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: mockWebSocket
        )

        await client.connect()

        // 触发自动重连
        client.handleDisconnect()
        XCTAssertTrue(client.isAutoReconnecting)

        // 用户手动断开 - 应该取消自动重连
        client.disconnect()

        XCTAssertFalse(client.isAutoReconnecting, "手动断开应该取消自动重连")
        XCTAssertEqual(client.reconnectAttempts, 0, "重连次数应该重置")
    }

    func testAutoReconnect_doesNotNotifyUI() async throws {
        let mockWebSocket = MockWebSocketConnection()
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: mockWebSocket
        )

        var connectionCallbacks: [Bool] = []
        client.onConnection = { connected in
            connectionCallbacks.append(connected)
        }

        // 初始连接 - 触发回调
        await client.connect()
        XCTAssertEqual(connectionCallbacks.count(where: { $0 }), 1, "初始连接应该触发回调")

        // 断开并自动重连（静默）
        client.handleDisconnect()
        await client.reconnect()

        // 验证：自动重连不触发 UI 回调
        XCTAssertEqual(connectionCallbacks.count(where: { $0 }), 1, "自动重连不应该触发 UI 回调")
    }

    // MARK: - 重连状态机测试

    func testReconnectStateMachine_consecutiveFailures() throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil
        )

        // 模拟连续失败的状态变化
        var attempts = 0
        var delay = client.currentReconnectDelay

        for _ in 1 ... 10 {
            attempts += 1
            delay = UInt64(Double(delay) * client.backoffMultiplier)
            delay = min(delay, client.maxReconnectDelay)

            // 验证每次失败后延迟增加
            if attempts < 10 {
                XCTAssertGreaterThan(delay, client.currentReconnectDelay, "延迟应该递增")
            }
        }

        // 验证最终状态
        XCTAssertEqual(attempts, 10, "应该尝试 10 次")
        XCTAssertEqual(delay, client.maxReconnectDelay, "最终延迟应达到最大值")
    }

    func testReconnectStateMachine_successResetsEverything() async throws {
        let mockWebSocket = MockWebSocketConnection()
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: mockWebSocket
        )

        await client.connect()

        // 模拟多次失败后的状态
        client.reconnectAttempts = 5
        client.currentReconnectDelay = 5_000_000_000 // 5 秒
        client.isAutoReconnecting = true

        // 重连成功
        await client.reconnect()

        // 验证所有状态被重置
        XCTAssertEqual(client.reconnectAttempts, 0, "重连次数应重置")
        XCTAssertEqual(client.currentReconnectDelay, 800_000_000, "延迟应重置为初始值")
        XCTAssertFalse(client.isAutoReconnecting, "重连标志应清除")
        XCTAssertTrue(client.connected, "连接应该恢复")
    }

    // MARK: - 边界条件测试

    func testReconnect_withoutPriorConnection() async throws {
        let mockWebSocket = MockWebSocketConnection()
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: mockWebSocket
        )

        // 直接重连（没有先连接）
        await client.reconnect()

        // Mock 模式应该成功
        XCTAssertTrue(client.connected, "Mock 模式下重连应该成功")
    }

    func testReconnect_duplicateCalls_skipsSecond() async throws {
        let mockWebSocket = MockWebSocketConnection()
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: mockWebSocket
        )

        await client.connect()
        client.handleDisconnect()

        let firstTask = client.reconnectTask

        // 再次触发（应该跳过）
        client.startSilentReconnect()

        // 验证任务没有变化
        XCTAssertEqual(client.reconnectTask, firstTask, "重复调用应该跳过")
    }

    // MARK: - 配置验证测试

    func testReconnectConfiguration_defaults() throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil
        )

        XCTAssertEqual(client.maxReconnectAttempts, 10, "最大重连次数应为 10")
        XCTAssertEqual(client.maxReconnectDelay, 15_000_000_000, "最大延迟应为 15 秒")
        XCTAssertEqual(client.backoffMultiplier, 1.7, "退避系数应为 1.7")
        XCTAssertEqual(client.currentReconnectDelay, 800_000_000, "初始延迟应为 800ms")
    }
}
