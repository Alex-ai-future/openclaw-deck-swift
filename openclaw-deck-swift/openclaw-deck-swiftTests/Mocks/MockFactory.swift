// MockFactory.swift
// OpenClaw Deck Swift
//
// Mock 工厂 - 统一创建测试依赖

@testable import openclaw_deck_swift
import Foundation

/// Mock 工厂 - 统一创建测试依赖
@MainActor
class MockFactory {
    /// 创建 DIContainer
    static func createDIContainer(
        storage: UserDefaultsStorageProtocol? = nil,
        gatewayClient: GatewayClientProtocol? = nil,
        cloudflareKV: CloudflareKVProtocol? = nil,
        globalInputState: GlobalInputStateProtocol? = nil,
        gatewayClientDelay: Double = 0.0,
        mockHistory: [ChatMessage] = []
    ) -> DIContainer {
        DIContainer(
            storage: storage ?? MockUserDefaultsStorage(),
            gatewayClientFactory: { _, _ in
                let client = gatewayClient ?? MockGatewayClient()
                if let mockClient = client as? MockGatewayClient {
                    mockClient.simulatedDelay = gatewayClientDelay
                    mockClient.mockHistory = mockHistory
                }
                return client
            },
            cloudflareKV: cloudflareKV ?? MockCloudflareKV(),
            globalInputStateFactory: { globalInputState ?? MockGlobalInputState() }
        )
    }
    
    /// 创建预配置的 MockGatewayClient
    static func createMockGatewayClient(
        connected: Bool = true,
        delay: Double = 0.0,
        history: [ChatMessage] = []
    ) -> MockGatewayClient {
        let client = MockGatewayClient()
        client.connected = connected
        client.simulatedDelay = delay
        client.mockHistory = history
        return client
    }
    
    /// 创建预配置的 MockUserDefaultsStorage
    static func createMockStorage(
        sessions: [SessionConfig] = [],
        order: [String] = [],
        gatewayUrl: String? = nil,
        token: String? = nil
    ) -> MockUserDefaultsStorage {
        let storage = MockUserDefaultsStorage()
        storage.saveSessions(sessions)
        storage.saveSessionOrder(order)
        if let url = gatewayUrl { storage.saveGatewayUrl(url) }
        if let token = token { storage.saveToken(token) }
        return storage
    }
}
