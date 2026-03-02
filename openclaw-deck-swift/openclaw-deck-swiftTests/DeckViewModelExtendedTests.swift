// DeckViewModelExtendedTests.swift
// OpenClaw Deck Swift
//
// 扩展测试 - 覆盖 DeckViewModel 的更多方法

@testable import openclaw_deck_swift
import XCTest

@MainActor
final class DeckViewModelExtendedTests: XCTestCase {
    var viewModel: DeckViewModel!
    var mockStorage: MockUserDefaultsStorage!
    var mockGlobalInputState: MockGlobalInputState!

    override func setUp() async throws {
        try await super.setUp()
        mockStorage = MockFactory.createMockStorage()
        mockGlobalInputState = MockGlobalInputState()
        // 清除 Cloudflare 配置，避免测试中访问 Keychain
        CloudflareConfig.clear()
        let testDIContainer = MockFactory.createDIContainer(
            storage: mockStorage,
            globalInputState: mockGlobalInputState
        )
        viewModel = DeckViewModel(diContainer: testDIContainer)
        // 加载 sessions（会创建 welcome session）
        await viewModel.loadSessionsFromStorageForTesting()
    }

    override func tearDown() async throws {
        viewModel = nil
        mockStorage = nil
        mockGlobalInputState = nil
        try await super.tearDown()
    }

    // MARK: - Storage Tests

    func testLoadSessionsFromStorage_withMockStorage() {
        // 验证使用 Mock Storage 时不会访问云端
        XCTAssertTrue(mockStorage.isTesting)

        // 创建一些测试数据
        let session = viewModel.createSession(name: "Test")

        // 验证数据保存在 Mock 中
        let savedSessions = mockStorage.loadSessions()
        XCTAssertTrue(savedSessions.contains { $0.id == session.id })
    }

    func testSaveSessionsToStorage_withMockStorage() {
        // 初始有 1 个 welcome session，再创建 2 个，总共 3 个
        _ = viewModel.createSession(name: "Test1")
        _ = viewModel.createSession(name: "Test2")

        // 验证保存到了 Mock（welcome + Test1 + Test2 = 3 个）
        let savedSessions = mockStorage.loadSessions()
        XCTAssertEqual(savedSessions.count, 3)

        let savedOrder = mockStorage.loadSessionOrder()
        XCTAssertEqual(savedOrder.count, 3)
    }

    func testSaveSessionsToStorage_updatesLastUpdated() {
        _ = viewModel.createSession(name: "Test")

        // 验证最后更新时间被设置
        let lastUpdated = UserDefaults.standard.string(forKey: "openclaw.deck.sessionOrder.lastUpdated")
        XCTAssertNotNil(lastUpdated)
    }

    // MARK: - Session Management Extended Tests

    func testDeleteSession_removesFromStorage() {
        let session = viewModel.createSession(name: "To Delete")

        // 验证已保存
        var savedSessions = mockStorage.loadSessions()
        XCTAssertTrue(savedSessions.contains { $0.id == session.id })

        // 删除
        viewModel.deleteSession(sessionId: session.id)

        // 验证从 Mock 中移除
        savedSessions = mockStorage.loadSessions()
        XCTAssertFalse(savedSessions.contains { $0.id == session.id })
    }

    func testDeleteSession_removesFromOrder() {
        let session = viewModel.createSession(name: "To Delete")

        // 验证在顺序列表中
        var savedOrder = mockStorage.loadSessionOrder()
        XCTAssertTrue(savedOrder.contains(session.id.lowercased()))

        // 删除
        viewModel.deleteSession(sessionId: session.id)

        // 验证从顺序列表中移除
        savedOrder = mockStorage.loadSessionOrder()
        XCTAssertFalse(savedOrder.contains(session.id.lowercased()))
    }

    func testDeleteAllSessions_createsWelcomeSession() {
        // 删除所有 session
        let sessionIds = viewModel.sessionOrder.map(\.self)
        for id in sessionIds {
            viewModel.deleteSession(sessionId: id)
        }

        // 验证创建了 welcome session
        XCTAssertGreaterThanOrEqual(viewModel.sessions.count, 1)
    }

    func testGetSession_caseInsensitive() {
        let session = viewModel.createSession(name: "Test")

        // 大小写不敏感查找
        let found1 = viewModel.getSession(sessionId: session.id)
        let found2 = viewModel.getSession(sessionId: session.id.uppercased())
        let found3 = viewModel.getSession(sessionId: session.id.lowercased())

        XCTAssertNotNil(found1)
        XCTAssertNotNil(found2)
        XCTAssertNotNil(found3)
        XCTAssertEqual(found1?.sessionId, found2?.sessionId)
        XCTAssertEqual(found1?.sessionId, found3?.sessionId)
    }

    // MARK: - Session Order Tests

    func testSessionOrder_newSessionInsertedAtBeginning() {
        let initialCount = viewModel.sessionOrder.count

        let session1 = viewModel.createSession(name: "First")
        XCTAssertEqual(viewModel.sessionOrder[0], session1.id.lowercased())

        let session2 = viewModel.createSession(name: "Second")
        XCTAssertEqual(viewModel.sessionOrder[0], session2.id.lowercased())
        XCTAssertEqual(viewModel.sessionOrder[1], session1.id.lowercased())

        let session3 = viewModel.createSession(name: "Third")
        XCTAssertEqual(viewModel.sessionOrder[0], session3.id.lowercased())
        XCTAssertEqual(viewModel.sessionOrder[1], session2.id.lowercased())
        XCTAssertEqual(viewModel.sessionOrder[2], session1.id.lowercased())
    }

    func testSessionOrder_afterDelete() {
        // 初始有 welcome session，创建 3 个后共 4 个
        let session1 = viewModel.createSession(name: "First")
        let session2 = viewModel.createSession(name: "Second")
        let session3 = viewModel.createSession(name: "Third")

        // 顺序：[third, second, first, welcome]
        XCTAssertEqual(viewModel.sessionOrder.count, 4)

        // 删除 second
        viewModel.deleteSession(sessionId: session2.id)

        // 顺序应该是：[third, first, welcome]
        XCTAssertEqual(viewModel.sessionOrder.count, 3)
        // 验证顺序正确（前两个是 third 和 first）
        XCTAssertEqual(viewModel.sessionOrder[0], session3.id.lowercased())
        XCTAssertEqual(viewModel.sessionOrder[1], session1.id.lowercased())
    }

    // MARK: - Gateway Connection Tests

    func testInitialize_savesConfig() async {
        // 验证初始状态
        XCTAssertFalse(viewModel.isInitializing)

        // 调用初始化
        await viewModel.initialize(url: "ws://test.com", token: "test-token")

        // 验证初始化完成后配置已保存
        XCTAssertEqual(viewModel.config.gatewayUrl, "ws://test.com")
        XCTAssertEqual(viewModel.config.token, "test-token")
        // 注意：isInitializing 在连接成功/失败后才会清除，这里是异步的
        // 所以这里只验证配置保存，不验证 isInitializing 状态
    }

    func testDisconnect_clearsGatewayClient() {
        // 断开连接
        viewModel.disconnect()

        // 验证连接状态
        XCTAssertFalse(viewModel.gatewayConnected)
    }

    func testClearConnectionError_clearsError() {
        // 设置错误
        viewModel.connectionError = "Test error"
        XCTAssertNotNil(viewModel.connectionError)

        // 清除错误
        viewModel.clearConnectionError()
        XCTAssertNil(viewModel.connectionError)
    }

    // MARK: - Event Handling Extended Tests

    func testHandleGatewayEvent_allEventTypes() {
        let events = [
            GatewayEvent(event: "tick", payload: nil),
            GatewayEvent(event: "health", payload: nil),
            GatewayEvent(event: "heartbeat", payload: nil),
            GatewayEvent(event: "unknown.event", payload: nil),
            GatewayEvent(event: "agent", payload: nil),
        ]

        // 验证所有事件类型都不会导致崩溃
        for event in events {
            viewModel.handleGatewayEvent(event)
        }
    }

    func testHandleAgentEvent_withValidPayload() {
        // 有效的 agent 事件 payload
        let event = GatewayEvent(
            event: "agent",
            payload: [
                "sessionKey": "test-key",
                "runId": "run-123",
                "stream": "assistant",
                "text": "Hello",
            ]
        )

        // 不应该崩溃
        viewModel.handleGatewayEvent(event)
    }

    func testHandleAgentEvent_withDifferentStreamTypes() {
        let streamTypes = ["assistant", "user", "system", "thinking"]

        for streamType in streamTypes {
            let event = GatewayEvent(
                event: "agent",
                payload: [
                    "sessionKey": "test-key",
                    "runId": "run-123",
                    "stream": streamType,
                ]
            )

            viewModel.handleGatewayEvent(event)
        }
    }

    // MARK: - Config Tests

    func testConfig_defaultValues() {
        let config = viewModel.config

        // 验证默认配置
        XCTAssertEqual(config.gatewayUrl, "ws://127.0.0.1:18789")
        XCTAssertEqual(config.mainAgentId, "main")
    }

    func testConfig_isValidGatewayUrl() {
        let config = AppConfig(
            gatewayUrl: "ws://localhost:18789", token: "test-token", mainAgentId: "main"
        )

        XCTAssertTrue(config.isValidGatewayUrl)
        XCTAssertTrue(config.isValidToken)
        XCTAssertTrue(config.isComplete)
    }

    func testConfig_invalidGatewayUrl() {
        let config = AppConfig(
            gatewayUrl: "invalid-url", token: "test-token", mainAgentId: "main"
        )
        XCTAssertFalse(config.isValidGatewayUrl)
    }

    func testConfig_invalidToken() {
        let config = AppConfig(
            gatewayUrl: "ws://localhost:18789", token: "", mainAgentId: "main"
        )
        XCTAssertFalse(config.isValidToken)
    }

    // MARK: - Play Sound Configuration

    func testPlaySoundOnMessage_defaultValue() {
        XCTAssertTrue(viewModel.playSoundOnMessage)
    }

    func testPlaySoundOnMessage_setValue() {
        viewModel.playSoundOnMessage = false
        XCTAssertFalse(viewModel.playSoundOnMessage)

        viewModel.playSoundOnMessage = true
        XCTAssertTrue(viewModel.playSoundOnMessage)
    }

    func testPlaySoundOnMessage_persistsToUserDefaults() {
        viewModel.playSoundOnMessage = false

        let saved = UserDefaults.standard.bool(forKey: "playSoundOnMessage")
        XCTAssertFalse(saved)
    }

    // MARK: - Reconnection Tests

    func testIsReconnecting_defaultValue() {
        XCTAssertFalse(viewModel.isReconnecting)
    }

    func testReconnectAttempts_defaultValue() {
        XCTAssertEqual(viewModel.reconnectAttempts, 0)
    }

    func testIsSyncing_defaultValue() {
        XCTAssertFalse(viewModel.isSyncing)
    }

    // MARK: - Edge Cases

    func testCreateSession_withVeryLongName() {
        let longName = String(repeating: "A", count: 1000)
        let session = viewModel.createSession(name: longName)

        XCTAssertNotNil(session)
        XCTAssertEqual(session.name, longName)
    }

    func testCreateSession_withEmojiName() {
        let session = viewModel.createSession(name: "🎉 Test 🚀 Session 🎊")

        XCTAssertNotNil(session)
        XCTAssertEqual(session.name, "🎉 Test 🚀 Session 🎊")
    }

    func testCreateSession_withUnicodeName() {
        let session = viewModel.createSession(name: "测试会话 - テスト - 테스트")

        XCTAssertNotNil(session)
        XCTAssertEqual(session.name, "测试会话 - テスト - 테스트")
    }

    func testDeleteSession_withCaseVariations() {
        let session = viewModel.createSession(name: "Test")

        // 用不同大小写删除
        viewModel.deleteSession(sessionId: session.id.uppercased())
        XCTAssertNil(viewModel.getSession(sessionId: session.id))
    }

    func testMultipleDeleteCalls_sameSession() {
        let session = viewModel.createSession(name: "Test")

        // 多次删除同一个 session 不应该崩溃
        viewModel.deleteSession(sessionId: session.id)
        viewModel.deleteSession(sessionId: session.id)
        viewModel.deleteSession(sessionId: session.id.uppercased())
    }

    // MARK: - Session State Tests

    func testSessionState_messageManagement() {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)

        XCTAssertNotNil(sessionState)
        guard let state = sessionState else { return }

        // 初始状态
        XCTAssertEqual(state.messages.count, 0)
        XCTAssertFalse(state.historyLoaded)
        XCTAssertFalse(state.isHistoryLoading)
        XCTAssertEqual(state.status, .idle)
        XCTAssertNil(state.activeRunId)
        XCTAssertFalse(state.isProcessing)
        XCTAssertFalse(state.hasUnreadMessage)
    }

    func testSessionState_contextManagement() {
        let session = viewModel.createSession(name: "Test", context: "Test context")

        XCTAssertEqual(session.context, "Test context")

        let sessionState = viewModel.getSession(sessionId: session.id)
        XCTAssertEqual(sessionState?.context, "Test context")
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentSessionCreation() {
        let expectation = XCTestExpectation(description: "Concurrent creation")

        // 并发创建多个 session
        for i in 0 ..< 10 {
            Task {
                _ = viewModel.createSession(name: "Concurrent-\(i)")
                if i == 9 {
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 5.0)

        // 验证所有 session 都创建了
        XCTAssertGreaterThanOrEqual(viewModel.sessions.count, 10)
    }

    func testConcurrentSessionDeletion() {
        // 先创建多个 session
        var sessions: [String] = []
        for i in 0 ..< 10 {
            let session = viewModel.createSession(name: "Test-\(i)")
            sessions.append(session.id)
        }

        let expectation = XCTestExpectation(description: "Concurrent deletion")

        // 并发删除
        for (index, sessionId) in sessions.enumerated() {
            Task {
                viewModel.deleteSession(sessionId: sessionId)
                if index == sessions.count - 1 {
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }
}
