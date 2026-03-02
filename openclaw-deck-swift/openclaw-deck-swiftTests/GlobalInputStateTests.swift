// GlobalInputStateTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/27/26.
// Copyright © 2026 OpenClaw. All rights reserved.

@testable import openclaw_deck_swift
import SwiftUI
import XCTest

@MainActor
final class GlobalInputStateTests: XCTestCase {
    var inputState: GlobalInputState!
    var viewModel: DeckViewModel!
    var mockStorage: MockUserDefaultsStorage!

    override func setUp() async throws {
        try await super.setUp()
        inputState = GlobalInputState()
        mockStorage = MockUserDefaultsStorage()
        let testDIContainer = DIContainer(
            storage: mockStorage,
            gatewayClientFactory: { _, _ in MockGatewayClient() },
            cloudflareKV: MockCloudflareKV(),
            globalInputStateFactory: { GlobalInputState() }
        )
        viewModel = DeckViewModel(diContainer: testDIContainer)
    }

    override func tearDown() async throws {
        inputState = nil
        viewModel = nil
        mockStorage = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization_defaultValues() {
        XCTAssertEqual(inputState.inputText, "")
        XCTAssertEqual(inputState.textHeight, 36)
        XCTAssertNil(inputState.selectedSessionId)
        XCTAssertEqual(inputState.inputWidth, 300)
        XCTAssertNotNil(inputState.speechRecognizer)
    }

    // MARK: - Input Text Tests

    func testInputText_setAndGet() {
        inputState.inputText = "Hello World"
        XCTAssertEqual(inputState.inputText, "Hello World")
    }

    func testInputText_clear() {
        inputState.inputText = "Test"
        inputState.inputText = ""
        XCTAssertEqual(inputState.inputText, "")
    }

    func testInputText_multiline() {
        let multilineText = """
        Line 1
        Line 2
        Line 3
        """
        inputState.inputText = multilineText
        XCTAssertEqual(inputState.inputText, multilineText)
    }

    // MARK: - Selected Session ID Tests

    func testSelectedSessionId_setAndGet() {
        inputState.selectedSessionId = "test-session-123"
        XCTAssertEqual(inputState.selectedSessionId, "test-session-123")
    }

    func testSelectedSessionId_clear() {
        inputState.selectedSessionId = "session-1"
        inputState.selectedSessionId = nil
        XCTAssertNil(inputState.selectedSessionId)
    }

    // MARK: - Input Width Tests

    func testInputWidth_customValue() {
        inputState.inputWidth = 500
        XCTAssertEqual(inputState.inputWidth, 500)
    }

    // MARK: - Clear Input Tests

    func testClearInput_resetsText() {
        inputState.inputText = "Test message"
        inputState.clearInput()
        XCTAssertEqual(inputState.inputText, "")
    }

    func testClearInput_resetsHeight() {
        inputState.textHeight = 100
        inputState.clearInput()
        XCTAssertEqual(inputState.textHeight, 36)
    }

    func testClearInput_clearsAll() {
        inputState.inputText = "Test"
        inputState.textHeight = 80
        inputState.clearInput()
        XCTAssertEqual(inputState.inputText, "")
        XCTAssertEqual(inputState.textHeight, 36)
    }

    // MARK: - Calculate Text Height Tests

    func testCalculateTextHeight_emptyText() {
        inputState.inputText = ""
        inputState.inputWidth = 300
        inputState.calculateTextHeight()
        // 空文本应该保持最小高度
        XCTAssertEqual(inputState.textHeight, 36)
    }

    func testCalculateTextHeight_shortText() {
        inputState.inputText = "Hello"
        inputState.inputWidth = 300
        inputState.calculateTextHeight()
        // 短文本应该是最小高度
        XCTAssertEqual(inputState.textHeight, 36)
    }

    func testCalculateTextHeight_maxHeightLimit() {
        let veryLongText = String(repeating: "Line\n", count: 100)
        inputState.inputText = veryLongText
        inputState.inputWidth = 300
        inputState.calculateTextHeight()
        // 高度不应该超过最大值 150
        XCTAssertLessThanOrEqual(inputState.textHeight, 150)
    }

    func testCalculateTextHeight_widthAffectsHeight() {
        let text = "This is a test text that will wrap differently based on width"

        // 窄宽度
        inputState.inputText = text
        inputState.inputWidth = 200
        inputState.calculateTextHeight()
        let narrowHeight = inputState.textHeight

        // 宽宽度
        inputState.inputText = text
        inputState.inputWidth = 600
        inputState.calculateTextHeight()
        let wideHeight = inputState.textHeight

        // 窄宽度应该导致更大的高度（因为需要更多行）
        XCTAssertGreaterThanOrEqual(narrowHeight, wideHeight)
    }

    // MARK: - Send Message Tests

    func testSendMessage_success() async {
        // 准备测试数据
        inputState.inputText = "Test message"
        inputState.selectedSessionId = "test-session"

        let session = SessionState(
            sessionId: "test-session",
            sessionKey: "agent:main:test-session"
        )

        // 发送消息
        await inputState.sendMessage(to: session, viewModel: viewModel)

        // 验证输入已清空（主要验证发送流程完成）
        XCTAssertEqual(inputState.inputText, "")
    }

    func testSendMessage_emptyText_doesNotSend() async {
        inputState.inputText = ""
        inputState.selectedSessionId = "test-session"

        let session = SessionState(
            sessionId: "test-session",
            sessionKey: "agent:main:test-session"
        )

        let initialMessageCount = session.messages.count

        await inputState.sendMessage(to: session, viewModel: viewModel)

        // 空文本不应该发送，消息数量不变
        XCTAssertEqual(session.messages.count, initialMessageCount)
    }

    func testSendMessage_clearsInputAfterSending() async {
        inputState.inputText = "Test message"
        inputState.selectedSessionId = "test-session"

        let session = SessionState(
            sessionId: "test-session",
            sessionKey: "agent:main:test-session"
        )

        await inputState.sendMessage(to: session, viewModel: viewModel)

        // 发送后输入应该被清空
        XCTAssertEqual(inputState.inputText, "")
        XCTAssertEqual(inputState.textHeight, 36)
    }

    func testSendMessage_stopsSpeechRecognizer() async {
        inputState.inputText = "Test message"
        inputState.selectedSessionId = "test-session"

        // 模拟语音识别正在监听
        inputState.speechRecognizer.isListening = true

        let session = SessionState(
            sessionId: "test-session",
            sessionKey: "agent:main:test-session"
        )

        await inputState.sendMessage(to: session, viewModel: viewModel)

        // 发送后语音识别应该停止
        XCTAssertFalse(inputState.speechRecognizer.isListening)
    }

    func testSendMessage_whenNotListening() async {
        inputState.inputText = "Test message"
        inputState.selectedSessionId = "test-session"

        // 语音识别未监听
        inputState.speechRecognizer.isListening = false

        let session = SessionState(
            sessionId: "test-session",
            sessionKey: "agent:main:test-session"
        )

        // 不应该崩溃
        await inputState.sendMessage(to: session, viewModel: viewModel)

        XCTAssertFalse(inputState.speechRecognizer.isListening)
    }

    func testClearInput_doesNotClearSelectedSession() {
        inputState.selectedSessionId = "test-session"
        inputState.inputText = "Test"

        inputState.clearInput()

        // selectedSessionId 应该保留
        XCTAssertEqual(inputState.selectedSessionId, "test-session")
        XCTAssertEqual(inputState.inputText, "")
    }

    func testMultipleInputChanges() {
        inputState.inputText = "First"
        XCTAssertEqual(inputState.inputText, "First")

        inputState.inputText = "Second"
        XCTAssertEqual(inputState.inputText, "Second")

        inputState.inputText = "Third"
        XCTAssertEqual(inputState.inputText, "Third")
    }

    func testSessionSwitch() {
        inputState.selectedSessionId = "session-1"
        inputState.inputText = "Message for session 1"

        XCTAssertEqual(inputState.selectedSessionId, "session-1")
        XCTAssertEqual(inputState.inputText, "Message for session 1")

        // 切换到另一个 Session
        inputState.selectedSessionId = "session-2"
        inputState.inputText = "Message for session 2"

        XCTAssertEqual(inputState.selectedSessionId, "session-2")
        XCTAssertEqual(inputState.inputText, "Message for session 2")
    }
}
