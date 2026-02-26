// ChatMessageTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/26.
// Copyright © 2026 OpenClaw. All rights reserved.

import XCTest

@testable import openclaw_deck_swift

final class ChatMessageTests: XCTestCase {

  func testMessageInitialization() {
    let message = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Hello",
      timestamp: Date(timeIntervalSince1970: 1_708_123_456)
    )

    XCTAssertEqual(message.id, "msg-1")
    XCTAssertEqual(message.role, .user)
    XCTAssertEqual(message.text, "Hello")
    XCTAssertNil(message.streaming)
    XCTAssertNil(message.runId)
  }

  func testMessageWithStreaming() {
    let message = ChatMessage(
      id: "msg-2",
      role: .assistant,
      text: "Thinking...",
      timestamp: Date(),
      streaming: true,
      runId: "run-123"
    )

    XCTAssertEqual(message.streaming, true)
    XCTAssertEqual(message.runId, "run-123")
  }

  func testMessageEncoding() throws {
    let message = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Hello",
      timestamp: Date(timeIntervalSince1970: 1_708_123_456)
    )

    let data = try JSONEncoder().encode(message)
    let decoded = try JSONDecoder().decode(ChatMessage.self, from: data)

    XCTAssertEqual(decoded.id, message.id)
    XCTAssertEqual(decoded.role, message.role)
    XCTAssertEqual(decoded.text, message.text)
  }

  func testMessageDecoding() throws {
    let json = """
      {
        "id": "msg-1",
        "role": "assistant",
        "text": "Hello World",
        "timestamp": 1708123456,
        "streaming": true,
        "runId": "run-123"
      }
      """
    let data = json.data(using: .utf8)!
    let message = try JSONDecoder().decode(ChatMessage.self, from: data)

    XCTAssertEqual(message.id, "msg-1")
    XCTAssertEqual(message.role, .assistant)
    XCTAssertEqual(message.text, "Hello World")
    XCTAssertEqual(message.streaming, true)
    XCTAssertEqual(message.runId, "run-123")
  }

  func testIsUserMessage() {
    let userMessage = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Hello",
      timestamp: Date()
    )
    XCTAssertTrue(userMessage.isUserMessage)

    let assistantMessage = ChatMessage(
      id: "msg-2",
      role: .assistant,
      text: "Hi",
      timestamp: Date()
    )
    XCTAssertFalse(assistantMessage.isUserMessage)
  }

  func testIsAssistantMessage() {
    let assistantMessage = ChatMessage(
      id: "msg-1",
      role: .assistant,
      text: "Hi",
      timestamp: Date()
    )
    XCTAssertTrue(assistantMessage.isAssistantMessage)

    let userMessage = ChatMessage(
      id: "msg-2",
      role: .user,
      text: "Hello",
      timestamp: Date()
    )
    XCTAssertFalse(userMessage.isAssistantMessage)
  }

  func testIsSystemMessage() {
    let systemMessage = ChatMessage(
      id: "msg-1",
      role: .system,
      text: "Connected",
      timestamp: Date()
    )
    XCTAssertTrue(systemMessage.isSystemMessage)
  }

  func testIsStreaming() {
    let streamingMessage = ChatMessage(
      id: "msg-1",
      role: .assistant,
      text: "Thinking...",
      timestamp: Date(),
      streaming: true
    )
    XCTAssertTrue(streamingMessage.isStreaming)

    let nonStreamingMessage = ChatMessage(
      id: "msg-2",
      role: .assistant,
      text: "Done",
      timestamp: Date(),
      streaming: false
    )
    XCTAssertFalse(nonStreamingMessage.isStreaming)
  }

  func testMessageDescription() {
    let userMessage = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Hello",
      timestamp: Date()
    )
    XCTAssertEqual(userMessage.description, "Hello")
  }
}
