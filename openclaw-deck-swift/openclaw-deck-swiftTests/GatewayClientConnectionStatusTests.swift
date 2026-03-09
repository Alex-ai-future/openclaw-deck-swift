// GatewayClientConnectionStatusTests.swift
// OpenClaw Deck Swift
//
// 连接状态测试 - 验证简化后的 connectionStatus 逻辑

@testable import openclaw_deck_swift
import SwiftUI
import XCTest

@MainActor
final class GatewayClientConnectionStatusTests: XCTestCase {
    var client: GatewayClient!
    var mockWebSocket: MockWebSocketConnection!

    override func setUp() async throws {
        try await super.setUp()
        mockWebSocket = MockWebSocketConnection()
        client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:18789")),
            token: nil,
            webSocket: mockWebSocket
        )
    }

    override func tearDown() async throws {
        client = nil
        mockWebSocket = nil
        try await super.tearDown()
    }

    // MARK: - 基本状态测试

    func testConnectionStatus_initialState() {
        XCTAssertEqual(client.connectionStatus, .disconnected, "初始状态应该是未连接")
        XCTAssertEqual(client.connectionStatus.color, Color.red, "初始状态颜色应该是红色")
        XCTAssertEqual(client.connectionStatus.iconName, "xmark.circle.fill", "初始状态图标应该是 xmark")
    }

    func testConnectionStatus_connected() async {
        // Mock WebSocket 会立即返回成功
        await client.connect()
        // 给一点时间让状态更新
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        XCTAssertEqual(client.connectionStatus, .connected, "连接后应该是已连接")
        XCTAssertEqual(client.connectionStatus.color, Color.green, "已连接颜色应该是绿色")
        XCTAssertEqual(client.connectionStatus.iconName, "checkmark.circle.fill", "已连接图标应该是 checkmark")
    }

    func testConnectionStatus_connecting() {
        client.isConnecting = true
        XCTAssertEqual(client.connectionStatus, .reconnecting, "连接中应该是重连状态")
        XCTAssertEqual(client.connectionStatus.color, Color.orange, "连接中颜色应该是橙色")
        XCTAssertEqual(client.connectionStatus.iconName, "arrow.clockwise", "连接中图标应该是 arrow")
    }

    func testConnectionStatus_disconnected() {
        client.connected = false
        client.isConnecting = false
        XCTAssertEqual(client.connectionStatus, .disconnected, "未连接应该是断开状态")
        XCTAssertEqual(client.connectionStatus.color, Color.red, "断开颜色应该是红色")
    }

    // MARK: - 状态优先级测试

    func testConnectionStatus_connectedTakesPriority() {
        // 已连接时，isConnecting 应该被忽略
        client.connected = true
        client.isConnecting = false
        XCTAssertEqual(client.connectionStatus, .connected, "已连接优先级最高")
    }

    func testConnectionStatus_connectingWhenDisconnected() {
        // 未连接但正在连接
        client.connected = false
        client.isConnecting = true
        XCTAssertEqual(client.connectionStatus, .reconnecting, "连接中显示橙色")
    }

    func testConnectionStatus_disconnectedWhenNeither() {
        // 既未连接也不在连接中
        client.connected = false
        client.isConnecting = false
        XCTAssertEqual(client.connectionStatus, .disconnected, "未连接显示红色")
    }

    // MARK: - 完整生命周期测试

    func testConnectionStatus_lifecycle() async {
        // 1. 初始状态：未连接
        XCTAssertEqual(client.connectionStatus, .disconnected, "🔴 初始：未连接")

        // 2. 开始连接
        client.isConnecting = true
        XCTAssertEqual(client.connectionStatus, .reconnecting, "🟠 连接中")

        // 3. 连接成功
        await client.connect()
        try? await Task.sleep(nanoseconds: 100_000_000) // 给一点时间让状态更新
        XCTAssertEqual(client.connectionStatus, .connected, "🟢 已连接")

        // 4. 手动断开
        client.disconnect()
        XCTAssertEqual(client.connectionStatus, .disconnected, "🔴 手动断开")
    }

    func testConnectionStatus_autoReconnectLifecycle() async {
        // 1. 初始连接
        await client.connect()
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(client.connectionStatus, .connected, "🟢 已连接")

        // 2. 被动断开（触发自动重连）
        client.handleDisconnect()
        XCTAssertEqual(client.connectionStatus, .reconnecting, "🟠 重连中")

        // 3. 等待重连成功（Mock 会立即成功）
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        XCTAssertEqual(client.connectionStatus, .connected, "🟢 重连成功")
    }

    // MARK: - 边界条件测试

    func testConnectionStatus_multipleStateChanges() async {
        // 快速切换状态
        await client.connect()
        try? await Task.sleep(nanoseconds: 100_000_000)
        client.disconnect()
        client.handleDisconnect()

        // 应该在重连中
        XCTAssertEqual(client.connectionStatus, .reconnecting, "应该在重连中")
    }

    func testConnectionStatus_disconnectDuringReconnecting() {
        // 开始重连
        client.handleDisconnect()
        XCTAssertEqual(client.connectionStatus, .reconnecting, "🟠 重连中")

        // 用户手动断开（取消重连）
        client.disconnect()
        XCTAssertEqual(client.connectionStatus, .disconnected, "🔴 手动断开")
    }
}
