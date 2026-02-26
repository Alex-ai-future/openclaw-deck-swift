// ChatMessageTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/26.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation
import Testing

struct ChatMessageTests {

  @Test
  func testMessageInitialization() {
    let message = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Hello",
      timestamp: Date(timeIntervalSince1970: 1_708_123_456)
    )

    #expect(message.id == "msg-1")
    #expect(message.role == .user)
    #expect(message.text == "Hello")
    #expect(message.streaming == nil)
    #expect(message.runId == nil)
  }

  @Test
  func testMessageWithStreaming() {
    let message = ChatMessage(
      id: "msg-2",
      role: .assistant,
      text: "Thinking...",
      timestamp: Date(),
      streaming: true,
      runId: "run-123"
    )

    #expect(message.streaming == true)
    #expect(message.runId == "run-123")
  }

  @Test
  func testMessageEncoding() throws {
    let message = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Hello",
      timestamp: Date(timeIntervalSince1970: 1_708_123_456)
    )

    let data = try JSONEncoder().encode(message)
    let decoded = try JSONDecoder().decode(ChatMessage.self, from: data)

    #expect(decoded.id == message.id)
    #expect(decoded.role == message.role)
    #expect(decoded.text == message.text)
  }

  @Test
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

    #expect(message.id == "msg-1")
    #expect(message.role == .assistant)
    #expect(message.text == "Hello World")
    #expect(message.streaming == true)
    #expect(message.runId == "run-123")
  }

  @Test
  func testIsUserMessage() {
    let userMessage = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Hello",
      timestamp: Date()
    )
    #expect(userMessage.isUserMessage == true)

    let assistantMessage = ChatMessage(
      id: "msg-2",
      role: .assistant,
      text: "Hi",
      timestamp: Date()
    )
    #expect(assistantMessage.isUserMessage == false)
  }

  @Test
  func testIsAssistantMessage() {
    let assistantMessage = ChatMessage(
      id: "msg-1",
      role: .assistant,
      text: "Hi",
      timestamp: Date()
    )
    #expect(assistantMessage.isAssistantMessage == true)

    let userMessage = ChatMessage(
      id: "msg-2",
      role: .user,
      text: "Hello",
      timestamp: Date()
    )
    #expect(userMessage.isAssistantMessage == false)
  }

  @Test
  func testIsSystemMessage() {
    let systemMessage = ChatMessage(
      id: "msg-1",
      role: .system,
      text: "Connected",
      timestamp: Date()
    )
    #expect(systemMessage.isSystemMessage == true)
  }

  @Test
  func testIsStreaming() {
    let streamingMessage = ChatMessage(
      id: "msg-1",
      role: .assistant,
      text: "Thinking...",
      timestamp: Date(),
      streaming: true
    )
    #expect(streamingMessage.isStreaming == true)

    let nonStreamingMessage = ChatMessage(
      id: "msg-2",
      role: .assistant,
      text: "Done",
      timestamp: Date(),
      streaming: false
    )
    #expect(nonStreamingMessage.isStreaming == false)
  }

  @Test
  func testMessageDescription() {
    let userMessage = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Hello",
      timestamp: Date()
    )
    #expect(userMessage.description == "Hello")
  }
}
