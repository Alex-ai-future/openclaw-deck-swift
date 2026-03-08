// DeckViewModelMessageTests.swift
// OpenClaw Deck Swift
//
// 消息接收逻辑测试 - 测试 handleAgentEvent、appendToAssistantMessage、replaceAssistantMessage 等方法

@testable import openclaw_deck_swift
import XCTest

@MainActor
final class DeckViewModelMessageTests: XCTestCase {
    var viewModel: DeckViewModel!
    var mockStorage: MockUserDefaultsStorage!
    var mockGlobalInputState: MockGlobalInputState!
    var mockClient: MockGatewayClient!

    override func setUp() async throws {
        try await super.setUp()

        // 清理 UserDefaults，避免测试间状态污染
        UserDefaults.standard.removeObject(forKey: "openclaw.deck.gatewayUrl")
        UserDefaults.standard.removeObject(forKey: "openclaw.deck.token")
        UserDefaults.standard.removeObject(forKey: "openclaw.deck.sessionOrder")
        UserDefaults.standard.synchronize()

        // 使用 Mock 存储和 Mock GlobalInputState
        mockStorage = MockFactory.createMockStorage()
        mockGlobalInputState = MockGlobalInputState()
        let testDIContainer = MockFactory.createDIContainer(
            storage: mockStorage,
            globalInputState: mockGlobalInputState
        )
        viewModel = DeckViewModel(diContainer: testDIContainer)

        // 创建 Mock GatewayClient
        mockClient = MockGatewayClient()
        mockClient.connected = true
        viewModel.gatewayClient = mockClient

        // 创建测试 Session
        _ = viewModel.createSession(name: "Test")
    }

    override func tearDown() async throws {
        viewModel = nil
        mockStorage = nil
        mockGlobalInputState = nil
        mockClient = nil

        // 清理 UserDefaults
        UserDefaults.standard.removeObject(forKey: "openclaw.deck.gatewayUrl")
        UserDefaults.standard.removeObject(forKey: "openclaw.deck.token")
        UserDefaults.standard.removeObject(forKey: "openclaw.deck.sessionOrder")
        UserDefaults.standard.synchronize()

        try await super.tearDown()
    }

    // MARK: - Delta Streaming Tests

    /// 测试 delta 流式追加 - 单条 delta 消息
    func testHandleAgentEvent_Assistant_Delta_Single() {
        // 准备：获取测试 session
        guard let session = viewModel.sessions.values.first else {
            XCTFail("Session should exist")
            return
        }

        let runId = "test-run-1"
        let sessionKey = session.sessionKey

        // 模拟收到 delta 事件
        let deltaEvent = GatewayEvent(
            event: "agent",
            payload: [
                "runId": runId,
                "stream": "assistant",
                "sessionKey": sessionKey,
                "seq": 1,
                "data": ["delta": "Hello"],
            ] as [String: Any]
        )

        // 执行：处理事件
        viewModel.handleGatewayEvent(deltaEvent)

        // 验证：消息被添加
        XCTAssertEqual(session.messages.count, 1, "应该添加 1 条消息")
        XCTAssertEqual(session.messages[0].text, "Hello")
        XCTAssertEqual(session.messages[0].runId, runId)
        XCTAssertEqual(session.messages[0].seq, 1)
        XCTAssertEqual(session.messages[0].streaming, true)
    }

    /// 测试 delta 流式追加 - 多条 delta 消息累积
    func testHandleAgentEvent_Assistant_Delta_Multiple() {
        // 准备
        guard let session = viewModel.sessions.values.first else {
            XCTFail("Session should exist")
            return
        }

        let runId = "test-run-2"
        let sessionKey = session.sessionKey

        // 模拟收到多条 delta 事件
        let deltaEvent1 = GatewayEvent(
            event: "agent",
            payload: [
                "runId": runId,
                "stream": "assistant",
                "sessionKey": sessionKey,
                "seq": 1,
                "data": ["delta": "Hello"],
            ] as [String: Any]
        )

        let deltaEvent2 = GatewayEvent(
            event: "agent",
            payload: [
                "runId": runId,
                "stream": "assistant",
                "sessionKey": sessionKey,
                "seq": 2,
                "data": ["delta": " "],
            ] as [String: Any]
        )

        let deltaEvent3 = GatewayEvent(
            event: "agent",
            payload: [
                "runId": runId,
                "stream": "assistant",
                "sessionKey": sessionKey,
                "seq": 3,
                "data": ["delta": "World"],
            ] as [String: Any]
        )

        // 执行
        viewModel.handleGatewayEvent(deltaEvent1)
        viewModel.handleGatewayEvent(deltaEvent2)
        viewModel.handleGatewayEvent(deltaEvent3)

        // 验证：消息应该累积 - 3 条 delta 合并为 1 条消息
        XCTAssertEqual(session.messages.count, 1, "3 条 delta 应该累积到 1 条消息")
        XCTAssertEqual(session.messages[0].text, "Hello World", "文本应该累积")
        XCTAssertEqual(session.messages[0].seq, 3, "seq 应该是最后一条的序号")
        XCTAssertEqual(session.messages[0].runId, runId, "runId 应该匹配")
    }

    /// 测试 seq 去重 - 相同的 seq 不应该重复处理
    func testHandleAgentEvent_Assistant_Seq_Deduplication() {
        // 准备
        guard let session = viewModel.sessions.values.first else {
            XCTFail("Session should exist")
            return
        }

        let runId = "test-run-3"
        let sessionKey = session.sessionKey

        // 发送两次相同 seq 的事件
        let deltaEvent = GatewayEvent(
            event: "agent",
            payload: [
                "runId": runId,
                "stream": "assistant",
                "sessionKey": sessionKey,
                "seq": 1,
                "data": ["delta": "Hello"],
            ] as [String: Any]
        )

        // 执行：发送两次
        viewModel.handleGatewayEvent(deltaEvent)
        viewModel.handleGatewayEvent(deltaEvent)

        // 验证：只处理一次
        XCTAssertEqual(session.messages.count, 1, "相同 seq 的消息应该只处理一次")
        XCTAssertEqual(session.messages[0].text, "Hello")
    }

    // MARK: - Text Full Text Mode Tests

    /// 测试 text 完整文本模式 - 创建新消息
    func testHandleAgentEvent_Assistant_Text_CreateNew() {
        // 准备
        guard let session = viewModel.sessions.values.first else {
            XCTFail("Session should exist")
            return
        }

        let runId = "test-run-4"
        let sessionKey = session.sessionKey

        // 模拟收到 text 事件（完整文本）
        let textEvent = GatewayEvent(
            event: "agent",
            payload: [
                "runId": runId,
                "stream": "assistant",
                "sessionKey": sessionKey,
                "seq": 1,
                "data": ["text": "This is a complete message"],
            ] as [String: Any]
        )

        // 执行
        viewModel.handleGatewayEvent(textEvent)

        // 验证
        XCTAssertEqual(session.messages.count, 1, "应该添加 1 条消息")
        XCTAssertEqual(session.messages[0].text, "This is a complete message")
        XCTAssertEqual(session.messages[0].runId, runId)
        XCTAssertEqual(session.messages[0].streaming, true)
    }

    /// 测试 text 完整文本模式 - 更新现有消息
    func testHandleAgentEvent_Assistant_Text_UpdateExisting() {
        // 准备
        guard let session = viewModel.sessions.values.first else {
            XCTFail("Session should exist")
            return
        }

        let runId = "test-run-5"
        let sessionKey = session.sessionKey

        // 先发送 delta 创建消息
        let deltaEvent = GatewayEvent(
            event: "agent",
            payload: [
                "runId": runId,
                "stream": "assistant",
                "sessionKey": sessionKey,
                "seq": 1,
                "data": ["delta": "Hello"],
            ] as [String: Any]
        )
        viewModel.handleGatewayEvent(deltaEvent)

        // 验证初始消息
        XCTAssertEqual(session.messages.count, 1)
        XCTAssertEqual(session.messages[0].text, "Hello")

        // 再发送 text 事件（完整文本）- 应该更新现有消息
        let textEvent = GatewayEvent(
            event: "agent",
            payload: [
                "runId": runId,
                "stream": "assistant",
                "sessionKey": sessionKey,
                "seq": 2,
                "data": ["text": "Hello World - Complete"],
            ] as [String: Any]
        )
        viewModel.handleGatewayEvent(textEvent)

        // 验证：消息被更新而不是新增
        XCTAssertEqual(session.messages.count, 1, "应该还是 1 条消息（更新而不是新增）")
        XCTAssertEqual(session.messages[0].text, "Hello World - Complete", "消息内容应该被替换")
    }

    // MARK: - RunId Matching Tests

    /// 测试 runId 匹配 - 多个 runId 同时存在
    func testHandleAgentEvent_Assistant_RunId_Matching() {
        // 准备
        guard let session = viewModel.sessions.values.first else {
            XCTFail("Session should exist")
            return
        }

        let sessionKey = session.sessionKey
        let runId1 = "test-run-6a"
        let runId2 = "test-run-6b"

        // 发送第一个 runId 的消息
        let event1 = GatewayEvent(
            event: "agent",
            payload: [
                "runId": runId1,
                "stream": "assistant",
                "sessionKey": sessionKey,
                "seq": 1,
                "data": ["delta": "Message 1"],
            ] as [String: Any]
        )
        viewModel.handleGatewayEvent(event1)

        // 发送第二个 runId 的消息
        let event2 = GatewayEvent(
            event: "agent",
            payload: [
                "runId": runId2,
                "stream": "assistant",
                "sessionKey": sessionKey,
                "seq": 2,
                "data": ["delta": "Message 2"],
            ] as [String: Any]
        )
        viewModel.handleGatewayEvent(event2)

        // 验证：两条消息都存在且 runId 正确
        XCTAssertEqual(session.messages.count, 2, "应该有 2 条消息")

        let message1 = session.messages.first { $0.runId == runId1 }
        let message2 = session.messages.first { $0.runId == runId2 }

        XCTAssertNotNil(message1, "应该找到 runId1 的消息")
        XCTAssertNotNil(message2, "应该找到 runId2 的消息")
        XCTAssertEqual(message1?.text, "Message 1")
        XCTAssertEqual(message2?.text, "Message 2")
    }

    /// 测试 runId 匹配 - 更新正确的消息
    func testHandleAgentEvent_Assistant_RunId_UpdateCorrect() {
        // 准备
        guard let session = viewModel.sessions.values.first else {
            XCTFail("Session should exist")
            return
        }

        let sessionKey = session.sessionKey
        let runId1 = "test-run-7a"
        let runId2 = "test-run-7b"

        // 创建两条消息
        let event1 = GatewayEvent(
            event: "agent",
            payload: [
                "runId": runId1,
                "stream": "assistant",
                "sessionKey": sessionKey,
                "seq": 1,
                "data": ["delta": "Initial 1"],
            ] as [String: Any]
        )
        viewModel.handleGatewayEvent(event1)

        let event2 = GatewayEvent(
            event: "agent",
            payload: [
                "runId": runId2,
                "stream": "assistant",
                "sessionKey": sessionKey,
                "seq": 2,
                "data": ["delta": "Initial 2"],
            ] as [String: Any]
        )
        viewModel.handleGatewayEvent(event2)

        // 更新 runId1 的消息
        let updateEvent1 = GatewayEvent(
            event: "agent",
            payload: [
                "runId": runId1,
                "stream": "assistant",
                "sessionKey": sessionKey,
                "seq": 3,
                "data": ["text": "Updated 1"],
            ] as [String: Any]
        )
        viewModel.handleGatewayEvent(updateEvent1)

        // 验证：只有 runId1 的消息被更新
        XCTAssertEqual(session.messages.count, 2, "应该还是 2 条消息")

        let message1 = session.messages.first { $0.runId == runId1 }
        let message2 = session.messages.first { $0.runId == runId2 }

        XCTAssertEqual(message1?.text, "Updated 1", "runId1 的消息应该被更新")
        XCTAssertEqual(message2?.text, "Initial 2", "runId2 的消息应该保持不变")
    }

    // MARK: - SessionKey Matching Tests

    /// 测试 sessionKey 匹配 - 错误的 sessionKey 不应该处理
    func testHandleAgentEvent_WrongSessionKey_Ignored() {
        // 准备
        guard let session = viewModel.sessions.values.first else {
            XCTFail("Session should exist")
            return
        }

        let initialCount = session.messages.count

        // 发送错误的 sessionKey
        let event = GatewayEvent(
            event: "agent",
            payload: [
                "runId": "test-run-8",
                "stream": "assistant",
                "sessionKey": "wrong-session-key",
                "seq": 1,
                "data": ["delta": "Should be ignored"],
            ] as [String: Any]
        )

        // 执行
        viewModel.handleGatewayEvent(event)

        // 验证：消息没有被添加
        XCTAssertEqual(session.messages.count, initialCount, "错误的 sessionKey 应该被忽略")
    }

    // MARK: - Lifecycle Event Tests

    /// 测试 lifecycle 事件 - start 和 end
    func testHandleAgentEvent_Lifecycle_StartEnd() {
        // 准备
        guard let session = viewModel.sessions.values.first else {
            XCTFail("Session should exist")
            return
        }

        let runId = "test-run-9"
        let sessionKey = session.sessionKey

        // 发送 lifecycle start
        let startEvent = GatewayEvent(
            event: "agent",
            payload: [
                "runId": runId,
                "stream": "lifecycle",
                "sessionKey": sessionKey,
                "data": ["phase": "start"],
            ] as [String: Any]
        )
        viewModel.handleGatewayEvent(startEvent)

        // 验证：状态变为 thinking
        XCTAssertEqual(session.status, .thinking, "lifecycle start 应该设置状态为 thinking")
        XCTAssertEqual(session.activeRunId, runId, "应该设置 activeRunId")

        // 发送 lifecycle end
        let endEvent = GatewayEvent(
            event: "agent",
            payload: [
                "runId": runId,
                "stream": "lifecycle",
                "sessionKey": sessionKey,
                "data": ["phase": "end"],
            ] as [String: Any]
        )
        viewModel.handleGatewayEvent(endEvent)

        // 验证：状态变为 idle
        XCTAssertEqual(session.status, .idle, "lifecycle end 应该设置状态为 idle")
        XCTAssertNil(session.activeRunId, "应该清除 activeRunId")
    }
}
