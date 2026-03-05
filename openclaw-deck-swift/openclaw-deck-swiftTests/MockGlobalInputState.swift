// MockGlobalInputState.swift
// OpenClaw Deck Swift
//
// Mock GlobalInputState 用于单元测试

import Foundation

@testable import openclaw_deck_swift

/// Mock GlobalInputState - 用于单元测试
@MainActor
final class MockGlobalInputState: GlobalInputStateProtocol {
  var inputText: String = ""
  var textHeight: CGFloat = 36
  var selectedSessionId: String?
  var inputWidth: CGFloat = 300
  
  // 追踪发送的消息
  var sentMessages: [(message: String, session: SessionState)] = []

  var calculateTextHeightCalled = false
  var clearInputCalled = false
  var sendMessageCalled = false

  init() {}

  func calculateTextHeight() {
    calculateTextHeightCalled = true
  }

  func clearInput() {
    clearInputCalled = true
    inputText = ""
    textHeight = 36
  }

  func sendMessage(to session: SessionState, viewModel: DeckViewModel) async {
    sendMessageCalled = true
    // 记录发送的消息
    sentMessages.append((message: inputText, session: session))
  }
}
