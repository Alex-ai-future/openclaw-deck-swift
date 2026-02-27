// SessionState.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/24/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation

/// Session 运行时状态
enum SessionStatus: Equatable {
  /// 空闲状态
  case idle
  /// 思考中（等待 Agent 响应）
  case thinking
  /// 流式输出中
  case streaming
  /// 错误状态
  case error(String)
}

/// Session 运行时状态（内存缓存，不持久化）
@Observable
class SessionState {
  /// Session ID
  let sessionId: String

  /// Session Key（用于 Gateway 通信）
  let sessionKey: String

  // Fix for Swift 6 @Observable + @MainActor crash in XCTest
  // See: https://github.com/swiftlang/swift/issues/87316
  nonisolated deinit {}

  /// 消息列表
  var messages: [ChatMessage] = []

  /// 是否已加载历史消息
  var historyLoaded: Bool = false

  /// 是否正在加载历史消息
  var isHistoryLoading: Bool = false

  /// 当前状态
  var status: SessionStatus = .idle

  /// 当前活跃的 runId（用于关联流式响应）
  var activeRunId: String?

  /// 🆕 是否正在处理中（lifecycle start → end 之间）
  var isProcessing: Bool = false

  /// 最后一条消息的时间
  var lastMessageAt: Date? {
    messages.last?.timestamp
  }

  /// 消息数量
  var messageCount: Int {
    messages.count
  }

  init(sessionId: String, sessionKey: String) {
    self.sessionId = sessionId
    self.sessionKey = sessionKey
  }

  // MARK: - Message Management

  /// 添加消息
  func appendMessage(_ message: ChatMessage) {
    messages.append(message)
  }

  /// 更新最后一条消息（用于流式输出）
  func updateLastMessage(text: String) {
    guard let index = messages.indices.last else { return }
    let message = messages[index]
    messages[index] = ChatMessage(
      id: message.id,
      role: message.role,
      text: text,
      timestamp: message.timestamp,
      streaming: message.streaming,
      thinking: message.thinking,
      toolUse: message.toolUse,
      runId: message.runId,
      isLoaded: message.isLoaded
    )
  }

  /// 追加文本到最后一条消息（用于流式输出）
  func appendToLastMessage(text: String) {
    guard let index = messages.indices.last else { return }
    let message = messages[index]

    // 只在最后一条消息是 assistant 消息时才追加
    guard message.role == .assistant else { return }

    messages[index] = ChatMessage(
      id: message.id,
      role: message.role,
      text: message.text + text,
      timestamp: message.timestamp,
      streaming: message.streaming,
      thinking: message.thinking,
      toolUse: message.toolUse,
      runId: message.runId,
      isLoaded: message.isLoaded
    )
  }

  /// 清除消息列表
  func clearMessages() {
    messages.removeAll()
    historyLoaded = false
  }
}
