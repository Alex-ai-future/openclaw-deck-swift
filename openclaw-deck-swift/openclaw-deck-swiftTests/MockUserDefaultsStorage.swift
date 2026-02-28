// MockUserDefaultsStorage.swift
// OpenClaw Deck Swift
//
// Mock 存储用于单元测试，避免状态污染

import Foundation

@testable import openclaw_deck_swift

/// Mock UserDefaultsStorage - 用于单元测试
final class MockUserDefaultsStorage: UserDefaultsStorageProtocol {

  // 内存存储，每个测试实例独立
  private var storage: [String: Any] = [:]
  
  /// 标记为测试环境
  var isTesting: Bool { true }

  // MARK: - Gateway URL

  func saveGatewayUrl(_ url: String) {
    storage["gatewayUrl"] = url
  }

  func loadGatewayUrl() -> String? {
    return storage["gatewayUrl"] as? String
  }

  // MARK: - Token

  func saveToken(_ token: String) {
    storage["token"] = token
  }

  func loadToken() -> String? {
    return storage["token"] as? String
  }

  // MARK: - Sessions

  func saveSessions(_ sessions: [SessionConfig]) {
    storage["sessions"] = sessions
  }

  func loadSessions() -> [SessionConfig] {
    // 返回空数组，让 DeckViewModel 自动创建 Welcome Session
    return storage["sessions"] as? [SessionConfig] ?? []
  }

  // MARK: - Session Order

  func saveSessionOrder(_ order: [String]) {
    storage["sessionOrder"] = order
  }

  func loadSessionOrder() -> [String] {
    return storage["sessionOrder"] as? [String] ?? []
  }

  // MARK: - Utility

  /// 清空所有存储（用于测试清理）
  func clear() {
    storage.removeAll()
  }

  /// 检查存储是否为空
  var isEmpty: Bool {
    return storage.isEmpty
  }
}
