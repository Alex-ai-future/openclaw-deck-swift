// GatewayClientConnectionStatusTests.swift
// OpenClaw Deck Swift
//
// 连接状态动态测试 - 验证 connectionStatus 在网络状态变化时的正确性

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
            urlSession: .shared,
            webSocket: mockWebSocket
        )
    }

    override func tearDown() async throws {
        client = nil
        mockWebSocket = nil
        try await super.tearDown()
    }

    // MARK: - 完整连接生命周期测试

    /// 测试完整的连接生命周期：未连接 → 连接成功 → 模拟断网 → 自动重连 → 重连成功
    func testConnectionStatus_Lifecycle() async throws {
        print("\n========================================")
        print("🧪 开始完整生命周期测试")
        print("========================================")

        // ========== 1. 初始状态：未连接 ==========
        print("\n1️⃣ 初始状态检查...")
        XCTAssertEqual(
            client.connectionStatus, .disconnected,
            "初始状态应该是未连接"
        )
        XCTAssertEqual(client.connectionStatus.color, Color.red, "初始状态颜色应该是红色")
        XCTAssertEqual(
            client.connectionStatus.iconName, "xmark.circle.fill",
            "初始状态图标应该是 xmark"
        )
        print("   ✅ 初始状态正确：.disconnected (🔴)")

        // ========== 2. 连接成功 ==========
        print("\n2️⃣ 开始连接...")
        client.connected = true
        client.connectionError = nil
        client.isAutoReconnecting = false

        // 等待状态更新
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        print("   检查连接后状态...")
        XCTAssertEqual(
            client.connectionStatus, .connected,
            "连接后应该是已连接状态"
        )
        XCTAssertEqual(client.connectionStatus.color, Color.green, "已连接颜色应该是绿色")
        XCTAssertEqual(
            client.connectionStatus.iconName, "checkmark.circle.fill",
            "已连接图标应该是 checkmark"
        )
        print("   ✅ 连接成功：.connected (🟢)")

        // ========== 3. 模拟断网（有错误） ==========
        print("\n3️⃣ 模拟网络断开...")
        client.connected = false
        client.connectionError = "network_error"
        client.isAutoReconnecting = false // 还没开始重连

        try await Task.sleep(nanoseconds: 100_000_000)

        print("   检查断开后状态...")
        XCTAssertEqual(
            client.connectionStatus, .disconnected,
            "断开后应该是未连接状态"
        )
        XCTAssertEqual(client.connectionStatus.color, Color.red, "断开颜色应该是红色")
        XCTAssertEqual(
            client.connectionStatus.iconName, "xmark.circle.fill",
            "断开图标应该是 xmark"
        )
        print("   ✅ 网络断开：.disconnected (🔴)")

        // ========== 4. 开始自动重连 ==========
        print("\n4️⃣ 开始自动重连...")
        client.isAutoReconnecting = true // 启动重连

        try await Task.sleep(nanoseconds: 100_000_000)

        print("   检查重连中状态...")
        XCTAssertEqual(
            client.connectionStatus, .reconnecting,
            "重连中应该是重连状态"
        )
        XCTAssertEqual(client.connectionStatus.color, Color.orange, "重连颜色应该是橙色")
        XCTAssertEqual(
            client.connectionStatus.iconName, "arrow.clockwise",
            "重连图标应该是 arrow.clockwise"
        )
        print("   ✅ 重连中：.reconnecting (🟠)")

        // ========== 5. 重连成功 ==========
        print("\n5️⃣ 重连成功...")
        client.connected = true
        client.connectionError = nil
        client.isAutoReconnecting = false

        try await Task.sleep(nanoseconds: 100_000_000)

        print("   检查重连成功后状态...")
        XCTAssertEqual(
            client.connectionStatus, .connected,
            "重连成功后应该是已连接状态"
        )
        XCTAssertEqual(client.connectionStatus.color, Color.green, "重连成功颜色应该是绿色")
        XCTAssertEqual(
            client.connectionStatus.iconName, "checkmark.circle.fill",
            "重连成功图标应该是 checkmark"
        )
        print("   ✅ 重连成功：.connected (🟢)")

        print("\n========================================")
        print("✅ 完整生命周期测试通过！")
        print("状态变化：🔴 → 🟢 → 🔴 → 🟠 → 🟢")
        print("========================================\n")
    }

    // MARK: - 边界条件测试

    /// 测试重连中但错误被清除的边缘情况
    func testConnectionStatus_ErrorClearedDuringReconnect() {
        print("\n🧪 测试：重连中但错误被清除")

        // 重连中但错误被清除（边缘情况）
        client.connected = false
        client.connectionError = nil // 错误已清除
        client.isAutoReconnecting = true

        // 根据优先级：isAutoReconnecting > connectionError
        XCTAssertEqual(
            client.connectionStatus, .reconnecting,
            "重连中优先级高于无错误状态"
        )
        XCTAssertEqual(client.connectionStatus.color, Color.orange)
        print("   ✅ 重连中优先级正确")
    }

    /// 测试已连接但有错误的不一致状态
    func testConnectionStatus_ConnectedButHasError() {
        print("\n🧪 测试：已连接但有错误（不一致状态）")

        // 已连接但有错误（理论上不应该发生，但要测试）
        client.connected = true
        client.connectionError = "some_error"
        client.isAutoReconnecting = false

        // 根据逻辑：connected && connectionError == nil 才是 .connected
        // 所以这种情况应该是 .disconnected
        XCTAssertEqual(
            client.connectionStatus, .disconnected,
            "有错误时即使 connected=true 也应该是断开状态"
        )
        XCTAssertEqual(client.connectionStatus.color, Color.red)
        print("   ✅ 错误优先级正确")
    }

    /// 测试初始无错误但未连接的状态
    func testConnectionStatus_InitialStateNoError() {
        print("\n🧪 测试：初始无错误但未连接")

        client.connected = false
        client.connectionError = nil
        client.isAutoReconnecting = false

        XCTAssertEqual(
            client.connectionStatus, .disconnected,
            "未连接且无错误应该是断开状态"
        )
        XCTAssertEqual(client.connectionStatus.color, Color.red)
        print("   ✅ 初始状态正确")
    }

    /// 测试重连失败后达到最大重试次数
    func testConnectionStatus_MaxRetriesReached() {
        print("\n🧪 测试：重连失败达到最大次数")

        client.connected = false
        client.connectionError = "max_retries_reached"
        client.isAutoReconnecting = false // 达到最大次数后停止重连

        XCTAssertEqual(
            client.connectionStatus, .disconnected,
            "达到最大重试次数后应该是断开状态"
        )
        XCTAssertEqual(client.connectionStatus.color, Color.red)
        print("   ✅ 最大重试次数状态正确")
    }

    // MARK: - 状态转换测试

    /// 测试从断开到重连的状态转换
    func testConnectionStatus_TransitionFromDisconnectedToReconnecting() {
        print("\n🧪 测试：从断开到重连的状态转换")

        // 初始断开
        client.connected = false
        client.connectionError = "timeout"
        client.isAutoReconnecting = false
        XCTAssertEqual(client.connectionStatus, .disconnected)

        // 启动重连
        client.isAutoReconnecting = true
        XCTAssertEqual(client.connectionStatus, .reconnecting)

        print("   ✅ 状态转换正确：.disconnected → .reconnecting")
    }

    /// 测试从重连到成功的状态转换
    func testConnectionStatus_TransitionFromReconnectingToConnected() {
        print("\n🧪 测试：从重连到成功的状态转换")

        // 重连中
        client.connected = false
        client.connectionError = "timeout"
        client.isAutoReconnecting = true
        XCTAssertEqual(client.connectionStatus, .reconnecting)

        // 重连成功
        client.connected = true
        client.connectionError = nil
        client.isAutoReconnecting = false
        XCTAssertEqual(client.connectionStatus, .connected)

        print("   ✅ 状态转换正确：.reconnecting → .connected")
    }
}
