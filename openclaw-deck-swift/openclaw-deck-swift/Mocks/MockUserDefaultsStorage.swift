@testable import openclaw_deck_swift

// MockUserDefaultsStorage.swift
// OpenClaw Deck Swift
//
// Mock UserDefaults 存储 - 用于 UI 测试

import Foundation

/// Mock UserDefaults 存储
class MockUserDefaultsStorage: UserDefaultsStorageProtocol {
    var isTesting: Bool = true

    /// 内存存储
    private var sessionsStore: [SessionConfig] = []
    private var sessionOrderStore: [String] = []
    private var gatewayUrlStore: String?
    private var tokenStore: String?

    func saveSessions(_ sessions: [SessionConfig]) {
        sessionsStore = sessions
    }

    func loadSessions() -> [SessionConfig] {
        sessionsStore
    }

    func saveSessionOrder(_ order: [String]) {
        sessionOrderStore = order
    }

    func loadSessionOrder() -> [String] {
        sessionOrderStore
    }

    func saveGatewayUrl(_ url: String) {
        gatewayUrlStore = url
    }

    func loadGatewayUrl() -> String? {
        gatewayUrlStore
    }

    func saveToken(_ token: String) {
        tokenStore = token
    }

    func loadToken() -> String? {
        tokenStore
    }

    func clearAll() {
        sessionsStore = []
        sessionOrderStore = []
        gatewayUrlStore = nil
        tokenStore = nil
    }
}
