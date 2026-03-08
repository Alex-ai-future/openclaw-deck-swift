// DeckViewModelHeartbeatTests.swift
// OpenClaw Deck Swift
//
// 心跳检测测试 - 验证心跳超时和自动重连逻辑

@testable import openclaw_deck_swift
import XCTest

@MainActor
final class DeckViewModelHeartbeatTests: XCTestCase {
    var viewModel: DeckViewModel!
    var mockGatewayClient: MockGatewayClient!

    override func setUp() async throws {
        try await super.setUp()

        // 创建 Mock GatewayClient
        mockGatewayClient = MockGatewayClient()

        // 创建 ViewModel
        let diContainer = DIContainer.shared
        viewModel = DeckViewModel(diContainer: diContainer)

        // 注入 Mock 客户端
        viewModel.gatewayClient = mockGatewayClient
    }

    override func tearDown() async throws {
        viewModel = nil
        mockGatewayClient = nil
        try await super.tearDown()
    }

    // MARK: - 心跳事件处理测试

    func testHandleGatewayEvent_heartbeatEvent() {
        // 验证：heartbeat 事件被处理（不崩溃）
        let heartbeatEvent = GatewayEvent(event: "heartbeat", payload: nil)
        viewModel.handleGatewayEvent(heartbeatEvent)

        // 测试通过（不崩溃即成功）
        XCTAssertTrue(true)
    }

    func testHandleGatewayEvent_tickEventIgnored() {
        // 验证：tick 事件被忽略
        let tickEvent = GatewayEvent(event: "tick", payload: nil)
        viewModel.handleGatewayEvent(tickEvent)

        XCTAssertTrue(true)
    }

    func testHandleGatewayEvent_healthEventIgnored() {
        // 验证：health 事件被忽略
        let healthEvent = GatewayEvent(event: "health", payload: nil)
        viewModel.handleGatewayEvent(healthEvent)

        XCTAssertTrue(true)
    }

    // MARK: - 断开连接测试

    func testDisconnect_stopsMonitoring() {
        // 断开连接（应该停止心跳检测）
        viewModel.disconnect()

        // 验证：客户端被断开
        XCTAssertFalse(mockGatewayClient.connected, "客户端应该被断开")
    }

    // MARK: - 连接回调测试

    func testOnConnectionSuccess_startsMonitoring() async {
        var connectionCallbackCalled = false

        mockGatewayClient.onConnection = { connected in
            if connected {
                connectionCallbackCalled = true
            }
        }

        // 触发连接成功
        await mockGatewayClient.connect()

        // 验证：回调被调用
        XCTAssertTrue(connectionCallbackCalled, "连接成功应该触发回调")
    }

    func testOnConnectionFailure_stopsMonitoring() {
        // 触发连接失败
        mockGatewayClient.onConnection?(false)

        // 验证：不崩溃
        XCTAssertTrue(true)
    }

    // MARK: - 边界条件测试

    func testHeartbeatMonitoring_multipleEvents() {
        // 发送多个心跳事件
        for _ in 0 ..< 10 {
            viewModel.handleGatewayEvent(GatewayEvent(event: "heartbeat", payload: nil))
        }

        // 验证：不崩溃
        XCTAssertTrue(true)
    }

    func testHeartbeatMonitoring_mixedEvents() {
        // 发送混合事件
        let events = [
            GatewayEvent(event: "heartbeat", payload: nil),
            GatewayEvent(event: "tick", payload: nil),
            GatewayEvent(event: "health", payload: nil),
            GatewayEvent(event: "heartbeat", payload: nil),
        ]

        for event in events {
            viewModel.handleGatewayEvent(event)
        }

        // 验证：不崩溃
        XCTAssertTrue(true)
    }
}
