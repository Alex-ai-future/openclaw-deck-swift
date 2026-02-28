// ChatMessageExtendedTests.swift
// OpenClaw Deck Swift
//
// ChatMessage 扩展测试

import XCTest

@testable import openclaw_deck_swift

final class ChatMessageExtendedTests: XCTestCase {

  // MARK: - Role Tests

  func testMessageRole_rawValue() {
    XCTAssertEqual(MessageRole.user.rawValue, "user")
    XCTAssertEqual(MessageRole.assistant.rawValue, "assistant")
    XCTAssertEqual(MessageRole.system.rawValue, "system")
  }

  func testMessageRole_fromRawValue() {
    XCTAssertEqual(MessageRole(rawValue: "user"), .user)
    XCTAssertEqual(MessageRole(rawValue: "assistant"), .assistant)
    XCTAssertEqual(MessageRole(rawValue: "system"), .system)
    XCTAssertNil(MessageRole(rawValue: "invalid"))
  }

  func testMessageRole_caseInsensitive() {
    // 原始值匹配是大小写敏感的
    XCTAssertNil(MessageRole(rawValue: "User"))
    XCTAssertNil(MessageRole(rawValue: "USER"))
  }

  // MARK: - ChatMessage Initialization Tests

  func testChatMessage_defaultValues() {
    let message = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Hello",
      timestamp: Date()
    )

    XCTAssertEqual(message.id, "msg-1")
    XCTAssertEqual(message.role, .user)
    XCTAssertEqual(message.text, "Hello")
    XCTAssertFalse(message.streaming)
    XCTAssertFalse(message.thinking)
    XCTAssertNil(message.toolUse)
    XCTAssertNil(message.runId)
    XCTAssertFalse(message.isLoaded)
  }

  func testChatMessage_withAllParameters() {
    let toolUse = ToolUse(name: "test_tool", input: ["key": "value"])
    let message = ChatMessage(
      id: "msg-1",
      role: .assistant,
      text: "Response",
      timestamp: Date(),
      streaming: true,
      thinking: false,
      toolUse: toolUse,
      runId: "run-123",
      isLoaded: true
    )

    XCTAssertEqual(message.id, "msg-1")
    XCTAssertEqual(message.role, .assistant)
    XCTAssertEqual(message.text, "Response")
    XCTAssertTrue(message.streaming)
    XCTAssertFalse(message.thinking)
    XCTAssertNotNil(message.toolUse)
    XCTAssertEqual(message.runId, "run-123")
    XCTAssertTrue(message.isLoaded)
  }

  // MARK: - ChatMessage Description Tests

  func testChatMessage_description_user() {
    let message = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Hello",
      timestamp: Date()
    )

    let description = message.description
    XCTAssertTrue(description.contains("user"))
    XCTAssertTrue(description.contains("Hello"))
  }

  func testChatMessage_description_assistant() {
    let message = ChatMessage(
      id: "msg-1",
      role: .assistant,
      text: "Response",
      timestamp: Date()
    )

    let description = message.description
    XCTAssertTrue(description.contains("assistant"))
    XCTAssertTrue(description.contains("Response"))
  }

  func testChatMessage_description_system() {
    let message = ChatMessage(
      id: "msg-1",
      role: .system,
      text: "System message",
      timestamp: Date()
    )

    let description = message.description
    XCTAssertTrue(description.contains("system"))
    XCTAssertTrue(description.contains("System message"))
  }

  func testChatMessage_description_withStreaming() {
    let message = ChatMessage(
      id: "msg-1",
      role: .assistant,
      text: "Streaming",
      timestamp: Date(),
      streaming: true
    )

    let description = message.description
    XCTAssertTrue(description.contains("streaming"))
  }

  func testChatMessage_description_withThinking() {
    let message = ChatMessage(
      id: "msg-1",
      role: .assistant,
      text: "Thinking",
      timestamp: Date(),
      thinking: true
    )

    let description = message.description
    XCTAssertTrue(description.contains("thinking"))
  }

  func testChatMessage_description_withToolUse() {
    let toolUse = ToolUse(name: "test_tool", input: ["key": "value"])
    let message = ChatMessage(
      id: "msg-1",
      role: .assistant,
      text: "Using tool",
      timestamp: Date(),
      toolUse: toolUse
    )

    let description = message.description
    XCTAssertTrue(description.contains("tool"))
  }

  // MARK: - ChatMessage Encoding/Decoding Tests

  func testChatMessage_encoding() throws {
    let message = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Hello",
      timestamp: Date()
    )

    let encoder = JSONEncoder()
    let jsonData = try encoder.encode(message)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(ChatMessage.self, from: jsonData)

    XCTAssertEqual(decoded.id, "msg-1")
    XCTAssertEqual(decoded.role, .user)
    XCTAssertEqual(decoded.text, "Hello")
  }

  func testChatMessage_decoding_withAllFields() throws {
    let json = """
      {
        "id": "msg-1",
        "role": "assistant",
        "text": "Response",
        "timestamp": "2024-01-01T00:00:00Z",
        "streaming": true,
        "thinking": false,
        "runId": "run-123",
        "isLoaded": true
      }
      """

    let data = Data(json.utf8)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let message = try decoder.decode(ChatMessage.self, from: data)

    XCTAssertEqual(message.id, "msg-1")
    XCTAssertEqual(message.role, .assistant)
    XCTAssertEqual(message.text, "Response")
    XCTAssertTrue(message.streaming)
    XCTAssertFalse(message.thinking)
    XCTAssertEqual(message.runId, "run-123")
    XCTAssertTrue(message.isLoaded)
  }

  func testChatMessage_decoding_withMinimalFields() throws {
    let json = """
      {
        "id": "msg-1",
        "role": "user",
        "text": "Hello",
        "timestamp": "2024-01-01T00:00:00Z"
      }
      """

    let data = Data(json.utf8)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let message = try decoder.decode(ChatMessage.self, from: data)

    XCTAssertEqual(message.id, "msg-1")
    XCTAssertEqual(message.role, .user)
    XCTAssertEqual(message.text, "Hello")
    XCTAssertFalse(message.streaming)
    XCTAssertFalse(message.thinking)
    XCTAssertNil(message.runId)
    XCTAssertFalse(message.isLoaded)
  }

  // MARK: - ChatMessage Equatable Tests

  func testChatMessage_equality_sameValues() {
    let timestamp = Date()
    let message1 = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Hello",
      timestamp: timestamp
    )

    let message2 = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Hello",
      timestamp: timestamp
    )

    XCTAssertEqual(message1, message2)
  }

  func testChatMessage_equality_differentID() {
    let timestamp = Date()
    let message1 = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Hello",
      timestamp: timestamp
    )

    let message2 = ChatMessage(
      id: "msg-2",
      role: .user,
      text: "Hello",
      timestamp: timestamp
    )

    XCTAssertNotEqual(message1, message2)
  }

  func testChatMessage_equality_differentRole() {
    let timestamp = Date()
    let message1 = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Hello",
      timestamp: timestamp
    )

    let message2 = ChatMessage(
      id: "msg-1",
      role: .assistant,
      text: "Hello",
      timestamp: timestamp
    )

    XCTAssertNotEqual(message1, message2)
  }

  func testChatMessage_equality_differentText() {
    let timestamp = Date()
    let message1 = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Hello",
      timestamp: timestamp
    )

    let message2 = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Hi",
      timestamp: timestamp
    )

    XCTAssertNotEqual(message1, message2)
  }

  // MARK: - ChatMessage Helper Method Tests

  func testIsUserMessage() {
    let userMessage = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Hello",
      timestamp: Date()
    )

    let assistantMessage = ChatMessage(
      id: "msg-2",
      role: .assistant,
      text: "Response",
      timestamp: Date()
    )

    XCTAssertTrue(userMessage.isUserMessage)
    XCTAssertFalse(assistantMessage.isUserMessage)
  }

  func testIsAssistantMessage() {
    let userMessage = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Hello",
      timestamp: Date()
    )

    let assistantMessage = ChatMessage(
      id: "msg-2",
      role: .assistant,
      text: "Response",
      timestamp: Date()
    )

    XCTAssertFalse(userMessage.isAssistantMessage)
    XCTAssertTrue(assistantMessage.isAssistantMessage)
  }

  func testIsSystemMessage() {
    let systemMessage = ChatMessage(
      id: "msg-1",
      role: .system,
      text: "System",
      timestamp: Date()
    )

    let userMessage = ChatMessage(
      id: "msg-2",
      role: .user,
      text: "Hello",
      timestamp: Date()
    )

    XCTAssertTrue(systemMessage.isSystemMessage)
    XCTAssertFalse(userMessage.isSystemMessage)
  }

  func testIsStreaming() {
    let streamingMessage = ChatMessage(
      id: "msg-1",
      role: .assistant,
      text: "Streaming",
      timestamp: Date(),
      streaming: true
    )

    let normalMessage = ChatMessage(
      id: "msg-2",
      role: .assistant,
      text: "Normal",
      timestamp: Date(),
      streaming: false
    )

    XCTAssertTrue(streamingMessage.isStreaming)
    XCTAssertFalse(normalMessage.isStreaming)
  }

  // MARK: - Edge Cases

  func testChatMessage_emptyText() {
    let message = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "",
      timestamp: Date()
    )

    XCTAssertEqual(message.text, "")
    XCTAssertFalse(message.text.isEmpty)  // 空字符串
  }

  func testChatMessage_veryLongText() {
    let longText = String(repeating: "A", count: 10000)
    let message = ChatMessage(
      id: "msg-1",
      role: .user,
      text: longText,
      timestamp: Date()
    )

    XCTAssertEqual(message.text.count, 10000)
  }

  func testChatMessage_specialCharacters() {
    let specialText = "Hello 世界 🌍 مرحبا"
    let message = ChatMessage(
      id: "msg-1",
      role: .user,
      text: specialText,
      timestamp: Date()
    )

    XCTAssertEqual(message.text, specialText)
  }

  func testChatMessage_newlineCharacters() {
    let textWithNewlines = "Line 1\nLine 2\nLine 3"
    let message = ChatMessage(
      id: "msg-1",
      role: .user,
      text: textWithNewlines,
      timestamp: Date()
    )

    XCTAssertEqual(message.text, textWithNewlines)
  }

  // MARK: - ToolUse Tests

  func testToolUse_initialization() {
    let toolUse = ToolUse(name: "test_tool", input: ["key": "value"])

    XCTAssertEqual(toolUse.name, "test_tool")
    XCTAssertEqual(toolUse.input["key"] as? String, "value")
  }

  func testToolUse_encoding() throws {
    let toolUse = ToolUse(name: "test_tool", input: ["key": "value"])

    let encoder = JSONEncoder()
    let jsonData = try encoder.encode(toolUse)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(ToolUse.self, from: jsonData)

    XCTAssertEqual(decoded.name, "test_tool")
    XCTAssertEqual(decoded.input["key"] as? String, "value")
  }

  func testToolUse_emptyInput() throws {
    let toolUse = ToolUse(name: "test_tool", input: [:])

    let encoder = JSONEncoder()
    let jsonData = try encoder.encode(toolUse)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(ToolUse.self, from: jsonData)

    XCTAssertEqual(decoded.name, "test_tool")
    XCTAssertTrue(decoded.input.isEmpty)
  }

  // MARK: - Performance Tests

  func testChatMessage_encoding_performance() {
    let message = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Test message",
      timestamp: Date()
    )

    self.measure {
      _ = try? JSONEncoder().encode(message)
    }
  }

  func testChatMessage_decoding_performance() throws {
    let message = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Test message",
      timestamp: Date()
    )

    let encoder = JSONEncoder()
    let jsonData = try encoder.encode(message)

    self.measure {
      _ = try? JSONDecoder().decode(ChatMessage.self, from: jsonData)
    }
  }
}
