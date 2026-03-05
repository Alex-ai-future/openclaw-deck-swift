// DeckViewModel.swift
// OpenClaw Deck Swift
//
// Deck ViewModel - 使用 SwiftData（简化版）

import SwiftData
import os.log

private let logger = Logger(subsystem: "com.openclaw.deck", category: "DeckViewModel")

@Observable
@MainActor
class DeckViewModel {
    private var modelContext: ModelContext
    
    /// 全局输入状态
    let globalInputState = GlobalInputState()
    
    /// Gateway 连接状态
    var gatewayConnected: Bool = false
    var isInitializing: Bool = false
    var loadingStage: LoadingStage = .idle
    var loadingProgress: Double = 0.0
    
    /// 配置
    var config: AppConfig = .default
    var playSoundOnMessage: Bool = true
    
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
        
        Task { @MainActor in
            await migrateFromUserDefaults()
        }
    }
    
    // MARK: - Create Session
    
    func createSession(name: String, context: String? = nil) async -> SessionState? {
        let sessionId = SessionConfig.generateId(from: name)
        let sessionKey = SessionConfig.generateSessionKey(sessionId: sessionId)
        
        // 获取最大 sortOrder
        let allSessions = try? modelContext.fetch(FetchDescriptor<SessionState>())
        let maxSortOrder = allSessions?.map { $0.sortOrder }.max() ?? -1
        
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
        
        logger.info("✅ Created session: \(name)")
        
        return session
    }
    
    // MARK: - Delete Session
    
    func deleteSession(id: String) {
        if let session = try? modelContext.fetch(
            FetchDescriptor<SessionState>(predicate: #Predicate { $0.id == id })
        ).first {
            modelContext.delete(session)
            logger.info("🗑️ Deleted session: \(id)")
        }
    }
    
    // MARK: - Migration
    
    private func migrateFromUserDefaults() async {
        if UserDefaults.standard.bool(forKey: "swiftdata.migrated") {
            return
        }
        
        logger.info("📥 Migrating from UserDefaults...")
        
        let storage = UserDefaultsStorage.shared
        let sessions = storage.loadSessions()
        
        for (index, config) in sessions.enumerated() {
            let session = SessionState(
                id: config.id,
                sessionKey: config.sessionKey,
                name: config.name,
                context: config.context,
                isHidden: false,
                sortOrder: index,
                createdAt: config.createdAt,
                lastActivityAt: Date()
            )
            modelContext.insert(session)
        }
        
        // 删除旧数据
        storage.clearSessions()
        
        UserDefaults.standard.set(true, forKey: "swiftdata.migrated")
        
        logger.info("✅ Migration complete: \(sessions.count) sessions")
    }
}
