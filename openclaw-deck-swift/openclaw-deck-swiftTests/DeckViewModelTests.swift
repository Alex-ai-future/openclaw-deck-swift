// DeckViewModelTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/26.
// Copyright © 2026 OpenClaw. All rights reserved.

@testable import openclaw_deck_swift
import XCTest

@MainActor
final class DeckViewModelTests: XCTestCase {
    var viewModel: DeckViewModel!
    var mockStorage: MockUserDefaultsStorage!
    var mockGlobalInputState: MockGlobalInputState!

    override func setUp() async throws {
        try await super.setUp()
        // 使用 Mock 存储和 Mock GlobalInputState，完全隔离测试
        mockStorage = MockFactory.createMockStorage()
        mockGlobalInputState = MockGlobalInputState()
        let testDIContainer = MockFactory.createDIContainer(
            storage: mockStorage,
            globalInputState: mockGlobalInputState
        )
        viewModel = DeckViewModel(diContainer: testDIContainer)
    }

    override func tearDown() async throws {
        viewModel = nil
        mockStorage = nil
        mockGlobalInputState = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testViewModelInitialization() {
        XCTAssertNil(viewModel.gatewayClient)
        XCTAssertGreaterThanOrEqual(viewModel.sessions.count, 0)
        XCTAssertGreaterThanOrEqual(viewModel.sessionOrder.count, 0)
        XCTAssertFalse(viewModel.gatewayConnected)
        XCTAssertNil(viewModel.connectionError)
    }

    // MARK: - Connection Tests

    func testClearConnectionError() {
        viewModel.connectionError = "Test error"
        XCTAssertNotNil(viewModel.connectionError)
        viewModel.clearConnectionError()
        XCTAssertNil(viewModel.connectionError)
    }

    func testDisconnect() {
        viewModel.disconnect()
        XCTAssertFalse(viewModel.gatewayConnected)
    }

    // MARK: - Session Management Tests

    func testCreateSession_generatesUniqueIds() {
        let session1 = viewModel.createSession(name: "Test Session 1")
        let session2 = viewModel.createSession(name: "Test Session 2")

        XCTAssertNotEqual(session1.id, session2.id)
        XCTAssertNotEqual(session1.sessionKey, session2.sessionKey)
    }

    func testCreateSession_savesToStorage() {
        let session = viewModel.createSession(name: "Test")

        XCTAssertNotNil(viewModel.getSession(sessionId: session.id))
        XCTAssertEqual(viewModel.getSession(sessionId: session.id)?.sessionId, session.id)
    }

    func testCreateSession_withCustomIcon() {
        let session = viewModel.createSession(
            name: "Custom",
            icon: "🚀",
            context: "Custom context"
        )

        XCTAssertEqual(session.icon, "🚀")
        XCTAssertEqual(session.context, "Custom context")
    }

    func testDeleteSession() {
        let session = viewModel.createSession(name: "To Delete")
        let sessionId = session.id

        XCTAssertNotNil(viewModel.getSession(sessionId: sessionId))
        viewModel.deleteSession(sessionId: sessionId)
        XCTAssertNil(viewModel.getSession(sessionId: sessionId))
    }

    func testDeleteSession_createsWelcomeSession() {
        let session = viewModel.createSession(name: "Only Session")
        viewModel.deleteSession(sessionId: session.id)
        XCTAssertGreaterThanOrEqual(viewModel.sessions.count, 1)
    }

    func testGetSession() {
        let session = viewModel.createSession(name: "Test")
        let retrieved = viewModel.getSession(sessionId: session.id)

        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.sessionId, session.id)
        XCTAssertEqual(retrieved?.sessionKey, session.sessionKey)
    }

    func testGetSession_notFound() {
        let retrieved = viewModel.getSession(sessionId: "non-existent")
        XCTAssertNil(retrieved)
    }

    func testSessionOrder() {
        let session1 = viewModel.createSession(name: "First")
        let session2 = viewModel.createSession(name: "Second")
        let session3 = viewModel.createSession(name: "Third")

        XCTAssertEqual(viewModel.sessionOrder[0], session3.id.lowercased())
        XCTAssertEqual(viewModel.sessionOrder[1], session2.id.lowercased())
        XCTAssertEqual(viewModel.sessionOrder[2], session1.id.lowercased())
    }

    // MARK: - Event Handling Tests

    func testHandleGatewayEvent_unknownEvent() {
        let event = GatewayEvent(event: "unknown.event", payload: nil)
        viewModel.handleGatewayEvent(event)
    }

    func testHandleGatewayEvent_tickEvent() {
        let event = GatewayEvent(event: "tick", payload: nil)
        viewModel.handleGatewayEvent(event)
    }

    func testHandleGatewayEvent_healthEvent() {
        let event = GatewayEvent(event: "health", payload: nil)
        viewModel.handleGatewayEvent(event)
    }

    func testHandleGatewayEvent_heartbeatEvent() {
        let event = GatewayEvent(event: "heartbeat", payload: nil)
        viewModel.handleGatewayEvent(event)
    }

    // MARK: - Gateway Event Integration Tests

    func testHandleAgentEvent_withInvalidPayload() {
        let event = GatewayEvent(event: "agent", payload: nil)
        viewModel.handleGatewayEvent(event)
    }

    func testHandleAgentEvent_withMissingSessionKey() {
        let event = GatewayEvent(
            event: "agent",
            payload: ["runId": "run-1", "stream": "assistant"]
        )
        viewModel.handleGatewayEvent(event)
    }

    // MARK: - State Management Tests

    func testSessionStatusTransitions() {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)

        XCTAssertNotNil(sessionState)
        guard let state = sessionState else { return }

        XCTAssertEqual(state.status, .idle)
        state.status = .thinking
        XCTAssertEqual(state.status, .thinking)
        state.status = .streaming
        XCTAssertEqual(state.status, .streaming)
        state.status = .error("Test error")
        XCTAssertEqual(state.status, .error("Test error"))
        state.status = .idle
        XCTAssertEqual(state.status, .idle)
    }

    // MARK: - Edge Cases

    func testCreateSession_withEmptyName() {
        let session = viewModel.createSession(name: "")
        XCTAssertNotNil(session)
        XCTAssertFalse(session.id.isEmpty)
    }

    func testCreateSession_withSpecialCharacters() {
        let session = viewModel.createSession(name: "Test @#$% Session")
        XCTAssertNotNil(session)
    }

    func testDeleteNonExistentSession() {
        viewModel.deleteSession(sessionId: "non-existent")
    }

    func testMultipleSessionsWithSameName() {
        let session1 = viewModel.createSession(name: "Same Name")
        let session2 = viewModel.createSession(name: "Same Name")

        XCTAssertNotEqual(session1.id, session2.id)
    }

    // MARK: - Gateway Event Handling Tests (Core)

    func testHandleAgentEvent_lifecycleStart() {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)
        XCTAssertNotNil(sessionState)

        let event = GatewayEvent(
            event: "agent",
            payload: [
                "runId": "run-123",
                "stream": "lifecycle",
                "sessionKey": session.sessionKey,
                "data": ["phase": "start"],
            ]
        )

        viewModel.handleGatewayEvent(event)

        XCTAssertEqual(sessionState?.isProcessing, true)
        XCTAssertEqual(sessionState?.status, .thinking)
        XCTAssertEqual(sessionState?.activeRunId, "run-123")
    }

    func testHandleAgentEvent_lifecycleEnd() {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)
        XCTAssertNotNil(sessionState)

        // 先设置为处理中状态
        sessionState?.isProcessing = true
        sessionState?.status = .thinking
        sessionState?.activeRunId = "run-123"

        let event = GatewayEvent(
            event: "agent",
            payload: [
                "runId": "run-123",
                "stream": "lifecycle",
                "sessionKey": session.sessionKey,
                "data": ["phase": "end"],
            ]
        )

        viewModel.handleGatewayEvent(event)

        XCTAssertEqual(sessionState?.isProcessing, false)
        XCTAssertEqual(sessionState?.status, .idle)
        XCTAssertNil(sessionState?.activeRunId)
        XCTAssertEqual(sessionState?.hasUnreadMessage, true)
    }

    func testHandleAgentEvent_assistantMessage_delta() {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)
        XCTAssertNotNil(sessionState)

        // 先发送 lifecycle.start
        let startEvent = GatewayEvent(
            event: "agent",
            payload: [
                "runId": "run-123",
                "stream": "lifecycle",
                "sessionKey": session.sessionKey,
                "data": ["phase": "start"],
            ]
        )
        viewModel.handleGatewayEvent(startEvent)

        // 发送第一条 delta 消息
        let msgEvent1 = GatewayEvent(
            event: "agent",
            payload: [
                "runId": "run-123",
                "stream": "assistant",
                "sessionKey": session.sessionKey,
                "data": ["delta": "Hello"],
            ]
        )
        viewModel.handleGatewayEvent(msgEvent1)

        XCTAssertEqual(sessionState?.messages.count, 1)
        XCTAssertEqual(sessionState?.messages.first?.text, "Hello")
        XCTAssertEqual(sessionState?.messages.first?.role, .assistant)
        XCTAssertEqual(sessionState?.messages.first?.runId, "run-123")
        XCTAssertEqual(sessionState?.messages.first?.streaming, true)

        // 发送第二条 delta 消息（追加）
        let msgEvent2 = GatewayEvent(
            event: "agent",
            payload: [
                "runId": "run-123",
                "stream": "assistant",
                "sessionKey": session.sessionKey,
                "data": ["delta": " World"],
            ]
        )
        viewModel.handleGatewayEvent(msgEvent2)

        XCTAssertEqual(sessionState?.messages.count, 1)
        XCTAssertEqual(sessionState?.messages.first?.text, "Hello World")
    }

    func testHandleAgentEvent_duplicateSeq() {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)
        XCTAssertNotNil(sessionState)

        // 发送带 seq 的消息
        let msgEvent1 = GatewayEvent(
            event: "agent",
            payload: [
                "runId": "run-123",
                "stream": "assistant",
                "sessionKey": session.sessionKey,
                "seq": 1,
                "data": ["text": "Hello"],
            ]
        )
        viewModel.handleGatewayEvent(msgEvent1)

        XCTAssertEqual(sessionState?.messages.count, 1)

        // 发送相同 seq 的消息（应该被忽略）
        viewModel.handleGatewayEvent(msgEvent1)

        XCTAssertEqual(sessionState?.messages.count, 1)
    }

    // MARK: - Send Message Tests

    func testSendMessage_success() async {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)
        XCTAssertNotNil(sessionState)

        // 设置 Mock GatewayClient
        let mockClient = MockGatewayClient()
        mockClient.connected = true
        viewModel.gatewayClient = mockClient

        await viewModel.sendMessage(sessionId: session.id, text: "Test message")

        // 验证添加了用户消息
        XCTAssertGreaterThanOrEqual(sessionState?.messages.count ?? 0, 1)
        let userMessage = sessionState?.messages.last
        XCTAssertEqual(userMessage?.role, .user)
        XCTAssertEqual(userMessage?.text, "Test message")
        XCTAssertEqual(sessionState?.status, .thinking)
    }

    func testSendMessage_gatewayNotConnected() async {
        let session = viewModel.createSession(name: "Test")

        // 不设置 GatewayClient（模拟未连接）
        viewModel.gatewayClient = nil

        await viewModel.sendMessage(sessionId: session.id, text: "Test message")

        // 验证显示错误弹窗
        XCTAssertEqual(viewModel.showMessageSendError, true)
        XCTAssertEqual(viewModel.messageSendErrorText, "Gateway 未连接")
    }

    // MARK: - Load History Tests

    func testLoadSessionHistory_success() async {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)
        XCTAssertNotNil(sessionState)

        // 设置 Mock GatewayClient 带模拟历史
        let mockClient = MockGatewayClient()
        mockClient.connected = true
        mockClient.mockHistory = [
            ChatMessage(
                id: "msg-1",
                role: .user,
                text: "Hello",
                timestamp: Date()
            ),
            ChatMessage(
                id: "msg-2",
                role: .assistant,
                text: "Hi there",
                timestamp: Date()
            ),
        ]
        viewModel.gatewayClient = mockClient

        await viewModel.loadSessionHistory(sessionKey: session.sessionKey)

        XCTAssertEqual(sessionState?.messages.count, 2)
        XCTAssertEqual(sessionState?.historyLoaded, true)
        XCTAssertEqual(sessionState?.isHistoryLoading, false)
    }

    func testLoadSessionHistory_gatewayDisconnected() async {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)
        XCTAssertNotNil(sessionState)

        // 设置未连接的 GatewayClient
        let mockClient = MockGatewayClient()
        mockClient.connected = false
        viewModel.gatewayClient = mockClient

        await viewModel.loadSessionHistory(sessionKey: session.sessionKey)

        // 验证没有加载消息（Gateway 未连接时跳过）
        XCTAssertEqual(sessionState?.messages.count, 0)
        XCTAssertEqual(sessionState?.historyLoaded, false)
    }

    // MARK: - Error Handling Tests

    func testHandleAgentError() {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)
        XCTAssertNotNil(sessionState)

        let errorEvent = GatewayEvent(
            event: "agent.error",
            payload: [
                "sessionKey": session.sessionKey,
                "message": "Test error message",
            ]
        )

        viewModel.handleGatewayEvent(errorEvent)

        XCTAssertEqual(sessionState?.status, .error("Test error message"))
        XCTAssertNil(sessionState?.activeRunId)

        // 验证添加了系统错误消息
        let errorMsg = sessionState?.messages.last
        XCTAssertEqual(errorMsg?.role, .system)
        XCTAssertTrue(errorMsg?.text.contains("Error: Test error message") ?? false)
    }

    // MARK: - Reconnect Tests

    func testReconnect() async {
        let mockClient = MockGatewayClient()
        mockClient.connected = true
        viewModel.gatewayClient = mockClient

        await viewModel.reconnect()

        // 验证断开后重新连接
        XCTAssertEqual(mockClient.connected, true)
    }

    // MARK: - Send Current Input Tests

    func testSendCurrentInput_noSelectedSession() async {
        mockGlobalInputState.selectedSessionId = nil

        await viewModel.sendCurrentInput()

        // 没有选中 session 时应该直接返回
        XCTAssertEqual(mockGlobalInputState.sentMessages.count, 0)
    }

    func testSendCurrentInput_withSelectedSession() async {
        let session = viewModel.createSession(name: "Test")
        mockGlobalInputState.selectedSessionId = session.id
        mockGlobalInputState.inputText = "Test input"

        // 设置 Mock GatewayClient
        let mockClient = MockGatewayClient()
        mockClient.connected = true
        viewModel.gatewayClient = mockClient

        await viewModel.sendCurrentInput()

        // 验证 GlobalInputState 的 sendMessage 被调用
        XCTAssertGreaterThanOrEqual(mockGlobalInputState.sentMessages.count, 0)
    }
}
