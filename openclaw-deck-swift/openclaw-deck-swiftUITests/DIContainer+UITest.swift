// DIContainer+UITest.swift
// OpenClaw Deck Swift
//
// UI 测试专用依赖容器配置

import Foundation
@testable import openclaw_deck_swift

/// 为 UI 测试创建依赖容器
@MainActor
func createUITestingDIContainer() -> DIContainer {
    // Mock 存储
    let mockStorage = MockUserDefaultsStorage()

    // 预置测试数据
    let welcomeSession = SessionConfig(
        id: "Welcome",
        sessionKey: "test-session-key",
        createdAt: Date(),
        name: "Welcome",
        icon: "W",
        context: "Welcome Session"
    )
    mockStorage.saveSessions([welcomeSession])
    mockStorage.saveSessionOrder(["Welcome"])

    // Mock Gateway 客户端工厂
    let gatewayClientFactory: (URL, String?) -> GatewayClientProtocol = { _, _ in
        let mockClient = MockGatewayClient()
        mockClient.simulatedDelay = 0.1 // 模拟快速响应
        mockClient.mockHistory = [
            ChatMessage(
                id: UUID().uuidString,
                role: .assistant,
                text: "Hello! This is a test message.",
                timestamp: Date()
            ),
        ]
        return mockClient
    }

    // Mock Cloudflare KV
    let mockCloudflare = MockCloudflareKV()
    mockCloudflare.simulatedDelay = 0.1

    // Mock 全局输入状态工厂
    let globalInputStateFactory: () -> GlobalInputStateProtocol = {
        GlobalInputState()
    }

    return DIContainer(
        storage: mockStorage,
        gatewayClientFactory: gatewayClientFactory,
        cloudflareKV: mockCloudflare,
        globalInputStateFactory: globalInputStateFactory
    )
}
