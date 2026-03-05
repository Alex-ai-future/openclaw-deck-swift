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

    /// 模拟冲突场景
    var simulateConflict: Bool = false

    /// 本地冲突数据
    var conflictLocalData: SyncData?

    /// 云端冲突数据
    var conflictRemoteData: SyncData?

    /// 保存调用次数
    var saveCallCount: Int = 0

    /// syncAndGet 调用次数
    var syncCallCount: Int = 0

    func syncAndGet() async throws -> MergeResult {
        syncCallCount += 1

        if simulatedDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }

        // 冲突场景
        if simulateConflict, let localData = conflictLocalData, let remoteData = conflictRemoteData {
            return MergeResult(
                source: .conflict,
                data: localData,
                localData: localData,
                remoteData: remoteData
            )
        }
    }
    
    func fetch() async throws -> SyncData {
        if simulatedDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
        
        return mockData ?? SyncData(sessions: [], lastUpdated: "")
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
        saveCallCount += 1

        if simulatedDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
        mockData = data
    }

    /// 重置 Mock 状态
    func reset() {
        mockData = nil
        simulateConflict = false
        conflictLocalData = nil
        conflictRemoteData = nil
        saveCallCount = 0
        syncCallCount = 0
    }
}
