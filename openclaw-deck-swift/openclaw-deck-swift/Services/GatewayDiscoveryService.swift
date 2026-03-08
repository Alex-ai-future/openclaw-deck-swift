// GatewayDiscoveryService.swift
// OpenClaw Deck Swift
//
// 局域网 Gateway 服务发现

import Combine
import Darwin // 用于 inet_ntop 等网络函数
import Foundation
import OSLog

/// Gateway 服务信息
struct GatewayService: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let hostName: String
    let port: Int32
    let type: String
    let domain: String
    let ipAddress: String? // IP 地址（仅用于显示/调试）

    /// WebSocket 连接地址（使用主机名，更稳定）
    var wsURL: String {
        "ws://\(hostName):\(port)"
    }

    /// HTTP 地址（用于测试）
    var httpURL: String {
        "http://\(hostName):\(port)"
    }

    /// 显示地址（用于 UI，显示主机名）
    var displayAddress: String {
        "\(hostName):\(port)"
    }
}

/// 局域网 Gateway 发现服务
final class GatewayDiscoveryService: NSObject, ObservableObject {
    static let shared = GatewayDiscoveryService()

    @Published private(set) var gateways: [GatewayService] = []
    @Published private(set) var isScanning: Bool = false
    @Published private(set) var lastScanTime: Date?
    @Published var isEnabled: Bool = false // 用户控制的扫描开关

    private let logger = Logger(subsystem: "com.openclaw.deck", category: "Discovery")
    private var browser: NetServiceBrowser?
    private var resolvedServices: [NetService] = []

    /// OpenClaw Gateway 服务类型
    private let serviceType = "_openclaw-gw._tcp"

    override private init() {}

    // MARK: - 公开方法

    /// 开始扫描局域网 Gateway
    @objc func start() {
        guard !isScanning else {
            logger.warning("已在扫描中")
            return
        }

        isEnabled = true
        logger.info("🔍 开始扫描局域网 Gateway...")
        gateways.removeAll()
        resolvedServices.removeAll()

        browser = NetServiceBrowser()
        browser?.delegate = self
        browser?.searchForServices(
            ofType: serviceType,
            inDomain: "local."
        )

        isScanning = true
    }

    /// 停止扫描
    @objc func stop() {
        isEnabled = false
        browser?.stop()
        browser = nil
        isScanning = false
        logger.info("⏹️ 停止扫描")
    }

    /// 刷新扫描（先停止再开始）
    @objc func refresh() {
        logger.info("🔄 刷新扫描")
        stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.start()
        }
    }
}

// MARK: - NetServiceBrowserDelegate

extension GatewayDiscoveryService: NetServiceBrowserDelegate {
    func netServiceBrowser(_: NetServiceBrowser,
                           didFind service: NetService,
                           moreComing _: Bool)
    {
        logger.info("✅ 发现服务：\(service.name)")
        resolvedServices.append(service)
        service.delegate = self
        service.resolve(withTimeout: 5.0)
    }

    func netServiceBrowser(_: NetServiceBrowser,
                           didRemove service: NetService,
                           moreComing _: Bool)
    {
        logger.info("❌ 服务移除：\(service.name)")
        gateways.removeAll { $0.name == service.name }
    }

    func netServiceBrowserDidStopSearch(_: NetServiceBrowser) {
        logger.info("🛑 扫描停止，共发现 \(self.gateways.count) 个 Gateway")
    }

    func netServiceBrowser(_: NetServiceBrowser,
                           didNotSearch error: [String: NSNumber])
    {
        logger.error("❌ 扫描失败：\(error)")
        isScanning = false
    }
}

// MARK: - NetServiceDelegate

extension GatewayDiscoveryService: NetServiceDelegate {
    func netServiceDidResolveAddress(_ sender: NetService) {
        // 解析 IP 地址
        let ipAddress = extractIPAddress(from: sender.addresses)

        let gateway = GatewayService(
            name: sender.name,
            hostName: sender.hostName ?? "unknown",
            port: Int32(sender.port),
            type: sender.type,
            domain: sender.domain ?? "local.",
            ipAddress: ipAddress
        )

        logger.info("""
        📡 Gateway 详情:
          名称：\(gateway.name)
          主机名：\(gateway.hostName)
          IP 地址：\(gateway.ipAddress ?? "未解析")
          端口：\(gateway.port)
          WebSocket: \(gateway.wsURL)
        """)

        DispatchQueue.main.async {
            // 避免重复添加
            if !self.gateways.contains(where: { $0.name == gateway.name }) {
                self.gateways.append(gateway)
                self.lastScanTime = Date()
            }
        }
    }

    func netService(_ sender: NetService, didNotResolve error: [String: NSNumber]) {
        logger.warning("⚠️ 解析失败：\(sender.name) - \(error)")
    }
}

// MARK: - Helper Methods

extension GatewayDiscoveryService {
    /// 从 addresses 数组中解析 IPv4 地址
    private func extractIPAddress(from addresses: [Data]?) -> String? {
        guard let addresses else { return nil }

        for addrData in addresses {
            let addr = addrData.withUnsafeBytes {
                $0.bindMemory(to: sockaddr.self).baseAddress!
            }

            switch addr.pointee.sa_family {
            case sa_family_t(AF_INET): // IPv4
                var ipv4Addr = sockaddr_in()
                memcpy(&ipv4Addr, addr, MemoryLayout<sockaddr_in>.size)
                var ip = CChar(INET_ADDRSTRLEN)
                return String(cString: inet_ntop(AF_INET, &ipv4Addr.sin_addr, &ip, socklen_t(INET_ADDRSTRLEN)))

            case sa_family_t(AF_INET6): // IPv6
                var ipv6Addr = sockaddr_in6()
                memcpy(&ipv6Addr, addr, MemoryLayout<sockaddr_in6>.size)
                var ip = CChar(INET6_ADDRSTRLEN)
                let ipAddress = String(cString: inet_ntop(AF_INET6, &ipv6Addr.sin6_addr, &ip, socklen_t(INET6_ADDRSTRLEN)))
                return "[\(ipAddress)]" // IPv6 需要方括号

            default:
                continue
            }
        }
        return nil
    }
}
