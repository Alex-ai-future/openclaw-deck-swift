// ChatMessage.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation

/// 聊天消息模型（本地管理）
struct ChatMessage: Codable, Identifiable, Equatable {
  /// 消息唯一标识（用于 UI 显示）
  let id: String

  /// 消息角色（user, assistant, system）
  let role: MessageRole

  /// 消息内容文本
  let text: String

  /// 消息时间戳（创建时间）
  let timestamp: Date

  /// 是否正在流式输出中（用于实时更新）
  var streaming: Bool?

  /// 是否正在思考中（用于显示 thinking 状态）
  var thinking: Bool?

  /// 工具调用信息（用于显示 tool_use 状态）
  var toolUse: ToolUseInfo?

  /// 当前运行的 runId（用于关联消息和 Agent 运行）
  var runId: String?

  /// Gateway 事件序号（用于区分同 run 内的不同消息）
  var seq: Int?

  /// 消息是否已加载（用于判断是否为新消息）
  var isLoaded: Bool = false

  enum CodingKeys: String, CodingKey {
    case id, role, text, timestamp, streaming, thinking, toolUse, runId, seq, isLoaded
  }

  init(
    id: String, role: MessageRole, text: String, timestamp: Date, streaming: Bool? = nil,
    thinking: Bool? = nil, toolUse: ToolUseInfo? = nil, runId: String? = nil, seq: Int? = nil,
    isLoaded: Bool = false
  ) {
    self.id = id
    self.role = role
    self.text = text
    self.timestamp = timestamp
    self.streaming = streaming
    self.thinking = thinking
    self.toolUse = toolUse
    self.runId = runId
    self.seq = seq
    self.isLoaded = isLoaded
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    role = try container.decode(MessageRole.self, forKey: .role)
    text = try container.decode(String.self, forKey: .text)
    timestamp = try container.decode(Date.self, forKey: .timestamp)
    streaming = try container.decodeIfPresent(Bool.self, forKey: .streaming)
    thinking = try container.decodeIfPresent(Bool.self, forKey: .thinking)
    toolUse = try container.decodeIfPresent(ToolUseInfo.self, forKey: .toolUse)
    runId = try container.decodeIfPresent(String.self, forKey: .runId)
    seq = try container.decodeIfPresent(Int.self, forKey: .seq)
    isLoaded = try container.decodeIfPresent(Bool.self, forKey: .isLoaded) ?? false
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(role, forKey: .role)
    try container.encode(text, forKey: .text)
    try container.encode(timestamp, forKey: .timestamp)
    try container.encodeIfPresent(streaming, forKey: .streaming)
    try container.encodeIfPresent(thinking, forKey: .thinking)
    try container.encodeIfPresent(toolUse, forKey: .toolUse)
    try container.encodeIfPresent(runId, forKey: .runId)
    try container.encodeIfPresent(seq, forKey: .seq)
    try container.encode(isLoaded, forKey: .isLoaded)
  }
}

/// 消息角色类型（用户、助手、系统）
enum MessageRole: String, Codable {
  /// 用户发送的消息
  case user

  /// AI 助手回复的消息
  case assistant

  /// 系统生成的消息（如连接状态等）
  case system

  /// 工具调用消息（tool_use, tool, tool_result）
  case tool

  /// 状态消息
  case status

  /// 参数消息
  case parameter

  /// 思考内容
  case thinking
}

/// 工具调用信息（用于显示 tool_use 状态）
struct ToolUseInfo: Codable, Equatable {
  /// 工具名称（如 "search", "code_interpreter"）
  let toolName: String

  /// 工具参数（工具调用时的输入参数）
  let input: String

  /// 工具输出（工具执行后的结果）
  let output: String?

  /// 工具执行状态（"running", "completed", "failed"）
  let status: String

  enum CodingKeys: String, CodingKey {
    case toolName, input, output, status
  }

  init(toolName: String, input: String, output: String? = nil, status: String) {
    self.toolName = toolName
    self.input = input
    self.output = output
    self.status = status
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    toolName = try container.decode(String.self, forKey: .toolName)
    input = try container.decode(String.self, forKey: .input)
    output = try container.decodeIfPresent(String.self, forKey: .output)
    status = try container.decode(String.self, forKey: .status)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(toolName, forKey: .toolName)
    try container.encode(input, forKey: .input)
    try container.encodeIfPresent(output, forKey: .output)
    try container.encode(status, forKey: .status)
  }
}

// MARK: - Extensions

extension ChatMessage {
  /// 检查消息是否为用户发送的消息
  var isUserMessage: Bool {
    return role == .user
  }

  /// 检查消息是否为助手回复的消息
  var isAssistantMessage: Bool {
    return role == .assistant
  }

  /// 检查消息是否为系统消息
  var isSystemMessage: Bool {
    return role == .system
  }

  /// 检查消息是否为流式消息（正在接收中）
  var isStreaming: Bool {
    return streaming == true
  }

  /// 检查消息是否为思考中的消息（thinking）
  var isThinking: Bool {
    return thinking == true
  }

  /// 检查消息是否为工具调用消息（tool_use）
  var isToolUse: Bool {
    return toolUse != nil
  }

  /// 获取消息的简要描述（用于 UI 显示）
  var description: String {
    switch role {
    case .user:
      return "\(text)"
    case .assistant, .tool, .status, .parameter, .thinking:
      return "\(text)"
    case .system:
      return "\(text)"
    }
  }
}
