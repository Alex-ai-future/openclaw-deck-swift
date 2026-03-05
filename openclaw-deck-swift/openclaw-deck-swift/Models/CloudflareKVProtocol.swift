// CloudflareKVProtocol.swift
// OpenClaw Deck Swift
//
// Cloudflare KV 协议 - 用于依赖注入和测试

import Foundation

/// Cloudflare KV 协议
protocol CloudflareKVProtocol {
    /// 是否已配置
    var isConfigured: Bool { get }

    /// 同步并获取数据
    func syncAndGet() async throws -> MergeResult

    /// 保存数据
    func save(_ data: SyncData) async throws

    /// 获取云端数据
    func fetch() async throws -> SyncData

    /// 保存 Session 列表到云端（从 SessionState 提取 ID）
    func saveSessions(_ sessions: [SessionState]) async throws

    /// 从云端获取 Session ID 列表，并转换为 SessionState（仅 ID，其他字段为空）
    func fetchSessions() async throws -> [SessionState]
}
