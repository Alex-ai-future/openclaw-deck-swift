// CloudflareKV+Sync.swift
// OpenClaw Deck Swift
//
// Cloudflare KV 同步扩展（直接使用 SessionState）

import Foundation

extension CloudflareKV {
    /// 保存 Session 列表到云端
    func saveSessions(_ sessions: [SessionState]) async throws {
        // 转换为 SyncData
        let sessionData = sessions.map { session in
            SessionData(
                id: session.id,
                sessionKey: session.sessionKey,
                name: session.name,
                context: session.context,
                sortOrder: session.sortOrder,
                createdAt: session.createdAt,
                lastActivityAt: session.lastActivityAt
            )
        }
        
        let syncData = SyncData(
            sessions: sessionData,
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        )
        
        try await save(syncData)
    }
    
    /// 从云端获取 Session 列表
    func fetchSessions() async throws -> [SessionState] {
        let syncData = try await fetch()
        
        // 转换为 SessionState 数组
        let sessions = syncData.sessions.map { data in
            SessionState(
                id: data.id,
                sessionKey: data.sessionKey,
                name: data.name,
                context: data.context,
                isHidden: false,  // 隐藏状态本地保存
                sortOrder: data.sortOrder,
                createdAt: data.createdAt,
                lastActivityAt: data.lastActivityAt
            )
        }
        
        return sessions
    }
}
