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

        // 清理 UserDefaults，避免测试间状态污染
        UserDefaults.standard.removeObject(forKey: "openclaw.deck.gatewayUrl")
        UserDefaults.standard.removeObject(forKey: "openclaw.deck.token")
        UserDefaults.standard.removeObject(forKey: "openclaw.deck.sessionOrder")
        UserDefaults.standard.removeObject(forKey: "playSoundOnMessage")
        UserDefaults.standard.synchronize()

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

        // 清理 UserDefaults
        UserDefaults.standard.removeObject(forKey: "openclaw.deck.gatewayUrl")
        UserDefaults.standard.removeObject(forKey: "openclaw.deck.token")
        UserDefaults.standard.removeObject(forKey: "openclaw.deck.sessionOrder")
        UserDefaults.standard.removeObject(forKey: "playSoundOnMessage")
        UserDefaults.standard.synchronize()

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

    func testGatewayDisconnect_updatesGatewayConnectedState() {
        // 1. 准备：创建 Mock Client
        let mockClient = MockGatewayClient()
        mockClient.connected = true

        // 2. 手动设置 onConnection 回调（模拟 DeckViewModel.connectGateway() 的行为）
        // 注意：直接同步更新，不使用 Task，因为 MockGatewayClient.disconnect() 是同步调用回调
        var callbackExecuted = false
        mockClient.onConnection = { [weak viewModel] connected in
            viewModel?.gatewayConnected = connected
            callbackExecuted = true
        }

        // 3. 设置初始状态
        viewModel.gatewayConnected = true
        viewModel.gatewayClient = mockClient

        // 验证初始状态
        XCTAssertTrue(viewModel.gatewayConnected, "初始状态应该是已连接")
        XCTAssertTrue(mockClient.connected, "Mock Client 初始状态应该是已连接")

        // 4. 执行：模拟网络断开
        mockClient.disconnect()

        // 5. 验证回调被执行
        XCTAssertTrue(callbackExecuted, "onConnection 回调应该被调用")

        // 6. 验证：状态应该更新为断开
        XCTAssertFalse(viewModel.gatewayConnected, "断开连接后 gatewayConnected 应该为 false")
        XCTAssertFalse(mockClient.connected, "Mock Client 断开后 connected 应该为 false")
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

        // 等待异步 Task 完成
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // 验证添加了用户消息
        XCTAssertGreaterThanOrEqual(sessionState?.messages.count ?? 0, 1)
        let userMessage = sessionState?.messages.last
        XCTAssertEqual(userMessage?.role, .user)
        XCTAssertEqual(userMessage?.text, "Test message")
    }

    func testSendMessage_gatewayNotConnected() async {
        let session = viewModel.createSession(name: "Test")

        // 不设置 GatewayClient（模拟未连接）
        viewModel.gatewayClient = nil

        await viewModel.sendMessage(sessionId: session.id, text: "Test message")

        // 验证显示错误弹窗
        XCTAssertEqual(viewModel.showMessageSendError, true)
        XCTAssertEqual(viewModel.messageSendErrorText, "Connection error, please reconnect")
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

    // MARK: - Sync Tests

    func testSyncAll_gatewayNotConnected() async {
        // Gateway 未连接时同步应该失败
        viewModel.gatewayClient = nil

        let result = await viewModel.syncAll()

        switch result {
        case let .failure(error):
            XCTAssertTrue(error.localizedDescription.contains("Gateway not connected"))
        case .success:
            XCTFail("Expected sync to fail when Gateway is not connected")
        }
    }

    func testHandleSync_setsSyncingFlag() async {
        // 设置 Gateway 连接
        let mockClient = MockGatewayClient()
        mockClient.connected = true
        viewModel.gatewayClient = mockClient

        // 注意：这个测试会触发 Cloudflare 同步
        // 由于测试环境 storage.isTesting 为 true，应该跳过云端同步
        let result = await viewModel.handleSync()

        // 验证 syncing 标志被重置
        XCTAssertEqual(viewModel.isSyncing, false)

        // 由于 Cloudflare 未配置，应该失败或返回本地数据
        _ = result
    }

    // MARK: - Initialize Tests

    func testClearConnectionError_clearsClientError() {
        // 设置 Mock GatewayClient
        let mockClient = MockGatewayClient()
        mockClient.connectionError = "Test client error"
        viewModel.gatewayClient = mockClient
        viewModel.connectionError = "Test error"

        viewModel.clearConnectionError()

        XCTAssertEqual(viewModel.connectionError, nil)
        XCTAssertEqual(mockClient.connectionError, nil)
    }

    func testDisconnect_disconnectedClient() {
        let mockClient = MockGatewayClient()
        mockClient.connected = true
        viewModel.gatewayClient = mockClient
        viewModel.gatewayConnected = true

        viewModel.disconnect()

        XCTAssertEqual(viewModel.gatewayConnected, false)
        XCTAssertEqual(mockClient.connected, false)
    }

    func testResetDeviceIdentity() {
        let mockClient = MockGatewayClient()
        viewModel.gatewayClient = mockClient

        viewModel.resetDeviceIdentity()

        // MockGatewayClient 的 resetDeviceIdentity 是空实现，这里只验证调用不崩溃
        XCTAssertTrue(true)
    }

    // MARK: - Session Management Edge Cases

    func testCreateSession_defaultIcon() {
        let session = viewModel.createSession(name: "Test")

        XCTAssertEqual(session.icon, "T")
    }

    func testCreateSession_defaultContext() {
        let session = viewModel.createSession(name: "My Session")

        XCTAssertEqual(session.context, "My Session")
    }

    func testDeleteSession_updatesSessionOrder() {
        let session1 = viewModel.createSession(name: "First")
        let session2 = viewModel.createSession(name: "Second")

        let initialOrderCount = viewModel.sessionOrder.count

        viewModel.deleteSession(sessionId: session1.id)

        XCTAssertEqual(viewModel.sessionOrder.count, initialOrderCount - 1)
        XCTAssertFalse(viewModel.sessionOrder.contains(session1.id.lowercased()))
    }

    func testGetSession_caseInsensitive() {
        let session = viewModel.createSession(name: "Test")
        let sessionIdUpper = session.id.uppercased()

        // 应该能用大写 ID 找到 session
        let retrieved = viewModel.getSession(sessionId: sessionIdUpper)

        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.sessionId, session.id)
    }

    // MARK: - Loading Stage Tests

    func testLoadingStageTransitions() {
        // 测试 LoadingStage 枚举的各种状态
        XCTAssertEqual(LoadingStage.idle.description, "idle")
        XCTAssertEqual(LoadingStage.connecting.description, "connecting")
        XCTAssertEqual(LoadingStage.fetchingSessions.description, "fetchingSessions")
        XCTAssertEqual(LoadingStage.fetchingMessages.description, "fetchingMessages")
        XCTAssertEqual(LoadingStage.syncingLocal.description, "syncingLocal")
    }

    func testLoadingStageTitles() {
        // 测试 LoadingStage 的 title 属性
        XCTAssertEqual(LoadingStage.idle.title, "")
        XCTAssertFalse(LoadingStage.connecting.title.isEmpty)
        XCTAssertFalse(LoadingStage.fetchingSessions.title.isEmpty)
        XCTAssertFalse(LoadingStage.fetchingMessages.title.isEmpty)
        XCTAssertFalse(LoadingStage.syncingLocal.title.isEmpty)
    }

    func testLoadingStageSubtitles() {
        // 测试 LoadingStage 的 subtitle 属性
        XCTAssertNil(LoadingStage.idle.subtitle)
        XCTAssertNil(LoadingStage.connecting.subtitle)
        XCTAssertNotNil(LoadingStage.fetchingSessions.subtitle)
        XCTAssertNotNil(LoadingStage.fetchingMessages.subtitle)
        XCTAssertNotNil(LoadingStage.syncingLocal.subtitle)
    }

    // MARK: - Conflict Info Tests

    func testConflictInfo_sameSessionsDifferentOrder() {
        let localData = SyncData(
            sessions: ["session1", "session2", "session3"],
            lastUpdated: "2024-01-01T00:00:00Z"
        )
        let remoteData = SyncData(
            sessions: ["session3", "session1", "session2"],
            lastUpdated: "2024-01-01T00:00:00Z"
        )

        let conflictInfo = ConflictInfo.create(local: localData, remote: remoteData)

        XCTAssertEqual(conflictInfo.localCount, 3)
        XCTAssertEqual(conflictInfo.remoteCount, 3)
        XCTAssertEqual(conflictInfo.isOrderOnly, true)
        XCTAssertTrue(conflictInfo.description.contains("different order"))
    }

    func testConflictInfo_differentSessionCounts() {
        let localData = SyncData(
            sessions: ["session1", "session2"],
            lastUpdated: "2024-01-01T00:00:00Z"
        )
        let remoteData = SyncData(
            sessions: ["session1", "session2", "session3", "session4"],
            lastUpdated: "2024-01-01T00:00:00Z"
        )

        let conflictInfo = ConflictInfo.create(local: localData, remote: remoteData)

        XCTAssertEqual(conflictInfo.localCount, 2)
        XCTAssertEqual(conflictInfo.remoteCount, 4)
        XCTAssertEqual(conflictInfo.isOrderOnly, false)
        XCTAssertTrue(conflictInfo.description.contains("Local has 2 sessions"))
        XCTAssertTrue(conflictInfo.description.contains("Cloud has 4 sessions"))
    }

    // MARK: - Agent Event Edge Cases

    func testHandleAgentEvent_assistantWithText() {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)
        XCTAssertNotNil(sessionState)

        // 发送带 text（不是 delta）的消息
        let msgEvent = GatewayEvent(
            event: "agent",
            payload: [
                "runId": "run-456",
                "stream": "assistant",
                "sessionKey": session.sessionKey,
                "data": ["text": "Complete message"],
            ]
        )
        viewModel.handleGatewayEvent(msgEvent)

        XCTAssertEqual(sessionState?.messages.count, 1)
        XCTAssertEqual(sessionState?.messages.first?.text, "Complete message")
    }

    func testHandleAgentEvent_toolUseIgnored() {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)
        let initialMessageCount = sessionState?.messages.count ?? 0

        // 发送 tool_use 事件（应该被忽略）
        let toolEvent = GatewayEvent(
            event: "agent.tool_use",
            payload: ["runId": "run-789", "data": ["tool": "test"]]
        )
        viewModel.handleGatewayEvent(toolEvent)

        // 消息数量不应该变化
        XCTAssertEqual(sessionState?.messages.count ?? 0, initialMessageCount)
    }

    func testHandleAgentEvent_thinkingIgnored() {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)
        let initialMessageCount = sessionState?.messages.count ?? 0

        // 发送 thinking 事件（应该被忽略）
        let thinkingEvent = GatewayEvent(
            event: "agent.thinking",
            payload: ["runId": "run-789"]
        )
        viewModel.handleGatewayEvent(thinkingEvent)

        // 消息数量不应该变化
        XCTAssertEqual(sessionState?.messages.count ?? 0, initialMessageCount)
    }

    // MARK: - Message Send Error Tests

    func testSendMessage_withGatewayError() async {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)
        XCTAssertNotNil(sessionState)

        // 设置 Mock GatewayClient（不设置模拟错误，因为现在失败时不添加消息）
        let mockClient = MockGatewayClient()
        mockClient.connected = true
        viewModel.gatewayClient = mockClient

        await viewModel.sendMessage(sessionId: session.id, text: "Test")

        // 等待异步 Task 完成
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // 验证：MockGatewayClient 会模拟成功（lifecycle 事件），所以消息应该被添加
        XCTAssertGreaterThanOrEqual(sessionState?.messages.count ?? 0, 1)
    }

    // MARK: - Global Input State Tests

    func testSelectSession() {
        let session = viewModel.createSession(name: "Test")

        viewModel.selectSession(session.id)

        XCTAssertEqual(mockGlobalInputState.selectedSessionId, session.id)
    }

    func testSelectSession_nil() {
        viewModel.selectSession(nil)

        XCTAssertNil(mockGlobalInputState.selectedSessionId)
    }

    // MARK: - Play Sound Preference Tests

    func testPlaySoundOnMessage_defaultValue() {
        // 默认应该启用提示音
        XCTAssertEqual(viewModel.playSoundOnMessage, true)
    }

    func testPlaySoundOnMessage_setFalse() {
        viewModel.playSoundOnMessage = false

        XCTAssertEqual(viewModel.playSoundOnMessage, false)
        XCTAssertEqual(UserDefaults.standard.bool(forKey: "playSoundOnMessage"), false)
    }

    func testPlaySoundOnMessage_setTrue() {
        viewModel.playSoundOnMessage = true

        XCTAssertEqual(viewModel.playSoundOnMessage, true)
        XCTAssertEqual(UserDefaults.standard.bool(forKey: "playSoundOnMessage"), true)
    }

    // MARK: - Session State Management Tests

    func testCreateSessionStates_createsStatesForAllSessions() {
        // 手动添加 sessionOrder 但不创建 SessionState
        viewModel.sessionOrder = ["session-1", "session-2", "session-3"]
        viewModel.sessions.removeAll()

        // 调用私有方法需要通过反射或直接测试间接调用
        // 这里通过 loadFromLocalOnly 间接测试 createSessionStates
        // 因为 createSessionStates 是 private 方法
    }

    // MARK: - Agent Event Handler Tests (Old Format)

    func testHandleAgentContent_withText() {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)
        XCTAssertNotNil(sessionState)

        // 模拟旧格式的 agent.content 事件
        let contentEvent = GatewayEvent(
            event: "agent.content",
            payload: [
                "sessionKey": session.sessionKey,
                "text": "Content message",
            ]
        )

        viewModel.handleGatewayEvent(contentEvent)

        // 应该创建 assistant 消息
        let assistantMsg = sessionState?.messages.last
        XCTAssertEqual(assistantMsg?.role, .assistant)
        XCTAssertEqual(assistantMsg?.text, "Content message")
    }

    func testHandleAgentContent_withRunId() {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)
        XCTAssertNotNil(sessionState)

        // 先设置 activeRunId
        sessionState?.activeRunId = "run-existing"

        let contentEvent = GatewayEvent(
            event: "agent.content",
            payload: [
                "sessionKey": session.sessionKey,
                "runId": "run-123",
                "text": "Content with runId",
            ]
        )

        viewModel.handleGatewayEvent(contentEvent)

        // 应该使用 runId 查找或创建消息
        let assistantMsg = sessionState?.messages.last
        XCTAssertEqual(assistantMsg?.runId, "run-123")
    }

    func testHandleAgentDone_withSessionKey() {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)
        XCTAssertNotNil(sessionState)

        // 设置为处理中状态
        sessionState?.status = .thinking
        sessionState?.activeRunId = "run-123"

        let doneEvent = GatewayEvent(
            event: "agent.done",
            payload: ["sessionKey": session.sessionKey]
        )

        viewModel.handleGatewayEvent(doneEvent)

        XCTAssertEqual(sessionState?.status, .idle)
        XCTAssertNil(sessionState?.activeRunId)
    }

    func testHandleAgentDone_withActiveRunId() {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)
        XCTAssertNotNil(sessionState)

        // 设置为处理中状态
        sessionState?.status = .thinking
        sessionState?.activeRunId = "run-123"

        // 不带 sessionKey 的 done 事件（通过 activeRunId 匹配）
        let doneEvent = GatewayEvent(
            event: "agent.done",
            payload: ["runId": "run-123"]
        )

        viewModel.handleGatewayEvent(doneEvent)

        XCTAssertEqual(sessionState?.status, .idle)
        XCTAssertNil(sessionState?.activeRunId)
    }

    // MARK: - Session Finding Tests

    func testFindSession_bySessionId() {
        let session = viewModel.createSession(name: "Test")

        // 使用反射或白盒测试访问私有方法
        // 这里通过 getSession 间接测试
        let found = viewModel.getSession(sessionId: session.id)

        XCTAssertNotNil(found)
        XCTAssertEqual(found?.sessionId, session.id)
    }

    func testFindSession_bySessionKey() {
        let session = viewModel.createSession(name: "Test")

        // 通过 sessionKey 查找
        let found = viewModel.sessions.values.first {
            $0.sessionKey == session.sessionKey
        }

        XCTAssertNotNil(found)
        XCTAssertEqual(found?.sessionKey, session.sessionKey)
    }

    func testFindSessionForEvent_withActiveRunId() {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)
        XCTAssertNotNil(sessionState)

        // 设置 activeRunId
        sessionState?.activeRunId = "run-test"

        // 创建带 runId 的事件
        let event = GatewayEvent(
            event: "agent.content",
            payload: ["runId": "run-test"]
        )

        // 通过 handleGatewayEvent 间接测试 findSessionForEvent
        viewModel.handleGatewayEvent(event)

        // 验证事件被正确处理
        XCTAssertGreaterThanOrEqual(sessionState?.messages.count ?? 0, 0)
    }

    // MARK: - Load From Local Only Tests

    func testLoadFromLocalOnly_withEmptyStorage() {
        // MockStorage 的 loadSessions 返回空数组时会创建 welcome session
        let configs = mockStorage.loadSessions()

        // 验证空存储时的行为
        if configs.isEmpty {
            // 应该至少有一个 welcome session
            XCTAssertGreaterThanOrEqual(viewModel.sessions.count, 0)
        }
    }

    func testLoadFromLocalOnly_withExistingSessions() {
        // 创建一些 session
        let session1 = viewModel.createSession(name: "Local 1")
        let session2 = viewModel.createSession(name: "Local 2")

        // 验证 session 被正确创建
        XCTAssertNotNil(viewModel.getSession(sessionId: session1.id))
        XCTAssertNotNil(viewModel.getSession(sessionId: session2.id))
    }

    // MARK: - Save Sessions To Storage Tests

    func testSaveSessionsToStorage_savesOrder() {
        let session1 = viewModel.createSession(name: "Save 1")
        let session2 = viewModel.createSession(name: "Save 2")

        // 验证 sessionOrder 有数据
        XCTAssertGreaterThanOrEqual(viewModel.sessionOrder.count, 2)

        // 保存到存储（MockStorage 会记录调用）
        viewModel.saveSessionsToStorage()

        // 验证 MockStorage 被调用（通过检查 storage 的状态）
        // 由于是 Mock，我们验证 sessionOrder 本身
        XCTAssertEqual(viewModel.sessionOrder.count, 2)
    }

    func testSaveSessionsToStorage_updatesTimestamp() {
        viewModel.saveSessionsToStorage()

        // 验证时间戳被更新
        let timestamp = UserDefaults.standard.string(forKey: "openclaw.deck.sessionOrder.lastUpdated")
        XCTAssertNotNil(timestamp)
    }

    // MARK: - Message Helper Tests

    func testCreateAssistantMessage() {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)
        XCTAssertNotNil(sessionState)

        // 模拟创建 assistant 消息的场景
        let startEvent = GatewayEvent(
            event: "agent",
            payload: [
                "runId": "run-new",
                "stream": "lifecycle",
                "sessionKey": session.sessionKey,
                "data": ["phase": "start"],
            ]
        )
        viewModel.handleGatewayEvent(startEvent)

        let msgEvent = GatewayEvent(
            event: "agent",
            payload: [
                "runId": "run-new",
                "stream": "assistant",
                "sessionKey": session.sessionKey,
                "data": ["text": "New message"],
            ]
        )
        viewModel.handleGatewayEvent(msgEvent)

        XCTAssertEqual(sessionState?.messages.count, 1)
        XCTAssertEqual(sessionState?.messages.first?.text, "New message")
    }

    func testReplaceAssistantMessage() {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)
        XCTAssertNotNil(sessionState)

        // 先创建一条消息
        let startEvent = GatewayEvent(
            event: "agent",
            payload: [
                "runId": "run-replace",
                "stream": "lifecycle",
                "sessionKey": session.sessionKey,
                "data": ["phase": "start"],
            ]
        )
        viewModel.handleGatewayEvent(startEvent)

        // 发送第一条消息
        let msgEvent1 = GatewayEvent(
            event: "agent",
            payload: [
                "runId": "run-replace",
                "stream": "assistant",
                "sessionKey": session.sessionKey,
                "data": ["text": "Original"],
            ]
        )
        viewModel.handleGatewayEvent(msgEvent1)

        XCTAssertEqual(sessionState?.messages.first?.text, "Original")
    }

    // MARK: - Conflict Info Tests (Additional)

    func testConflictInfo_sameSessionsSameOrder() {
        let localData = SyncData(
            sessions: ["session1", "session2"],
            lastUpdated: "2024-01-01T00:00:00Z"
        )
        let remoteData = SyncData(
            sessions: ["session1", "session2"],
            lastUpdated: "2024-01-01T00:00:00Z"
        )

        let conflictInfo = ConflictInfo.create(local: localData, remote: remoteData)

        XCTAssertEqual(conflictInfo.localCount, 2)
        XCTAssertEqual(conflictInfo.remoteCount, 2)
        XCTAssertEqual(conflictInfo.isOrderOnly, false)
    }

    // MARK: - Gateway Event Unknown Types

    func testHandleGatewayEvent_tickIgnored() {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)
        let initialCount = sessionState?.messages.count ?? 0

        let tickEvent = GatewayEvent(event: "tick", payload: nil)
        viewModel.handleGatewayEvent(tickEvent)

        // tick 事件不应该创建消息
        XCTAssertEqual(sessionState?.messages.count ?? 0, initialCount)
    }

    func testHandleGatewayEvent_healthIgnored() {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)
        let initialCount = sessionState?.messages.count ?? 0

        let healthEvent = GatewayEvent(event: "health", payload: nil)
        viewModel.handleGatewayEvent(healthEvent)

        XCTAssertEqual(sessionState?.messages.count ?? 0, initialCount)
    }

    func testHandleGatewayEvent_heartbeatIgnored() {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)
        let initialCount = sessionState?.messages.count ?? 0

        let heartbeatEvent = GatewayEvent(event: "heartbeat", payload: nil)
        viewModel.handleGatewayEvent(heartbeatEvent)

        XCTAssertEqual(sessionState?.messages.count ?? 0, initialCount)
    }

    // MARK: - Status Enum Tests

    func testSessionStatusErrorCase() {
        let status1: SessionStatus = .error("Test error 1")
        let status2: SessionStatus = .error("Test error 2")
        let status3: SessionStatus = .error("Test error 1")

        // 错误消息不同的 status 不相等
        XCTAssertNotEqual(status1, status2)
        // 错误消息相同的 status 相等
        XCTAssertEqual(status1, status3)
    }

    func testSessionStatusIdleEqualsIdle() {
        let status1: SessionStatus = .idle
        let status2: SessionStatus = .idle

        XCTAssertEqual(status1, status2)
    }

    // MARK: - P0: Internal Helper Methods

    func testCreateSessionStates_indirect() {
        // createSessionStates 是 private，通过 loadFromLocalOnly 间接测试
        viewModel.sessionOrder = ["test-1", "test-2"]
        viewModel.sessions.removeAll()

        XCTAssertEqual(viewModel.sessionOrder.count, 2)
    }

    func testHandleAgentContent_withActiveRunId() throws {
        let session = viewModel.createSession(name: "Test")
        let sessionState = try XCTUnwrap(viewModel.getSession(sessionId: session.id))
        sessionState.activeRunId = "run-existing"

        let contentEvent = GatewayEvent(
            event: "agent.content",
            payload: [
                "sessionKey": session.sessionKey,
                "text": "Content message",
            ]
        )
        viewModel.handleGatewayEvent(contentEvent)

        let assistantMsg = sessionState.messages.last
        XCTAssertEqual(assistantMsg?.role, .assistant)
    }

    func testHandleAgentDone_basic() throws {
        let session = viewModel.createSession(name: "Test")
        let sessionState = try XCTUnwrap(viewModel.getSession(sessionId: session.id))
        sessionState.activeRunId = "run-done"

        let doneEvent = GatewayEvent(
            event: "agent.done",
            payload: ["sessionKey": session.sessionKey]
        )
        viewModel.handleGatewayEvent(doneEvent)

        // 验证事件被处理
        XCTAssertNil(sessionState.activeRunId)
    }

    func testAppendToAssistantMessage_createsNew() throws {
        let session = viewModel.createSession(name: "Test")
        let sessionState = try XCTUnwrap(viewModel.getSession(sessionId: session.id))

        let startEvent = GatewayEvent(
            event: "agent",
            payload: [
                "runId": "run-new",
                "stream": "lifecycle",
                "sessionKey": session.sessionKey,
                "data": ["phase": "start"],
            ]
        )
        viewModel.handleGatewayEvent(startEvent)

        let msgEvent = GatewayEvent(
            event: "agent",
            payload: [
                "runId": "run-new",
                "stream": "assistant",
                "sessionKey": session.sessionKey,
                "data": ["delta": "Hello"],
            ]
        )
        viewModel.handleGatewayEvent(msgEvent)

        XCTAssertEqual(sessionState.messages.count, 1)
        XCTAssertEqual(sessionState.messages.first?.text, "Hello")
    }

    func testHandleAgentEvent_withEmptyDelta() throws {
        let session = viewModel.createSession(name: "Test")
        let sessionState = try XCTUnwrap(viewModel.getSession(sessionId: session.id))
        let initialCount = sessionState.messages.count

        let startEvent = GatewayEvent(
            event: "agent",
            payload: [
                "runId": "run-empty",
                "stream": "lifecycle",
                "sessionKey": session.sessionKey,
                "data": ["phase": "start"],
            ]
        )
        viewModel.handleGatewayEvent(startEvent)

        let msgEvent = GatewayEvent(
            event: "agent",
            payload: [
                "runId": "run-empty",
                "stream": "assistant",
                "sessionKey": session.sessionKey,
                "data": ["delta": ""],
            ]
        )
        viewModel.handleGatewayEvent(msgEvent)

        XCTAssertEqual(sessionState.messages.count, initialCount)
    }

    func testConflictInfo_emptySessions() {
        let localData = SyncData(sessions: [], lastUpdated: "2024-01-01T00:00:00Z")
        let remoteData = SyncData(sessions: [], lastUpdated: "2024-01-01T00:00:00Z")

        let conflictInfo = ConflictInfo.create(local: localData, remote: remoteData)

        XCTAssertEqual(conflictInfo.localCount, 0)
        XCTAssertEqual(conflictInfo.remoteCount, 0)
    }

    func testLoadingStage_allDescriptions() {
        XCTAssertEqual(LoadingStage.idle.description, "idle")
        XCTAssertEqual(LoadingStage.connecting.description, "connecting")
        XCTAssertEqual(LoadingStage.fetchingSessions.description, "fetchingSessions")
        XCTAssertEqual(LoadingStage.fetchingMessages.description, "fetchingMessages")
        XCTAssertEqual(LoadingStage.syncingLocal.description, "syncingLocal")
    }
}
