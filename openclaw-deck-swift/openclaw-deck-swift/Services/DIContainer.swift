// DIContainer.swift
// OpenClaw Deck Swift
//
// 依赖注入容器 - 管理服务依赖

import Foundation

/// 依赖容器
@MainActor
class DIContainer {
    /// 共享实例（生产环境）
    @MainActor static let shared = DIContainer()

    /// UserDefaults 存储
    let storage: UserDefaultsStorageProtocol

    /// Gateway 客户端工厂
    let gatewayClientFactory: (URL, String?) -> GatewayClientProtocol

    /// Cloudflare KV
    let cloudflareKV: CloudflareKVProtocol

    /// 全局输入状态工厂
    let globalInputStateFactory: () -> GlobalInputStateProtocol

    /// 初始化（生产环境）
    private init() {
        self.storage = UserDefaultsStorage.shared
        self.gatewayClientFactory = { url, token in
            GatewayClient(url: url, token: token)
        }
        self.cloudflareKV = CloudflareKV.shared
        self.globalInputStateFactory = {
            GlobalInputState()
        }
    }

    /// 初始化（测试环境）
    init(
        storage: UserDefaultsStorageProtocol,
        gatewayClientFactory: @escaping (URL, String?) -> GatewayClientProtocol,
        cloudflareKV: CloudflareKVProtocol,
        globalInputStateFactory: @escaping () -> GlobalInputStateProtocol
    ) {
        self.storage = storage
        self.gatewayClientFactory = gatewayClientFactory
        self.cloudflareKV = cloudflareKV
        self.globalInputStateFactory = globalInputStateFactory
    }

    /// 创建 Gateway 客户端
    func createGatewayClient(url: URL, token: String?) -> GatewayClientProtocol {
        gatewayClientFactory(url, token)
    }

    /// 创建全局输入状态
    func createGlobalInputState() -> GlobalInputStateProtocol {
        globalInputStateFactory()
    }
}
