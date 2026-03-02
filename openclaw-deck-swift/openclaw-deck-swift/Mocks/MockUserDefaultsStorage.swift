@testable import openclaw_deck_swift

// MockUserDefaultsStorage.swift
// OpenClaw Deck Swift
//
// Mock UserDefaults 存储 - 用于 UI 测试

import Foundation

/// Mock UserDefaults 存储
public class MockUserDefaultsStorage: UserDefaultsStorageProtocol {
    public var isTesting: Bool = true

    /// 内存存储
    private var sessionsStore: [SessionConfig] = []
    private var sessionOrderStore: [String] = []
    private var gatewayUrlStore: String?
    private var tokenStore: String?

    public func saveSessions(_ sessions: [SessionConfig]) {
        sessionsStore = sessions
    }

    public func loadSessions() -> [SessionConfig] {
        sessionsStore
    }

    public func saveSessionOrder(_ order: [String]) {
        sessionOrderStore = order
    }

    public func loadSessionOrder() -> [String] {
        sessionOrderStore
    }

    public func saveGatewayUrl(_ url: String) {
        gatewayUrlStore = url
    }

    public func loadGatewayUrl() -> String? {
        gatewayUrlStore
    }

    public func saveToken(_ token: String) {
        tokenStore = token
    }

    public func loadToken() -> String? {
        tokenStore
    }

    public func clearAll() {
        sessionsStore = []
        sessionOrderStore = []
        gatewayUrlStore = nil
        tokenStore = nil
    }
}
