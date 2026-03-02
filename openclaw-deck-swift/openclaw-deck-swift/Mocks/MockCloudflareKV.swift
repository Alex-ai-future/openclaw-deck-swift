@testable import openclaw_deck_swift

// MockCloudflareKV.swift
// OpenClaw Deck Swift
//
// Mock Cloudflare KV - 用于 UI 测试

import Foundation

/// Mock Cloudflare KV
class MockCloudflareKV: CloudflareKVProtocol {
    var isConfigured: Bool = true

    /// 模拟数据
    var mockData: SyncData?

    /// 模拟延迟（秒）
    var simulatedDelay: Double = 0.0

    func syncAndGet() async throws -> MergeResult {
        if simulatedDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }

        // 返回模拟数据或空数据
        let data = mockData ?? SyncData(sessions: [], lastUpdated: ISO8601DateFormatter().string(from: Date()))

        return MergeResult(
            source: .local,
            data: data,
            localData: data,
            remoteData: nil
        )
    }

    func save(_ data: SyncData) async throws {
        if simulatedDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
        mockData = data
    }
}
