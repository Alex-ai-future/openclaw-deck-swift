// UserDefaultsStorage.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/24/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation
import os.log

private let logger = Logger(subsystem: "com.openclaw.deck", category: "UserDefaultsStorage")

// MARK: - Protocol

/// UserDefaults 存储协议
protocol UserDefaultsStorageProtocol {
    /// 是否是测试环境（用于跳过云端同步）
    var isTesting: Bool { get }

    func saveGatewayUrl(_ url: String)
    func loadGatewayUrl() -> String?
    func saveToken(_ token: String)
    func loadToken() -> String?
    func saveSessions(_ sessions: [SessionConfig])
    func loadSessions() -> [SessionConfig]
    func saveSessionOrder(_ order: [String])
    func loadSessionOrder() -> [String]
}

// MARK: - UserDefaults Storage Keys

/// UserDefaults 存储键
enum StorageKeys: String {
    case gatewayUrl = "openclaw.deck.gatewayUrl"
    case token = "openclaw.deck.token"
    case sessionConfigs = "openclaw.deck.sessionConfigs"
    case sessionOrder = "openclaw.deck.sessionOrder"
}

// MARK: - Default Implementation

/// UserDefaults 存储工具类
@MainActor
class UserDefaultsStorage: UserDefaultsStorageProtocol {
    static let shared = UserDefaultsStorage()

    private let defaults: UserDefaults

    /// 是否是测试环境（默认 false）
    var isTesting: Bool {
        false
    }

    /// 初始化
    /// - Parameter defaults: UserDefaults 实例（默认为 .standard）
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Gateway URL

    func saveGatewayUrl(_ url: String) {
        defaults.set(url, forKey: StorageKeys.gatewayUrl.rawValue)
    }

    func loadGatewayUrl() -> String? {
        defaults.string(forKey: StorageKeys.gatewayUrl.rawValue)
    }

    // MARK: - Token

    func saveToken(_ token: String) {
        defaults.set(token, forKey: StorageKeys.token.rawValue)
    }

    func loadToken() -> String? {
        defaults.string(forKey: StorageKeys.token.rawValue)
    }

    /// 清除 Token
    func clearToken() {
        defaults.removeObject(forKey: StorageKeys.token.rawValue)
    }

    // MARK: - Session Configs

    func saveSessions(_ sessions: [SessionConfig]) {
        do {
            let data = try JSONEncoder().encode(sessions)
            defaults.set(data, forKey: StorageKeys.sessionConfigs.rawValue)
        } catch {
            logger.error("Failed to encode sessions: \(error)")
        }
    }

    func loadSessions() -> [SessionConfig] {
        guard let data = defaults.data(forKey: StorageKeys.sessionConfigs.rawValue) else {
            return []
        }

        do {
            return try JSONDecoder().decode([SessionConfig].self, from: data)
        } catch {
            logger.error("Failed to decode sessions: \(error)")
            return []
        }
    }

    // MARK: - Session Order

    func saveSessionOrder(_ order: [String]) {
        defaults.set(order, forKey: StorageKeys.sessionOrder.rawValue)
    }

    func loadSessionOrder() -> [String] {
        defaults.array(forKey: StorageKeys.sessionOrder.rawValue) as? [String] ?? []
    }

    // MARK: - Clear All

    /// 清除所有存储数据
    func clearAll() {
        defaults.removeObject(forKey: StorageKeys.gatewayUrl.rawValue)
        defaults.removeObject(forKey: StorageKeys.token.rawValue)
        defaults.removeObject(forKey: StorageKeys.sessionConfigs.rawValue)
        defaults.removeObject(forKey: StorageKeys.sessionOrder.rawValue)
    }
}
