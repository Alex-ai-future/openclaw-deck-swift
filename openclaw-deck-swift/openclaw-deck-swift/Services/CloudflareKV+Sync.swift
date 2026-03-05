// CloudflareKV+Sync.swift
// OpenClaw Deck Swift
//
// Cloudflare KV 同步扩展（直接使用 SessionState）

import Foundation

extension CloudflareKV {
    /// 保存 Session 列表到云端
    func saveSessions(_ sessions: [SessionState]) async throws {
        // 直接编码 SessionState 数组
        let data = try JSONEncoder().encode(sessions)
        let base64 = data.base64EncodedString()
        
        try await put(key: "sessions", value: base64)
    }
    
    /// 从云端获取 Session 列表
    func fetchSessions() async throws -> [SessionState] {
        guard let base64 = try await get(key: "sessions") else {
            return []
        }
        
        guard let data = Data(base64Encoded: base64) else {
            return []
        }
        
        // 直接解码为 SessionState 数组
        let sessions = try JSONDecoder().decode([SessionState].self, from: data)
        return sessions
    }
}
