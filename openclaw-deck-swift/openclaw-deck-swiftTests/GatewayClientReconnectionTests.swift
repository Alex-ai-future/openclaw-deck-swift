// GatewayClientReconnectionTests.swift
// OpenClaw Deck Swift
//
// 重连机制测试 - 验证简化后的自动重连逻辑

@testable import openclaw_deck_swift
import XCTest

@MainActor
final class GatewayClientReconnectionTests: XCTestCase {
    var mockWebSocket: MockWebSocketConnection!
    var client: GatewayClient!

    override func setUp() async throws {
        try await super.setUp()
        mockWebSocket = MockWebSocketConnection()
        client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: mockWebSocket
        )
    }

    override func tearDown() async throws {
        client = nil
        mockWebSocket = nil
        try await super.tearDown()
    }

    // MARK: - 连接状态测试

    func testConnectionStatus_initialState() {
        // 初始状态：未连接
        XCTAssertEqual(client.connectionStatus, .disconnected, "初始状态应该是未连接")
    }

    func testConnectionStatus_connected() async {
        await client.connect()
        XCTAssertEqual(client.connectionStatus, .connected, "连接后应该是已连接")
    }

    func testConnectionStatus_connecting() {
        // 手动设置连接中状态
        client.isConnecting = true
        XCTAssertEqual(client.connectionStatus, .reconnecting, "连接中应该是重连状态")
    }

    func testConnectionStatus_disconnected() {
        client.connected = false
        client.isConnecting = false
        XCTAssertEqual(client.connectionStatus, .disconnected, "未连接应该是断开状态")
    }

    // MARK: - 手动断开测试

    func testManualDisconnect_doesNotAutoReconnect() async {
        await client.connect()
        XCTAssertTrue(client.connected, "应该已连接")

        var disconnectCallbackCalled = false
        client.onConnection = { connected in
            if !connected {
                disconnectCallbackCalled = true
            }
        }

        // 手动断开
        client.disconnect()

        // 验证：通知了 UI，但没有自动重连
        XCTAssertTrue(disconnectCallbackCalled, "应该通知 UI 断开")
        XCTAssertFalse(client.connected, "应该已断开")
        XCTAssertFalse(client.isConnecting, "不应该在连接中")
    }

    func testManualDisconnect_clearsState() async {
        await client.connect()

        // 添加一些待处理请求（使用 withCheckedContinuation 创建）
        // 注意：这里只是为了测试，实际不会使用这些请求
        let dummyContinuation: CheckedContinuation<GatewayResponse, Error> =
            await withCheckedContinuation { _ in }
        client.pendingRequests["test-id"] = PendingRequest(
            continuation: dummyContinuation,
            timeout: Task { try? await Task.sleep(nanoseconds: 1_000_000_000) }
        )

        // 手动断开
        client.disconnect()

        // 验证：状态被清除
        XCTAssertFalse(client.connected)
        XCTAssertFalse(client.isConnecting)
        XCTAssertTrue(client.pendingRequests.isEmpty, "待处理请求应该被清除")
    }

    // MARK: - 被动断开（自动重连）测试

    func testHandleDisconnect_triggersAutoReconnect() async {
        await client.connect()
        XCTAssertTrue(client.connected, "应该已连接")

        // 被动断开（网络问题）
        client.handleDisconnect()

        // 验证：进入连接中状态（显示橙色）
        XCTAssertTrue(client.isConnecting, "应该进入连接中状态")
        // ✅ connected 保持 true（用户期望保持连接）
        XCTAssertTrue(client.connected, "应该保持连接期望")
    }

    func testHandleDisconnect_preventsDuplicate() async {
        await client.connect()

        // 第一次触发断开
        client.handleDisconnect()
        let firstIsConnecting = client.isConnecting

        // 第二次触发断开（应该被忽略）
        client.handleDisconnect()

        // 验证：没有重复触发
        XCTAssertEqual(firstIsConnecting, client.isConnecting, "重复调用应该被忽略")
    }

    func testHandleDisconnect_reconnectsAfterDelay() async {
        await client.connect()
        XCTAssertTrue(client.connected, "初始应该已连接")

        // 被动断开
        client.handleDisconnect()
        // ✅ connected 保持 true（用户期望保持连接）
        XCTAssertTrue(client.connected, "应该保持连接期望")
        XCTAssertTrue(client.isConnecting, "应该在连接中")

        // 等待重连（handleDisconnect 内部有 1 秒延迟 + 连接时间）
        // Mock 模式下 connect() 会立即成功
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        // Mock 模式下重连会成功
        XCTAssertTrue(client.connected, "重连后应该已连接")
        XCTAssertFalse(client.isConnecting, "重连成功后应该不在连接中")
    }

    // MARK: - 重连回调测试

    func testReconnect_notifiesUIOnSuccess() async {
        var connectionCallbacks: [Bool] = []
        client.onConnection = { connected in
            connectionCallbacks.append(connected)
        }

        // 初始连接
        await client.connect()
        XCTAssertEqual(connectionCallbacks.count(where: { $0 }), 1, "初始连接应该触发回调")

        // 被动断开并重连
        client.handleDisconnect()

        // 等待重连
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        // 验证：重连成功触发回调
        XCTAssertEqual(connectionCallbacks.count(where: { $0 }), 2, "重连成功应该触发回调")
    }

    // MARK: - 边界条件测试

    func testReconnect_withoutPriorConnection() async {
        // 直接调用重连（没有先连接）
        client.handleDisconnect()

        // 等待重连
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        // Mock 模式下应该成功
        XCTAssertTrue(client.connected, "Mock 模式下重连应该成功")
    }

    func testMultipleDisconnectCalls() async {
        await client.connect()

        // 多次调用 disconnect
        client.disconnect()
        client.disconnect()
        client.disconnect()

        // 验证：状态稳定
        XCTAssertFalse(client.connected)
        XCTAssertFalse(client.isConnecting)
    }

    // MARK: - 状态流转测试

    func testStateTransition_connectedToDisconnected() async {
        await client.connect()
        XCTAssertEqual(client.connectionStatus, .connected, "初始：已连接 🟢")

        client.disconnect()
        XCTAssertEqual(client.connectionStatus, .disconnected, "手动断开：断开 🔴")
    }

    func testStateTransition_connectedToReconnecting() async {
        await client.connect()
        XCTAssertEqual(client.connectionStatus, .connected, "初始：已连接 🟢")

        client.handleDisconnect()
        XCTAssertEqual(client.connectionStatus, .reconnecting, "被动断开：重连中 🟠")
    }

    func testStateTransition_reconnectingToConnected() async {
        await client.connect()
        client.handleDisconnect()
        XCTAssertEqual(client.connectionStatus, .reconnecting, "重连中 🟠")

        // 等待重连
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        XCTAssertEqual(client.connectionStatus, .connected, "重连成功：已连接 🟢")
    }
}
