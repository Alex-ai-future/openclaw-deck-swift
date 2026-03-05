// DeckViewModel.swift
// OpenClaw Deck Swift
//
// Deck ViewModel - 使用 SwiftData（简化版 + 同步）

import Foundation
import os.log
import SwiftData

private let logger = Logger(subsystem: "com.openclaw.deck", category: "DeckViewModel")

@Observable
@MainActor
class DeckViewModel {
    var modelContext: ModelContext

    /// 全局输入状态
    let globalInputState = GlobalInputState()

    /// Gateway 客户端
    var gatewayClient: GatewayClientProtocol?

    /// 连接错误信息
    var connectionError: String?

    /// 停止错误信息
    var stopErrorText: String = ""

    /// 是否显示停止错误
    var showStopError: Bool = false

    /// Gateway 连接状态
    var gatewayConnected: Bool = false
    var isInitializing: Bool = false
    var loadingStage: LoadingStage = .idle
    var loadingProgress: Double = 0.0

    /// 选择 Session
    func selectSession(_ sessionId: String?) async {
        globalInputState.selectedSessionId = sessionId
    }
    
    /// 获取 Session
    func getSession(id: String) -> SessionState? {
        try? modelContext.fetch(FetchDescriptor<SessionState>(
            predicate: #Predicate { $0.id == id }
        )).first
    }
    
    /// 配置
    var config: AppConfig = .default
    var playSoundOnMessage: Bool = true

    /// Session 字典（计算属性，从 SwiftData 读取）
    var sessions: [String: SessionState] {
        do {
            let allSessions = try modelContext.fetch(FetchDescriptor<SessionState>())
            var dict: [String: SessionState] = [:]
            for session in allSessions {
                dict[session.id] = session
            }
            return dict
        } catch {
            return [:]
        }
    }

    /// Session 顺序（计算属性，从 SwiftData 读取）
    var sessionOrder: [String] {
        do {
            var descriptor = FetchDescriptor<SessionState>()
            descriptor.sortBy = [SortDescriptor(\.sortOrder)]
            let allSessions = try modelContext.fetch(descriptor)
            return allSessions.map(\.id)
        } catch {
            return []
        }
    }

    /// 检查 Session 名称是否已被使用
    func isSessionNameTaken(name: String) -> Bool {
        let allNames = sessions.values.map(\.name)
        return allNames.contains(name)
    }

    init() {
        let schema = Schema([SessionState.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = ModelContext(container)
            modelContext.autosaveEnabled = true
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // 加载配置
        playSoundOnMessage = UserDefaults.standard.object(forKey: "playSoundOnMessage") as? Bool ?? true

        // 启动时同步云端
        Task { @MainActor in
            await syncFromCloudOnLaunch()
        }
    }

    // MARK: - Cloud Sync on Launch

    private func syncFromCloudOnLaunch() async {
        do {
            // 检查冲突
            let result = try await checkCloudConflict()

            switch result {
            case .noConflict:
                // 无冲突：全量同步到云端
                await syncToCloud()

            case let .conflict(localCount, cloudCount):
                // 有冲突：暂时使用本地（后续添加冲突解决 UI）
                logger.warning("⚠️ Conflict detected: local=\(localCount), cloud=\(cloudCount)")
                await syncToCloud() // 本地优先
            }
        } catch {
            logger.error("❌ Cloud sync failed: \(error)")
            // 失败时使用本地数据
        }
    }

    // MARK: - Create Session

    func createSession(name: String, context: String? = nil) async -> SessionState? {
        let sessionId = SessionConfig.generateId(from: name)
        let sessionKey = SessionConfig.generateSessionKey(sessionId: sessionId)

        // 获取最大 sortOrder
        let allSessions = try? modelContext.fetch(FetchDescriptor<SessionState>())
        let maxSortOrder = allSessions?.map(\.sortOrder).max() ?? -1

        let session = SessionState(
            id: sessionId,
            sessionKey: sessionKey,
            name: name,
            context: context,
            isHidden: false,
            sortOrder: maxSortOrder + 1,
            createdAt: Date(),
            lastActivityAt: Date()
        )
        modelContext.insert(session)

        // 全量同步到云端
        Task {
            await syncToCloud()
        }

        logger.info("✅ Created session: \(name)")

        return session
    }

    // MARK: - Delete Session

    func deleteSession(id: String) {
        if let session = try? modelContext.fetch(
            FetchDescriptor<SessionState>(predicate: #Predicate { $0.id == id })
        ).first {
            modelContext.delete(session)

            // 全量同步到云端
            Task {
                await syncToCloud()
            }

            logger.info("🗑️ Deleted session: \(id)")
        }
    }

    // MARK: - Send Message

    /// 发送消息到 Session
    func sendMessage(sessionId: String, text: String) async {
        // TODO: Implement message sending logic
        logger.info("📤 Send message to session \(sessionId): \(text)")
    }

    /// 发送当前输入到选中的 Session
    func sendCurrentInput() async {
        guard let sessionId = globalInputState.selectedSessionId else { return }
        guard !globalInputState.inputText.isEmpty else { return }

        let text = globalInputState.inputText
        globalInputState.inputText = ""
        await sendMessage(sessionId: sessionId, text: text)
    }
}
