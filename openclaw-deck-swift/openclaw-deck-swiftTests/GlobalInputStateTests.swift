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

    override func setUp() async throws {
        try await super.setUp()
        inputState = GlobalInputState()
        viewModel = DeckViewModel()
    }

    override func tearDown() async throws {
        inputState = nil
        viewModel = nil
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
        XCTAssertEqual(inputState.textHeight, 36)
    }

    func testCalculateTextHeight_shortText() {
        inputState.inputText = "Hello"
        inputState.inputWidth = 300
        inputState.calculateTextHeight()
        XCTAssertEqual(inputState.textHeight, 36)
    }

    func testCalculateTextHeight_maxHeightLimit() {
        let veryLongText = String(repeating: "Line\n", count: 100)
        inputState.inputText = veryLongText
        inputState.inputWidth = 300
        inputState.calculateTextHeight()
        XCTAssertLessThanOrEqual(inputState.textHeight, 150)
    }

    func testCalculateTextHeight_widthAffectsHeight() {
        let text = "This is a test text that will wrap differently based on width"

        inputState.inputText = text
        inputState.inputWidth = 200
        inputState.calculateTextHeight()
        let narrowHeight = inputState.textHeight

        inputState.inputText = text
        inputState.inputWidth = 600
        inputState.calculateTextHeight()
        let wideHeight = inputState.textHeight

        XCTAssertGreaterThanOrEqual(narrowHeight, wideHeight)
    }

    // MARK: - Send Message Tests

    func testSendMessage_success() async {
        inputState.inputText = "Test message"
        inputState.selectedSessionId = "test-session"

        let session = SessionState(
            sessionId: "test-session",
            sessionKey: "agent:main:test-session"
        )

        await inputState.sendMessage(to: session, viewModel: viewModel)

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

        XCTAssertEqual(inputState.inputText, "")
        XCTAssertEqual(inputState.textHeight, 36)
    }

    func testSendMessage_stopsSpeechRecognizer() async {
        inputState.inputText = "Test message"
        inputState.selectedSessionId = "test-session"

        inputState.speechRecognizer.isListening = true

        let session = SessionState(
            sessionId: "test-session",
            sessionKey: "agent:main:test-session"
        )

        await inputState.sendMessage(to: session, viewModel: viewModel)

        XCTAssertFalse(inputState.speechRecognizer.isListening)
    }

    func testSendMessage_whenNotListening() async {
        inputState.inputText = "Test message"
        inputState.selectedSessionId = "test-session"

        inputState.speechRecognizer.isListening = false

        let session = SessionState(
            sessionId: "test-session",
            sessionKey: "agent:main:test-session"
        )

        await inputState.sendMessage(to: session, viewModel: viewModel)

        XCTAssertFalse(inputState.speechRecognizer.isListening)
    }

    func testClearInput_doesNotClearSelectedSession() {
        inputState.selectedSessionId = "test-session"
        inputState.inputText = "Test"

        inputState.clearInput()

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

        inputState.selectedSessionId = "session-2"
        inputState.inputText = "Message for session 2"

        XCTAssertEqual(inputState.selectedSessionId, "session-2")
        XCTAssertEqual(inputState.inputText, "Message for session 2")
    }
}
