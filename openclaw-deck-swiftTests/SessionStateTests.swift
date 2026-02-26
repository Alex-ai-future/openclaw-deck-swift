// SessionStateTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/26.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation
import Testing

@Suite
struct SessionStateTests {

  @Test
  func testSessionStateInitialization() {
    let session = SessionState(
      sessionId: "test-session",
      sessionKey: "agent:main:test-session"
    )

    #expect(session.sessionId == "test-session")
    #expect(session.sessionKey == "agent:main:test-session")
    #expect(session.messages.isEmpty == true)
    #expect(session.historyLoaded == false)
    #expect(session.isHistoryLoading == false)
    #expect(session.status == .idle)
    #expect(session.activeRunId == nil)
  }

  @Test
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

    #expect(session.messages.count == 1)
    #expect(session.messages.first?.id == "msg-1")
  }

  @Test
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

    #expect(session.messages.last?.text == "Updated")
  }

  @Test
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

    #expect(session.messages.last?.text == "Hello World")
  }

  @Test
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

    // 如果最后一条消息不是 assistant 消息，appendToLastMessage 不应该修改任何内容
    session.appendToLastMessage(text: " World")

    #expect(session.messages.last?.text == "Hello")
  }

  @Test
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
    session.historyLoaded = true

    session.clearMessages()

    #expect(session.messages.isEmpty == true)
    #expect(session.historyLoaded == false)
  }

  @Test
  func testMessageCount() {
    let session = SessionState(
      sessionId: "test",
      sessionKey: "agent:main:test"
    )

    #expect(session.messageCount == 0)

    session.appendMessage(
      ChatMessage(
        id: "msg-1",
        role: .user,
        text: "Hello",
        timestamp: Date()
      ))

    #expect(session.messageCount == 1)
  }

  @Test
  func testLastMessageAt() {
    let session = SessionState(
      sessionId: "test",
      sessionKey: "agent:main:test"
    )

    #expect(session.lastMessageAt == nil)

    let now = Date()
    session.appendMessage(
      ChatMessage(
        id: "msg-1",
        role: .user,
        text: "Hello",
        timestamp: now
      ))

    #expect(session.lastMessageAt == now)
  }

  @Test
  func testSessionStatusTransitions() {
    let session = SessionState(
      sessionId: "test",
      sessionKey: "agent:main:test"
    )

    // 初始状态为 idle
    #expect(session.status == .idle)

    // 转换到 thinking
    session.status = .thinking
    #expect(session.status == .thinking)

    // 转换到 streaming
    session.status = .streaming
    #expect(session.status == .streaming)

    // 转换到 error
    session.status = .error("Test error")
    #expect(session.status == .error("Test error"))

    // 恢复到 idle
    session.status = .idle
    #expect(session.status == .idle)
  }

  @Test
  func testStatusEquatable() {
    let status1: SessionStatus = .idle
    let status2: SessionStatus = .idle
    let status3: SessionStatus = .thinking
    let status4: SessionStatus = .error("Error 1")
    let status5: SessionStatus = .error("Error 2")

    #expect(status1 == status2)
    #expect(status1 != status3)
    #expect(status4 != status5)
  }
}
