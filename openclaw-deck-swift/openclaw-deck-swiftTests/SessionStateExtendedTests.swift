// SessionStateExtendedTests.swift
// OpenClaw Deck Swift
//
// SessionState 扩展测试

@testable import openclaw_deck_swift
import XCTest

@MainActor
final class SessionStateExtendedTests: XCTestCase {
    // MARK: - SessionStatus Tests

    func testSessionStatus_idle() {
        let status: SessionStatus = .idle
        XCTAssertEqual(status, .idle)
    }

    func testSessionStatus_thinking() {
        let status: SessionStatus = .thinking
        XCTAssertEqual(status, .thinking)
    }

    func testSessionStatus_streaming() {
        let status: SessionStatus = .streaming
        XCTAssertEqual(status, .streaming)
    }

    func testSessionStatus_error() {
        let status: SessionStatus = .error("Test error")

        if case let .error(message) = status {
            XCTAssertEqual(message, "Test error")
        } else {
            XCTFail("Expected error status")
        }
    }

    func testSessionStatus_equatable() {
        let status1: SessionStatus = .idle
        let status2: SessionStatus = .idle
        let status3: SessionStatus = .thinking

        XCTAssertEqual(status1, status2)
        XCTAssertNotEqual(status1, status3)
    }

    func testSessionStatus_errorEquatable() {
        let status1: SessionStatus = .error("Error 1")
        let status2: SessionStatus = .error("Error 1")
        let status3: SessionStatus = .error("Error 2")

        XCTAssertEqual(status1, status2)
        XCTAssertNotEqual(status1, status3)
    }

    // MARK: - SessionState Initialization Tests

    func testSessionState_initialization() {
        let session = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        XCTAssertEqual(session.sessionId, "session-1")
        XCTAssertEqual(session.sessionKey, "key-1")
        XCTAssertEqual(session.id, "session-1") // Identifiable
        XCTAssertTrue(session.messages.isEmpty)
        XCTAssertFalse(session.messageLoadState == .loaded)
        XCTAssertFalse(session.messageLoadState == .loading)
        XCTAssertEqual(session.status, .idle)
        XCTAssertNil(session.activeRunId)
        XCTAssertFalse(session.status == .thinking)
        XCTAssertFalse(session.hasUnreadMessage)
        XCTAssertNil(session.context)
        XCTAssertNil(session.lastMessageAt)
        XCTAssertEqual(session.messageCount, 0)
    }

    func testSessionState_initializationWithContext() {
        let session = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1",
            context: "Test context"
        )

        XCTAssertEqual(session.sessionId, "session-1")
        XCTAssertEqual(session.sessionKey, "key-1")
        XCTAssertEqual(session.context, "Test context")
    }

    // MARK: - SessionState Hashable Tests

    func testSessionState_hashable_sameSession() {
        let session1 = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        let session2 = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        XCTAssertEqual(session1, session2)
        XCTAssertEqual(session1.hashValue, session2.hashValue)
    }

    func testSessionState_hashable_differentSessionId() {
        let session1 = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        let session2 = SessionState(
            sessionId: "session-2",
            sessionKey: "key-1"
        )

        XCTAssertNotEqual(session1, session2)
    }

    func testSessionState_hashable_differentSessionKey() {
        let session1 = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        let session2 = SessionState(
            sessionId: "session-1",
            sessionKey: "key-2"
        )

        XCTAssertNotEqual(session1, session2)
    }

    func testSessionState_inSet() {
        let session1 = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        let session2 = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        let sessionSet: Set<SessionState> = [session1, session2]

        // 相同的 session 应该只保留一个
        XCTAssertEqual(sessionSet.count, 1)
    }

    func testSessionState_asDictionaryKey() {
        let session1 = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        let session2 = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        var sessionDict: [SessionState: String] = [:]
        sessionDict[session1] = "Value 1"
        sessionDict[session2] = "Value 2"

        // 相同的 session 应该覆盖
        XCTAssertEqual(sessionDict.count, 1)
        XCTAssertEqual(sessionDict[session1], "Value 2")
    }

    // MARK: - Message Management Tests

    func testAppendMessage() {
        let session = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        let message = ChatMessage(
            id: "msg-1",
            role: .user,
            text: "Hello",
            timestamp: Date()
        )

        session.appendMessage(message)

        XCTAssertEqual(session.messages.count, 1)
        XCTAssertEqual(session.messages[0].text, "Hello")
    }

    func testAppendMultipleMessages() {
        let session = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        let message1 = ChatMessage(
            id: "msg-1",
            role: .user,
            text: "Hello",
            timestamp: Date()
        )

        let message2 = ChatMessage(
            id: "msg-2",
            role: .assistant,
            text: "Hi",
            timestamp: Date()
        )

        session.appendMessage(message1)
        session.appendMessage(message2)

        XCTAssertEqual(session.messages.count, 2)
        XCTAssertEqual(session.messages[0].role, .user)
        XCTAssertEqual(session.messages[1].role, .assistant)
    }

    func testUpdateLastMessage() {
        let session = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        let message = ChatMessage(
            id: "msg-1",
            role: .assistant,
            text: "Initial",
            timestamp: Date()
        )

        session.appendMessage(message)
        session.updateLastMessage(text: "Updated")

        XCTAssertEqual(session.messages.count, 1)
        XCTAssertEqual(session.messages[0].text, "Updated")
    }

    func testUpdateLastMessage_emptyMessages() {
        let session = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        // 没有消息时更新应该不会崩溃
        session.updateLastMessage(text: "Updated")

        XCTAssertEqual(session.messages.count, 0)
    }

    func testAppendToLastMessage() {
        let session = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        let message = ChatMessage(
            id: "msg-1",
            role: .assistant,
            text: "Hello",
            timestamp: Date()
        )

        session.appendMessage(message)
        session.appendToLastMessage(text: " World")

        XCTAssertEqual(session.messages.count, 1)
        XCTAssertEqual(session.messages[0].text, "Hello World")
    }

    func testAppendToLastMessage_nonAssistantMessage() {
        let session = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        let userMessage = ChatMessage(
            id: "msg-1",
            role: .user,
            text: "Hello",
            timestamp: Date()
        )

        session.appendMessage(userMessage)
        session.appendToLastMessage(text: " World")

        // 最后一条不是 assistant 消息，不应该追加
        XCTAssertEqual(session.messages.count, 1)
        XCTAssertEqual(session.messages[0].text, "Hello")
    }

    func testAppendToLastMessage_emptyMessages() {
        let session = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        // 没有消息时追加应该不会崩溃
        session.appendToLastMessage(text: "Text")

        XCTAssertEqual(session.messages.count, 0)
    }

    func testClearMessages() {
        let session = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        let message = ChatMessage(
            id: "msg-1",
            role: .user,
            text: "Hello",
            timestamp: Date()
        )

        session.appendMessage(message)
        session.messageLoadState = .loaded

        XCTAssertEqual(session.messages.count, 1)
        XCTAssertTrue(session.messageLoadState == .loaded)

        session.clearMessages()

        XCTAssertTrue(session.messages.isEmpty)
        XCTAssertFalse(session.messageLoadState == .loaded)
    }

    // MARK: - Computed Property Tests

    func testLastMessageAt_withMessages() {
        let session = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        let now = Date()
        let message = ChatMessage(
            id: "msg-1",
            role: .user,
            text: "Hello",
            timestamp: now
        )

        session.appendMessage(message)

        XCTAssertEqual(session.lastMessageAt, now)
    }

    func testLastMessageAt_withoutMessages() {
        let session = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        XCTAssertNil(session.lastMessageAt)
    }

    func testMessageCount() {
        let session = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
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

        session.appendMessage(
            ChatMessage(
                id: "msg-2",
                role: .assistant,
                text: "Hi",
                timestamp: Date()
            )
        )

        XCTAssertEqual(session.messageCount, 2)
    }

    // MARK: - Status Tests

    func testStatusTransitions() {
        let session = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        // Initial
        XCTAssertEqual(session.status, .idle)

        // To thinking
        session.status = .thinking
        XCTAssertEqual(session.status, .thinking)

        // To streaming
        session.status = .streaming
        XCTAssertEqual(session.status, .streaming)

        // To error
        session.status = .error("Test error")

        if case let .error(message) = session.status {
            XCTAssertEqual(message, "Test error")
        }

        // Back to idle
        session.status = .idle
        XCTAssertEqual(session.status, .idle)
    }

    func testActiveRunId() {
        let session = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        XCTAssertNil(session.activeRunId)

        session.activeRunId = "run-123"
        XCTAssertEqual(session.activeRunId, "run-123")

        session.activeRunId = nil
        XCTAssertNil(session.activeRunId)
    }

    func testIsProcessing() {
        let session = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        XCTAssertFalse(session.status == .thinking)

        session.status = .thinking
        XCTAssertTrue(session.status == .thinking)

        session.status = .idle
        XCTAssertFalse(session.status == .thinking)
    }

    func testHasUnreadMessage() {
        let session = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        XCTAssertFalse(session.hasUnreadMessage)

        session.hasUnreadMessage = true
        XCTAssertTrue(session.hasUnreadMessage)

        session.hasUnreadMessage = false
        XCTAssertFalse(session.hasUnreadMessage)
    }

    // MARK: - Edge Cases

    func testAppendMessage_withNilText() {
        let session = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        let message = ChatMessage(
            id: "msg-1",
            role: .user,
            text: "",
            timestamp: Date()
        )

        session.appendMessage(message)

        XCTAssertEqual(session.messages.count, 1)
        XCTAssertEqual(session.messages[0].text, "")
    }

    func testUpdateLastMessage_withLongText() {
        let session = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        let longText = String(repeating: "A", count: 10000)

        session.appendMessage(
            ChatMessage(
                id: "msg-1",
                role: .assistant,
                text: "Initial",
                timestamp: Date()
            )
        )

        session.updateLastMessage(text: longText)

        XCTAssertEqual(session.messages[0].text.count, 10000)
    }

    func testMultipleStatusChanges() {
        let session = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        // 快速切换多次状态
        for _ in 0 ..< 100 {
            session.status = .thinking
            session.status = .streaming
            session.status = .idle
        }

        XCTAssertEqual(session.status, .idle)
    }

    // MARK: - Performance Tests

    func testAppendMessage_performance() {
        let session = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        self.measure {
            for i in 0 ..< 100 {
                session.appendMessage(
                    ChatMessage(
                        id: "msg-\(i)",
                        role: .user,
                        text: "Message \(i)",
                        timestamp: Date()
                    )
                )
            }
        }
    }

    func testClearMessages_performance() {
        let session = SessionState(
            sessionId: "session-1",
            sessionKey: "key-1"
        )

        // 先添加一些消息
        for i in 0 ..< 100 {
            session.appendMessage(
                ChatMessage(
                    id: "msg-\(i)",
                    role: .user,
                    text: "Message \(i)",
                    timestamp: Date()
                )
            )
        }

        self.measure {
            session.clearMessages()

            // 重新添加
            for i in 0 ..< 100 {
                session.appendMessage(
                    ChatMessage(
                        id: "msg-\(i)",
                        role: .user,
                        text: "Message \(i)",
                        timestamp: Date()
                    )
                )
            }
        }
    }
}
