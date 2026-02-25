// UserDefaultsStorage.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/24/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation

/// UserDefaults 存储键
enum StorageKeys {
  static let gatewayUrl = "openclaw.deck.gatewayUrl"
  static let token = "openclaw.deck.token"
  static let sessionConfigs = "openclaw.deck.sessionConfigs"
  static let sessionOrder = "openclaw.deck.sessionOrder"
}

/// UserDefaults 存储工具类
class UserDefaultsStorage {
  static let shared = UserDefaultsStorage()

  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  // MARK: - Gateway URL

  /// 保存 Gateway URL
  func saveGatewayUrl(_ url: String) {
    defaults.set(url, forKey: StorageKeys.gatewayUrl)
  }

  /// 加载 Gateway URL
  func loadGatewayUrl() -> String? {
    return defaults.string(forKey: StorageKeys.gatewayUrl)
  }

  // MARK: - Token

  /// 保存 Token
  func saveToken(_ token: String) {
    defaults.set(token, forKey: StorageKeys.token)
  }

  /// 加载 Token
  func loadToken() -> String? {
    return defaults.string(forKey: StorageKeys.token)
  }

  /// 清除 Token
  func clearToken() {
    defaults.removeObject(forKey: StorageKeys.token)
  }

  // MARK: - Session Configs

  /// 保存 Session 配置列表
  func saveSessions(_ sessions: [SessionConfig]) {
    do {
      let data = try JSONEncoder().encode(sessions)
      defaults.set(data, forKey: StorageKeys.sessionConfigs)
    } catch {
      print("[UserDefaultsStorage] Failed to encode sessions: \(error)")
    }
  }

  /// 加载 Session 配置列表
  func loadSessions() -> [SessionConfig] {
    guard let data = defaults.data(forKey: StorageKeys.sessionConfigs) else {
      return []
    }

    do {
      let sessions = try JSONDecoder().decode([SessionConfig].self, from: data)
      return sessions
    } catch {
      print("[UserDefaultsStorage] Failed to decode sessions: \(error)")
      return []
    }
  }

  // MARK: - Session Order

  /// 保存 Session 顺序
  func saveSessionOrder(_ order: [String]) {
    defaults.set(order, forKey: StorageKeys.sessionOrder)
  }

  /// 加载 Session 顺序
  func loadSessionOrder() -> [String] {
    return defaults.array(forKey: StorageKeys.sessionOrder) as? [String] ?? []
  }

  // MARK: - Clear All

  /// 清除所有存储数据
  func clearAll() {
    defaults.removeObject(forKey: StorageKeys.gatewayUrl)
    defaults.removeObject(forKey: StorageKeys.token)
    defaults.removeObject(forKey: StorageKeys.sessionConfigs)
    defaults.removeObject(forKey: StorageKeys.sessionOrder)
  }
}
