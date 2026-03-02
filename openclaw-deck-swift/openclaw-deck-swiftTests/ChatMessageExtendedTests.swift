// ChatMessageExtendedTests.swift
// OpenClaw Deck Swift
//
// ChatMessage 扩展测试

import XCTest

@testable import openclaw_deck_swift

final class ChatMessageExtendedTests: XCTestCase {

  // MARK: - MessageRole Tests

  func testMessageRole_rawValue() {
    XCTAssertEqual(MessageRole.user.rawValue, "user")
    XCTAssertEqual(MessageRole.assistant.rawValue, "assistant")
    XCTAssertEqual(MessageRole.system.rawValue, "system")
    XCTAssertEqual(MessageRole.tool.rawValue, "tool")
    XCTAssertEqual(MessageRole.status.rawValue, "status")
  }

  func testMessageRole_fromRawValue() {
    XCTAssertEqual(MessageRole(rawValue: "user"), .user)
    XCTAssertEqual(MessageRole(rawValue: "assistant"), .assistant)
    XCTAssertEqual(MessageRole(rawValue: "system"), .system)
    XCTAssertEqual(MessageRole(rawValue: "tool"), .tool)
    XCTAssertNil(MessageRole(rawValue: "invalid"))
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
    XCTAssertNil(message.streaming)
    XCTAssertNil(message.thinking)
    XCTAssertNil(message.toolUse)
    XCTAssertNil(message.runId)
    XCTAssertNil(message.seq)
    XCTAssertFalse(message.isLoaded)
  }

  func testChatMessage_withAllParameters() {
    let toolUse = ToolUseInfo(
      toolName: "test_tool",
      input: "input",
      output: "output",
      status: "completed"
    )

    let message = ChatMessage(
      id: "msg-1",
      role: .assistant,
      text: "Response",
      timestamp: Date(),
      streaming: true,
      thinking: false,
      toolUse: toolUse,
      runId: "run-123",
      seq: 1,
      isLoaded: true
    )

    XCTAssertEqual(message.streaming, true)
    XCTAssertEqual(message.thinking, false)
    XCTAssertNotNil(message.toolUse)
    XCTAssertEqual(message.runId, "run-123")
    XCTAssertEqual(message.seq, 1)
    XCTAssertTrue(message.isLoaded)
  }

  // MARK: - ChatMessage Codable Tests

  func testChatMessage_encoding() throws {
    let message = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Hello",
      timestamp: Date()
    )

    let encoder = JSONEncoder()
    let jsonData = try encoder.encode(message)

    // 验证可以解码
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(ChatMessage.self, from: jsonData)

    XCTAssertEqual(decoded.id, "msg-1")
    XCTAssertEqual(decoded.role, .user)
    XCTAssertEqual(decoded.text, "Hello")
  }

  func testChatMessage_decoding_withAllFields() throws {
    let iso8601DateFormatter = ISO8601DateFormatter()
    let testDate = iso8601DateFormatter.date(from: "2024-01-01T00:00:00Z")!

    let json = """
      {
        "id": "msg-1",
        "role": "assistant",
        "text": "Response",
        "timestamp": "2024-01-01T00:00:00Z",
        "streaming": true,
        "thinking": false,
        "runId": "run-123",
        "seq": 1,
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
    XCTAssertEqual(message.streaming, true)
    XCTAssertEqual(message.thinking, false)
    XCTAssertEqual(message.runId, "run-123")
    XCTAssertEqual(message.seq, 1)
    XCTAssertTrue(message.isLoaded)
  }

  func testChatMessage_decoding_withOptionalFields() throws {
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
    XCTAssertNil(message.streaming)
    XCTAssertNil(message.thinking)
    XCTAssertNil(message.runId)
    XCTAssertFalse(message.isLoaded)
  }

  // MARK: - ToolUseInfo Tests

  func testToolUseInfo_initialization() {
    let toolUse = ToolUseInfo(
      toolName: "search",
      input: "query",
      output: "result",
      status: "completed"
    )

    XCTAssertEqual(toolUse.toolName, "search")
    XCTAssertEqual(toolUse.input, "query")
    XCTAssertEqual(toolUse.output, "result")
    XCTAssertEqual(toolUse.status, "completed")
  }

  func testToolUseInfo_withNilOutput() {
    let toolUse = ToolUseInfo(
      toolName: "search",
      input: "query",
      output: nil,
      status: "running"
    )

    XCTAssertNil(toolUse.output)
    XCTAssertEqual(toolUse.status, "running")
  }

  func testToolUseInfo_encoding() throws {
    let toolUse = ToolUseInfo(
      toolName: "test_tool",
      input: "input",
      output: "output",
      status: "completed"
    )

    let encoder = JSONEncoder()
    let jsonData = try encoder.encode(toolUse)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(ToolUseInfo.self, from: jsonData)

    XCTAssertEqual(decoded.toolName, "test_tool")
    XCTAssertEqual(decoded.input, "input")
    XCTAssertEqual(decoded.output, "output")
    XCTAssertEqual(decoded.status, "completed")
  }

  // MARK: - Message Role Tests

  func testChatMessage_isUserMessage() {
    let userMessage = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Hello",
      timestamp: Date()
    )

    XCTAssertEqual(userMessage.role, .user)
  }

  func testChatMessage_isAssistantMessage() {
    let assistantMessage = ChatMessage(
      id: "msg-1",
      role: .assistant,
      text: "Response",
      timestamp: Date()
    )

    XCTAssertEqual(assistantMessage.role, .assistant)
  }

  func testChatMessage_isSystemMessage() {
    let systemMessage = ChatMessage(
      id: "msg-1",
      role: .system,
      text: "System message",
      timestamp: Date()
    )

    XCTAssertEqual(systemMessage.role, .system)
  }

  func testChatMessage_isToolMessage() {
    let toolMessage = ChatMessage(
      id: "msg-1",
      role: .tool,
      text: "Tool result",
      timestamp: Date()
    )

    XCTAssertEqual(toolMessage.role, .tool)
  }

  // MARK: - Streaming State Tests

  func testChatMessage_streamingState() {
    let message = ChatMessage(
      id: "msg-1",
      role: .assistant,
      text: "Streaming",
      timestamp: Date(),
      streaming: true
    )

    XCTAssertEqual(message.streaming, true)
  }

  func testChatMessage_thinkingState() {
    let message = ChatMessage(
      id: "msg-1",
      role: .assistant,
      text: "Thinking",
      timestamp: Date(),
      thinking: true
    )

    XCTAssertEqual(message.thinking, true)
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

  // MARK: - Identifiable Tests

  func testChatMessage_identifiable() {
    let message = ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Hello",
      timestamp: Date()
    )

    // 验证 Identifiable 协议
    XCTAssertEqual(message.id, "msg-1")
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
