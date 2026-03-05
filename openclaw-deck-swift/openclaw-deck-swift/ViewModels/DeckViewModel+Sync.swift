// DeckViewModel+Sync.swift
// OpenClaw Deck Swift
//
// DeckViewModel 同步扩展

import os.log
import SwiftData

private let logger = Logger(subsystem: "com.openclaw.deck", category: "DeckViewModel")

extension DeckViewModel {
    /// 全量同步到 Cloudflare（本地有任何改动时调用）
    func syncToCloud() async {
        do {
            // 获取所有本地 Session
            let sessions = try modelContext.fetch(FetchDescriptor<SessionState>())

            // 直接上传 SessionState 数组
            try await CloudflareKV.shared.saveSessions(sessions)

            logger.info("✅ Synced \(sessions.count) sessions to cloud")
        } catch {
            logger.error("❌ Sync failed: \(error)")
        }
    }

    /// 从云端下载
    func downloadFromCloud() async {
        do {
            let cloudSessions = try await CloudflareKV.shared.fetchSessions()

            // 清空本地
            let localSessions = try? modelContext.fetch(FetchDescriptor<SessionState>())
            for session in localSessions ?? [] {
                modelContext.delete(session)
            }

            // 直接插入 SessionState（重置 isHidden）
            for session in cloudSessions {
                session.isHidden = false // 隐藏状态本地保存
                modelContext.insert(session)
            }

            try? modelContext.save()
        } catch {
            logger.error("❌ Download failed: \(error)")
        }
    }

    /// 检查云端冲突
    func checkCloudConflict() async throws -> ConflictResult {
        let localSessions = try modelContext.fetch(FetchDescriptor<SessionState>())
        let cloudSessions = try await CloudflareKV.shared.fetchSessions()

        // 比较 ID 集合
        let localIds = Set(localSessions.map(\.id))
        let cloudIds = Set(cloudSessions.map(\.id))

        if localIds == cloudIds {
            // ID 相同：检查顺序
            let localOrder = localSessions.map(\.id)
            let cloudOrder = cloudSessions.map(\.id)

            if localOrder == cloudOrder {
                return .noConflict
            }
        }

        return .conflict(
            localCount: localSessions.count,
            cloudCount: cloudSessions.count
        )
    }

    /// 解决冲突
    func resolveConflict(choice: ConflictChoice) async {
        switch choice {
        case .useLocal:
            // 使用本地：全量上传到云端
            await syncToCloud()

        case .useCloud:
            // 使用云端：下载并覆盖本地
            await downloadFromCloud()

        case .merge:
            // 合并：云端 + 本地
            await mergeWithCloud()
        }
    }

    /// 合并云端和本地
    private func mergeWithCloud() async {
        do {
            let cloudSessions = try await CloudflareKV.shared.fetchSessions()
            var localSessions = try modelContext.fetch(FetchDescriptor<SessionState>())

            // 添加云端有但本地没有的
            let localIds = Set(localSessions.map(\.id))
            for cloudSession in cloudSessions {
                if !localIds.contains(cloudSession.id) {
                    cloudSession.isHidden = false
                    modelContext.insert(cloudSession)
                    localSessions.append(cloudSession)
                }
            }

            // 全量同步回云端
            try await CloudflareKV.shared.saveSessions(localSessions)
            try? modelContext.save()
        } catch {
            logger.error("❌ Merge failed: \(error)")
        }
    }
}

// MARK: - Conflict Types

enum ConflictResult {
    case noConflict
    case conflict(localCount: Int, cloudCount: Int)
}

enum ConflictChoice {
    case useLocal
    case useCloud
    case merge
}
