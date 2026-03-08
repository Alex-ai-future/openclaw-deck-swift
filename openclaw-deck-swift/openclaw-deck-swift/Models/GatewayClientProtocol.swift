// GatewayClientProtocol.swift
// OpenClaw Deck Swift
//
// Gateway 客户端协议 - 用于依赖注入和测试

import Foundation

/// Gateway 客户端协议
@MainActor
protocol GatewayClientProtocol {
    /// 是否已连接
    var connected: Bool { get set }

    /// 连接错误信息
    var connectionError: String? { get set }

    /// 连接状态（计算属性）
    var connectionStatus: ConnectionStatus { get }

    /// 事件回调
    var onEvent: ((GatewayEvent) -> Void)? { get set }

    /// 连接状态回调
    var onConnection: ((Bool) -> Void)? { get set }

    /// 连接 Gateway
    /// - Parameter silent: 是否静默连接（用于自动重连）
    func connect(silent: Bool) async

    /// 断开连接
    func disconnect()

    /// 处理断开连接（被动断开 → 自动重连）
    func handleDisconnect()

    /// 清除错误
    func clearError()

    /// 重置设备身份
    func resetDeviceIdentity()

    /// 获取 Session 历史
    func getSessionHistory(sessionKey: String) async throws -> [ChatMessage]?

    /// 运行 Agent
    func runAgent(
        agentId: String,
        message: String,
        sessionKey: String?
    ) async throws -> (runId: String, status: String)

    /// 中断对话
    func abortChat(sessionKey: String, runId: String?) async throws
}
