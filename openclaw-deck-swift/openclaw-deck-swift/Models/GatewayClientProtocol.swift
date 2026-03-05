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

    /// 事件回调
    var onEvent: ((GatewayEvent) -> Void)? { get set }

    /// 连接状态回调
    var onConnection: ((Bool) -> Void)? { get set }

    /// 连接 Gateway
    func connect() async

    /// 断开连接
    func disconnect()

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
