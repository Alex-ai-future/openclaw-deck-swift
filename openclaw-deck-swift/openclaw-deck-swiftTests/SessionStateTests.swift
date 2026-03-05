// SessionStateTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/26.
// Copyright © 2026 OpenClaw. All rights reserved.

@testable import openclaw_deck_swift
import XCTest

final class SessionStateTests: XCTestCase {
    func testSessionStateInitialization() {
        let session = SessionState(
            sessionId: "test-session",
            sessionKey: "agent:main:test-session"
        )

        XCTAssertEqual(session.sessionId, "test-session")
        XCTAssertEqual(session.sessionKey, "agent:main:test-session")
        XCTAssertTrue(session.messages.isEmpty)
        XCTAssertFalse(session.messageLoadState == .loaded)
        XCTAssertFalse(session.messageLoadState == .loading)
        XCTAssertEqual(session.status, .idle)
        XCTAssertNil(session.activeRunId)
    }

    func testAppendMessage() {
        let session = SessionState(
            sessionId: "test",
            sessionKey: "agent:main:test"
        )

        let message = ChatMessage(
            id: "msg-1",
            role: .user,
            text: "Hello",
            timestamp: Date()
        )

        session.appendMessage(message)

        XCTAssertEqual(session.messages.count, 1)
        XCTAssertEqual(session.messages.first?.id, "msg-1")
    }

    func testUpdateLastMessage() {
        let session = SessionState(
            sessionId: "test",
            sessionKey: "agent:main:test"
        )

        let message = ChatMessage(
            id: "msg-1",
            role: .assistant,
            text: "Initial",
            timestamp: Date()
        )
        session.appendMessage(message)

        session.updateLastMessage(text: "Updated")

        XCTAssertEqual(session.messages.last?.text, "Updated")
    }

    func testAppendToLastMessage() {
        let session = SessionState(
            sessionId: "test",
            sessionKey: "agent:main:test"
        )

        let message = ChatMessage(
            id: "msg-1",
            role: .assistant,
            text: "Hello",
            timestamp: Date()
        )
        session.appendMessage(message)

        session.appendToLastMessage(text: " World")

        XCTAssertEqual(session.messages.last?.text, "Hello World")
    }

    func testAppendToLastMessage_nonAssistantMessage() {
        let session = SessionState(
            sessionId: "test",
            sessionKey: "agent:main:test"
        )

        let message = ChatMessage(
            id: "msg-1",
            role: .user,
            text: "Hello",
            timestamp: Date()
        )
        session.appendMessage(message)

        session.appendToLastMessage(text: " World")

        XCTAssertEqual(session.messages.last?.text, "Hello")
    }

    func testClearMessages() {
        let session = SessionState(
            sessionId: "test",
            sessionKey: "agent:main:test"
        )

        let message = ChatMessage(
            id: "msg-1",
            role: .user,
            text: "Hello",
            timestamp: Date()
        )
        session.appendMessage(message)
        // session.messageLoadState = .loaded  # Already loaded

        session.clearMessages()

        XCTAssertTrue(session.messages.isEmpty)
        XCTAssertFalse(session.messageLoadState == .loaded)
    }

    func testMessageCount() {
        let session = SessionState(
            sessionId: "test",
            sessionKey: "agent:main:test"
        )

        XCTAssertEqual(session.messageCount, 0)

        session.appendMessage(
            ChatMessage(
                id: "msg-1",
                role: .user,
                text: "Hello",
                timestamp: Date()
            )
        )

        XCTAssertEqual(session.messageCount, 1)
    }

    func testLastMessageAt() {
        let session = SessionState(
            sessionId: "test",
            sessionKey: "agent:main:test"
        )

        XCTAssertNil(session.lastMessageAt)

        let now = Date()
        session.appendMessage(
            ChatMessage(
                id: "msg-1",
                role: .user,
                text: "Hello",
                timestamp: now
            )
        )

        XCTAssertEqual(session.lastMessageAt, now)
    }

    func testSessionStatusTransitions() {
        let session = SessionState(
            sessionId: "test",
            sessionKey: "agent:main:test"
        )

        XCTAssertEqual(session.status, .idle)

        session.status = .thinking
        XCTAssertEqual(session.status, .thinking)

        session.status = .streaming
        XCTAssertEqual(session.status, .streaming)

        session.status = .error("Test error")
        XCTAssertEqual(session.status, .error("Test error"))

        session.status = .idle
        XCTAssertEqual(session.status, .idle)
    }

    func testStatusEquatable() {
        let status1: SessionStatus = .idle
        let status2: SessionStatus = .idle
        let status3: SessionStatus = .thinking
        let status4: SessionStatus = .error("Error 1")
        let status5: SessionStatus = .error("Error 2")

        XCTAssertEqual(status1, status2)
        XCTAssertNotEqual(status1, status3)
        XCTAssertNotEqual(status4, status5)
    }
}
