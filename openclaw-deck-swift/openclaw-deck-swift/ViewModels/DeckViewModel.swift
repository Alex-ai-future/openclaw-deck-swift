// DeckViewModel.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/24/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation
import os

private let logger = Logger(subsystem: "com.openclaw.deck", category: "DeckViewModel")

// MARK: - App State

/// 应用状态（统一连接状态 + 加载状态）
enum AppState: Equatable, CustomStringConvertible {
    case disconnected // 未连接（欢迎页面）
    case connecting(LoadingStage, Double) // 连接中（阶段 + 进度）
    case connected // 已连接（主界面）
    case error(String) // 错误状态

    var isLoading: Bool {
        if case .connecting = self { return true }
        return false
    }

    var progress: Double {
        if case let .connecting(_, progress) = self { return progress }
        return 0.0
    }

    var loadingStage: LoadingStage? {
        if case let .connecting(stage, _) = self { return stage }
        return nil
    }

    var description: String {
        switch self {
        case .disconnected:
            "disconnected"
        case let .connecting(stage, progress):
            "connecting(\(stage), \(Int(progress * 100))%)"
        case .connected:
            "connected"
        case let .error(message):
            "error(\(message))"
        }
    }
}

// MARK: - Loading Stage

/// 加载阶段枚举
enum LoadingStage: Equatable {
    case connecting // 连接 Gateway
    case fetchingSessions // 从云端获取会话列表
    case fetchingMessages // 从后端获取消息历史
    case syncingLocal // 同步到本地存储
}

// MARK: - LoadingStage: CustomStringConvertible

extension LoadingStage: CustomStringConvertible {
    var description: String {
        switch self {
        case .connecting: "connecting"
        case .fetchingSessions: "fetchingSessions"
        case .fetchingMessages: "fetchingMessages"
        case .syncingLocal: "syncingLocal"
        }
    }
}

// MARK: - LoadingStage: Title & Subtitle

extension LoadingStage {
    var title: String {
        switch self {
        case .connecting:
            "connecting_to_gateway".localized
        case .fetchingSessions:
            "fetching_sessions".localized
        case .fetchingMessages:
            "fetching_messages".localized
        case .syncingLocal:
            "syncing_to_local".localized
        }
    }

    var subtitle: String? {
        switch self {
        case .connecting:
            nil
        case .fetchingSessions:
            "fetching_sessions_from_cloudflare_kv".localized
        case .fetchingMessages:
            "fetching_messages_from_gateway".localized
        case .syncingLocal:
            "saving_to_local_storage".localized
        }
    }
}

// MARK: - Conflict Info

/// 冲突信息
struct ConflictInfo {
    let localCount: Int
    let remoteCount: Int
    let isOrderOnly: Bool
    let description: String

    static func create(local: SyncData, remote: SyncData) -> ConflictInfo {
        let localCount = local.sessions.count
        let remoteCount = remote.sessions.count

        // 检查是否只是顺序差异（内容相同但顺序不同）
        let localSet = Set(local.sessions)
        let remoteSet = Set(remote.sessions)
        let isOrderOnly = localSet == remoteSet && local.sessions != remote.sessions

        let description =
            if isOrderOnly {
                "Local and remote have the same \(localCount) sessions but in different order.\n\n• Use Local: Keep your order (overwrite cloud)\n• Use Cloud: Merge cloud order with local"
            } else if localCount == remoteCount {
                "Local and remote both have \(localCount) sessions but with different content.\n\n• Use Local: Keep local sessions (overwrite cloud)\n• Use Cloud: Merge cloud sessions with local"
            } else {
                "Local has \(localCount) sessions, Cloud has \(remoteCount) sessions.\n\n• Use Local: Keep local sessions (overwrite cloud)\n• Use Cloud: Merge cloud sessions with local"
            }

        return ConflictInfo(
            localCount: localCount,
            remoteCount: remoteCount,
            isOrderOnly: isOrderOnly,
            description: description
        )
    }
}

/// Deck ViewModel - 管理多个 Session
@MainActor
@Observable
class DeckViewModel {
    // Fix for Swift 6 @Observable + @MainActor crash in XCTest
    // See: https://github.com/swiftlang/swift/issues/87316
    nonisolated deinit {}

    // 依赖容器

    /// 是否在 UI 测试模式
    private var isUITesting: Bool {
        ProcessInfo.processInfo.environment["UITESTING"] == "YES"
    }

    private let diContainer: DIContainer

    /// Gateway 客户端
    var gatewayClient: GatewayClientProtocol?

    /// 所有 Session 状态（按 sessionId 索引）
    var sessions: [String: SessionState] = [:]

    /// Session 顺序（用于 UI 展示顺序）
    var sessionOrder: [String] = []

    /// 应用状态（统一连接状态 + 加载状态）
    var appState: AppState = .disconnected

    // MARK: - Message Queue

    /// 消息队列（网络断开时暂存消息）
    private var messageQueue: [(sessionId: String, text: String)] = []

    /// 是否正在发送队列消息
    private var isFlushingQueue: Bool = false

    /// 队列中的消息数量（用于 UI 显示）
    var messageQueueCount: Int {
        messageQueue.count
    }

    /// 应用配置
    var config: AppConfig = .default

    /// 是否正在同步
    var isSyncing: Bool = false

    /// 全局输入状态（唯一实例）
    var globalInputState: GlobalInputStateProtocol

    /// 是否显示消息发送失败弹窗
    var showMessageSendError: Bool = false

    /// 消息发送失败原因
    var messageSendErrorText: String = ""

    /// 是否显示停止操作失败弹窗
    var showStopError: Bool = false

    /// 停止失败原因
    var stopErrorText: String = ""

    /// 是否播放消息提示音
    var playSoundOnMessage: Bool = true {
        didSet {
            UserDefaults.standard.set(playSoundOnMessage, forKey: "playSoundOnMessage")
        }
    }

    /// UserDefaults 存储
    private let storage: UserDefaultsStorageProtocol

    /// 初始化（使用 DI 容器）
    /// - Parameter diContainer: 依赖容器（默认为共享实例）
    init(diContainer: DIContainer? = nil) {
        self.diContainer = diContainer ?? DIContainer.shared
        self.storage = self.diContainer.storage
        self.globalInputState = self.diContainer.createGlobalInputState()
        setupGatewayCallbacks()

        // 加载配置
        playSoundOnMessage =
            UserDefaults.standard.object(forKey: "playSoundOnMessage") as? Bool ?? true

        // ⚠️ 不在这里加载 Sessions，在 initialize() 中同步加载
    }

    /// 设置 Gateway 回调
    private func setupGatewayCallbacks() {
        // 回调将在 initialize() 中设置
    }

    /// 连接 Gateway（共用方法）
    /// - Parameters:
    /// 初始化并连接 Gateway
    /// 初始化并连接 Gateway
    func initialize(url: String, token: String?) async {
        guard !appState.isLoading else { return }
        appState = .connecting(.connecting, 0.0)

        // 🧪 UI 测试模式：跳过 Gateway 连接，直接完成初始化
        if isUITesting {
            logger.info("🧪 UI 测试模式，跳过 Gateway 连接")
            appState = .connected

            appState = .connected
            // 加载本地会话（测试环境 storage.isTesting 应该为 true）
            await loadSessionsFromStorage()
            return
        }

        appState = .connecting(.connecting, 0.5)

        // 保存到 UserDefaults
        storage.saveGatewayUrl(url)
        if let token {
            storage.saveToken(token)
        }

        guard let gatewayUrl = URL(string: url) else {
            logger.error("Invalid gateway URL: \(url)")
            gatewayClient?.connectionError = "Invalid gateway URL: \(url)"
            appState = .connected
            return
        }

        // ✅ 先加载会话列表（包括 Cloudflare 同步），确保后续操作有数据
        // 如果 sessionOrder 已经有值（解决冲突后重新调用），跳过加载
        if sessionOrder.isEmpty {
            logger.info("📥 加载会话列表...")
            appState = .connecting(.fetchingSessions, 0.3)

            await loadSessionsFromStorage()

            // ❗ 检测是否有冲突（冲突时 showingSyncConflict 会被设置）
            // 如果有冲突，停止初始化流程，等待用户解决
            if showingSyncConflict {
                logger.log("⏳ Sync conflict detected, stopping initialization")
                // 保持 appState = .connecting(.fetchingSessions, 0.3)，等待用户解决冲突
                // 不继续执行连接 Gateway 的流程
                return
            }

            logger.info("✅ 会话列表加载完成，共 \(self.sessionOrder.count) 个会话")
        } else {
            logger.info("✅ 会话列表已存在，跳过加载（\(self.sessionOrder.count) 个会话）")
        }

        // 🔧 内联 connectGateway 的逻辑
        // 先断开旧连接
        gatewayClient?.disconnect()

        // 创建新客户端
        var client = diContainer.createGatewayClient(url: gatewayUrl, token: token)

        // 设置事件回调
        client.onEvent = { [weak self] event in
            Task { @MainActor in
                self?.handleGatewayEvent(event)
            }
        }

        // 设置连接状态回调
        client.onConnection = { [weak self] connected in
            Task { @MainActor in
                guard let self else { return }
                if connected {
                    logger.log("✅ Gateway 连接成功")

                    // 🔧 内联 onConnect 回调的逻辑
                    // 重连时重置所有 session 的处理状态
                    for session in self.sessions.values {
                        session.status = .idle
                        session.activeRunId = nil
                    }

                    // ✅ 重连成功，发送队列中的消息
                    await self.flushMessageQueue()

                    // ✅ 只在初始化时显示加载动画，重连成功时不显示
                    if self.appState.isLoading {
                        // 🔧 内联 initializeAfterConnect() 的逻辑
                        // 连接成功，更新进度
                        self.appState = .connecting(.connecting, 0.5)
                        // 检查是否有会话列表
                        if self.sessionOrder.isEmpty {
                            logger.warning("⚠️ 没有会话列表，跳过消息加载")
                        } else {
                            // 加载所有历史
                            await self.loadAllSessionHistory()
                        }

                        // 所有数据加载完成，设置 100% 进度
                        if case let .connecting(stage, _) = self.appState {
                            self.appState = .connecting(stage, 1.0)
                        }

                        // 初始化完成，立即切换到 connected 状态（无延迟）
                        self.appState = .connected
                    } else {
                        // ✅ 重连成功，不显示加载动画
                        self.appState = .connected
                        logger.log("✅ 重连成功，保持当前界面")
                    }

                } else {
                    logger.error("❌ Gateway 连接失败")
                    self.appState = .disconnected
                    // 获取错误信息
                    // 连接失败，错误信息已在 client 中
                }
            }
        }

        gatewayClient = client
        // 错误信息已在 client 中

        // 异步连接 Gateway
        await client.connect()
    }

    /// 清除连接错误
    func clearConnectionError() {
        gatewayClient?.connectionError = nil
        gatewayClient?.clearError()
    }

    /// 断开 Gateway 连接
    /// - Note: 断开连接时保留所有历史消息，不清空数据
    func disconnect() {
        // 只断开连接，不清空 Session 消息（保留离线浏览能力）
        gatewayClient?.disconnect()
    }

    /// 重置设备身份（清除 device identity 和 device token）
    func resetDeviceIdentity() {
        gatewayClient?.resetDeviceIdentity()
    }

    /// 设置当前选中的 Session
    func selectSession(_ sessionId: String?) {
        globalInputState.selectedSessionId = sessionId
    }

    /// 发送当前输入（全局入口）
    func sendCurrentInput() async {
        guard let sessionId = globalInputState.selectedSessionId,
              let session = getSession(sessionId: sessionId)
        else {
            return
        }

        await globalInputState.sendMessage(to: session, viewModel: self)
    }

    // MARK: - Session Management

    // 创建新 Session
    // - Parameters:
    //   - name: Session 名称
    //   - icon: 可选的图标
    //   - context: 可选的上下文描述
    // - Returns: 创建的 SessionConfig

    /// 检查 Session 名称是否已被使用
    /// - Parameter name: 要检查的名称
    /// - Returns: 如果名称已存在返回 true
    func isSessionNameTaken(name: String) -> Bool {
        SessionConfig.isNameTaken(name: name, existingSessions: sessions)
    }

    func createSession(
        name: String,
        icon: String? = nil,
        context: String? = nil
    ) -> SessionConfig {
        // 1. 生成 Session ID
        let sessionId = SessionConfig.generateId(from: name)

        // 2. 生成 Session Key
        let sessionKey = SessionConfig.generateSessionKey(sessionId: sessionId)

        // 3. 创建 SessionConfig
        let sessionConfig = SessionConfig(
            id: sessionId,
            sessionKey: sessionKey,
            createdAt: Date(),
            name: name,
            icon: icon ?? String(name.prefix(1)).uppercased(),
            context: context ?? name
        )

        // 4. 创建 SessionState
        let sessionState = SessionState(
            sessionId: sessionId,
            sessionKey: sessionKey,
            context: context,
            name: name
        )

        // 5. 添加到 sessions（使用小写 key 确保与 Gateway 一致）
        let sessionIdLower = sessionId.lowercased()
        sessions[sessionIdLower] = sessionState
        sessionOrder.insert(sessionIdLower, at: 0) // 插入到开头，让新 Session 在最左边

        // 6. 保存到 UserDefaults
        saveSessionsToStorage()

        // 7. 如果已连接，加载历史消息
        if gatewayClient?.connected ?? false, ProcessInfo.processInfo.environment["UITESTING"] != "YES" {
            Task {
                await loadSessionHistory(sessionKey: sessionKey)
            }
        }

        return sessionConfig
    }

    /// 创建 Welcome Session（当没有 session 时自动创建）
    private func createWelcomeSession() {
        // 使用 createSession 方法创建
        _ = createSession(name: "main")
    }

    /// 删除 Session
    /// - Parameter sessionId: 要删除的 Session ID
    func deleteSession(sessionId: String) {
        logger.log("🗑️ 删除会话：\(sessionId)")

        // 1. 从 sessions 中移除（使用小写 key）
        sessions.removeValue(forKey: sessionId.lowercased())

        // 2. 从 sessionOrder 中移除
        sessionOrder.removeAll { $0 == sessionId.lowercased() }

        logger.log("✅ 会话已从本地删除，剩余 \(self.sessionOrder.count) 个会话")

        // 3. 保存到 UserDefaults（会自动同步到云端）
        saveSessionsToStorage()
        logger.log("📡 已触发云端同步（异步）")

        // 4. 如果删除后没有 session 了，创建 welcome session
        if sessions.isEmpty {
            logger.log("📭 没有会话了，创建 Welcome session")
            createWelcomeSession()
        }

        // 注意：Gateway 中的消息历史不会被删除
        // Session Key 可以继续使用，下次创建同名 Session 会加载历史
    }

    /// 获取 Session
    /// - Parameter sessionId: Session ID
    /// - Returns: SessionState（如果存在）
    func getSession(sessionId: String) -> SessionState? {
        // 大小写不敏感匹配
        sessions[sessionId.lowercased()]
    }

    // MARK: - Storage

    /// 从 UserDefaults 加载 Sessions（带 Cloudflare 同步）
    private func loadSessionsFromStorage() async {
        logger.log("📥 加载 Sessions...")

        // 🧪 UI 测试模式：跳过云端同步
        if ProcessInfo.processInfo.environment["UITESTING"] == "YES" {
            logger.log("🧪 UI 测试模式，使用本地数据")
            loadFromLocalOnly()
            return
        }

        // 测试环境跳过云端同步
        if storage.isTesting {
            logger.log("🧪 测试环境，使用本地数据")
            loadFromLocalOnly()
            return
        }

        // ✅ 如果有 Mock 实例，使用 Mock（即使没有配置 Cloudflare）
        if CloudflareKV.mockInstance != nil {
            logger.log("🧪 检测到 Mock Cloudflare，使用 Mock 实例")
            await loadSessionsWithCloudflareSync()
            return
        }

        // 尝试从 Cloudflare 同步（如果已配置）
        if CloudflareKV.shared.isConfigured {
            logger.log("☁️ Cloudflare 已配置，开始同步...")
            await loadSessionsWithCloudflareSync()
        } else {
            logger.log("📱 未配置 Cloudflare，使用本地数据")
            // 没有配置 Cloudflare，使用本地数据
            loadFromLocalOnly()
        }
    }

    /// 测试专用：加载 Sessions（测试用）
    @MainActor func loadSessionsFromStorageForTesting() async {
        appState = .connecting(.fetchingSessions, 0.3)

        await loadSessionsFromStorage()
        // 恢复为 connecting 状态，等待连接成功
        appState = .connecting(.connecting, 0.5)
    }

    /// 从 Cloudflare 同步加载 Sessions
    private func loadSessionsWithCloudflareSync() async {
        do {
            logger.log("🔄 开始智能同步...")

            // 智能同步：返回本地和云端数据，自动处理一致情况，冲突时弹窗
            let result = try await CloudflareKV.shared.syncAndGet()

            // 检测是否需要用户选择
            if result.source == .conflict {
                // 数据冲突，需要用户选择
                await handleSyncConflict(result: result)
                return
            }

            logger.log("✅ 同步成功：\(result.data.sessions.count) 个 sessions")

            // 使用同步后的数据
            await MainActor.run {
                self.sessionOrder = result.data.sessions.map { $0.lowercased() }
                self.createSessionStates()

                logger.log("📋 Session 顺序：\(self.sessionOrder)")

                // 默认选中第一个 Session
                if let firstSessionId = sessionOrder.first {
                    globalInputState.selectedSessionId = firstSessionId
                    logger.log("🎯 选中 Session: \(firstSessionId)")
                }
            }
        } catch {
            logger.error("❌ Cloudflare sync failed: \(error.localizedDescription)")
            // 同步失败，退化到本地数据
            await MainActor.run {
                self.loadFromLocalOnly()
            }
        }
    }

    /// 处理同步冲突（弹窗让用户选择）
    @MainActor
    private func handleSyncConflict(result: MergeResult) async {
        guard let localData = result.localData, let remoteData = result.remoteData else {
            logger.error("❌ handleSyncConflict: missing localData or remoteData")
            return
        }

        logger.log(
            "⚠️ Data conflict detected: local \(localData.sessions.count) sessions, remote \(remoteData.sessions.count) sessions"
        )

        // 设置冲突数据，供 UI 层显示
        conflictLocalData = localData
        conflictRemoteData = remoteData
        conflictInfo = ConflictInfo.create(local: localData, remote: remoteData)
        showingSyncConflict = true

        logger.log("✅ showingSyncConflict set to TRUE, UI should show conflict alert")
        logger.log("⏳ Waiting for user selection...")
        // ✅ initialize() 会检测 showingSyncConflict 状态并停止执行
    }

    /// 冲突时的本地数据（用于弹窗显示）
    var conflictLocalData: SyncData?

    /// 冲突时的云端数据（用于弹窗显示）
    var conflictRemoteData: SyncData?

    /// 是否显示同步冲突弹窗
    var showingSyncConflict: Bool = false

    /// 冲突信息（用于弹窗说明）
    var conflictInfo: ConflictInfo?

    /// 用户选择同步方案
    @MainActor
    func resolveSyncConflict(choice: String) async {
        showingSyncConflict = false

        guard let localData = conflictLocalData, let remoteData = conflictRemoteData else {
            return
        }

        switch choice {
        case "local":
            // Use local data (overwrite cloud)
            logger.log("✅ User selected: local data (\(localData.sessions.count) sessions)")
            await applySyncData(localData)

        case "remote":
            // Use cloud data (merge with local)
            logger.log("✅ User selected: cloud data (\(remoteData.sessions.count) sessions)")
            await applySyncData(remoteData)

        default:
            // Cancel, do nothing
            logger.log("⚠️ User cancelled sync")
            return
        }

        // Clear conflict data
        conflictLocalData = nil
        conflictRemoteData = nil
        conflictInfo = nil

        // ✅ 继续完成初始化流程（连接 Gateway + 加载历史）
        // 从 UserDefaults 读取配置
        let gatewayUrl = storage.loadGatewayUrl() ?? "ws://127.0.0.1:18789"
        let token = storage.loadToken()

        guard let url = URL(string: gatewayUrl) else {
            logger.error("❌ Invalid gateway URL: \(gatewayUrl)")
            appState = .connected
            appState = .connected
            return
        }

        // 🔧 内联 connectGateway 的逻辑
        // 先断开旧连接
        gatewayClient?.disconnect()

        // 创建新客户端
        var client = diContainer.createGatewayClient(url: url, token: token)

        // 设置事件回调
        client.onEvent = { [weak self] event in
            Task { @MainActor in
                self?.handleGatewayEvent(event)
            }
        }

        // 设置连接状态回调
        client.onConnection = { [weak self] connected in
            Task { @MainActor in
                guard let self else { return }
                if connected {
                    logger.log("✅ Gateway 连接成功")

                    // 连接成功后加载历史
                    await self.loadAllSessionHistory()
                    // 初始化完成
                    logger.log("✅ Sync conflict resolved, initialization complete")

                } else {
                    logger.error("❌ Gateway 连接失败")
                    self.appState = .disconnected
                    // 连接失败，错误信息已在 client 中
                }
            }
        }

        gatewayClient = client
        // 错误信息已在 client 中

        // 异步连接 Gateway
        await client.connect()
    }

    /// 应用同步数据
    @MainActor
    private func applySyncData(_ data: SyncData) async {
        sessionOrder = data.sessions.map { $0.lowercased() }
        createSessionStates()

        // Save to local
        let storage = UserDefaultsStorage.shared
        storage.saveSessionOrder(data.sessions)
        UserDefaults.standard.set(
            data.lastUpdated, forKey: "openclaw.deck.sessionOrder.lastUpdated"
        )

        // Always save to cloud when resolving conflict (user explicitly chose)
        do {
            try await CloudflareKV.shared.save(data)
            logger.info("✅ Saved to cloud: \(data.sessions.count) sessions")
        } catch {
            logger.error("❌ Failed to save to cloud: \(error.localizedDescription)")
        }

        logger.log("✅ Sync complete: \(data.sessions.count) sessions")

        // If Gateway connected, load history
        if gatewayClient?.connected ?? false, ProcessInfo.processInfo.environment["UITESTING"] != "YES" {
            await loadAllSessionHistory()
        }
    }

    /// 仅从本地加载 Sessions（退化模式）
    private func loadFromLocalOnly() {
        logger.log("📱 从本地加载 Sessions...")

        let configs = storage.loadSessions()
        let order = storage.loadSessionOrder()

        logger.log("📋 本地 configs: \(configs.count) 个，order: \(order.count) 个")

        // 如果没有 session，创建 welcome session
        if configs.isEmpty {
            logger.log("📭 本地没有 session，创建 Welcome session")
            createWelcomeSession()
            // ✅ 重置加载状态，避免卡在 100%
            appState = .connected

            return
        }

        // 使用小写 key 确保与 Gateway 一致
        for config in configs {
            let idLower = config.id.lowercased()
            sessions[idLower] = SessionState(
                sessionId: config.id,
                sessionKey: config.sessionKey,
                context: config.context,
                name: config.name
            )
        }

        // 也小写化 sessionOrder
        if order.isEmpty {
            sessionOrder = configs.map { $0.id.lowercased() }
        } else {
            sessionOrder = order.map { $0.lowercased() }
        }

        // 默认选中第一个 Session
        if let firstSessionId = sessionOrder.first {
            globalInputState.selectedSessionId = firstSessionId
            logger.log("🎯 选中 Session: \(firstSessionId)")
        }

        // 如果 Gateway 已连接，立即加载历史消息
        if gatewayClient?.connected ?? false, ProcessInfo.processInfo.environment["UITESTING"] != "YES" {
            logger.log("🔗 Gateway 已连接，加载历史消息...")
            Task {
                await loadAllSessionHistory()
            }
        }

        // ✅ 重置加载状态，避免卡在 100%
        appState = .connected
    }

    /// 创建 Session 状态（从 sessionOrder）
    private func createSessionStates() {
        logger.log("🏗️ 创建 Session 状态...")

        // 为每个 Session ID 创建 SessionState
        for sessionId in sessionOrder {
            if sessions[sessionId] == nil {
                let sessionKey = SessionConfig.generateSessionKey(sessionId: sessionId)
                sessions[sessionId] = SessionState(
                    sessionId: sessionId,
                    sessionKey: sessionKey
                )
                logger.log("  + \(sessionId)")
            }
        }
    }

    /// 保存 Sessions 到 UserDefaults（并同步到 Cloudflare）
    func saveSessionsToStorage() {
        let configs = sessionOrder.compactMap { id -> SessionConfig? in
            guard let state = self.sessions[id] else { return nil }
            return SessionConfig(
                id: state.sessionId,
                sessionKey: state.sessionKey,
                createdAt: Date(),
                name: state.sessionId,
                icon: nil,
                context: state.context
            )
        }

        storage.saveSessions(configs)
        storage.saveSessionOrder(sessionOrder)

        // 更新最后更新时间
        UserDefaults.standard.set(
            ISO8601DateFormatter().string(from: Date()),
            forKey: "openclaw.deck.sessionOrder.lastUpdated"
        )

        // 测试环境跳过云端同步
        if storage.isTesting {
            logger.log("🧪 测试环境，跳过云端同步")
        } else if CloudflareKV.shared.isConfigured {
            // 生产环境，同步到云端
            Task {
                await syncToCloudflare()
            }
        }
    }

    /// 同步到 Cloudflare KV
    private func syncToCloudflare() async {
        logger.log("☁️ 开始同步到 Cloudflare KV，共 \(self.sessionOrder.count) 个会话...")

        do {
            let syncData = SyncData(
                sessions: sessionOrder, lastUpdated: ISO8601DateFormatter().string(from: Date())
            )
            try await CloudflareKV.shared.save(syncData)
            logger.log("✅ 成功同步到 Cloudflare KV")
        } catch {
            logger.error("❌ Cloudflare sync failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Sync

    /// 同步操作（带状态管理）
    /// - Returns: 同步结果（成功/失败消息）
    @MainActor
    func handleSync() async -> Result<String, Error> {
        // 🧪 UI 测试模式：跳过真正的同步，直接返回成功
        if ProcessInfo.processInfo.environment["UITESTING"] == "YES" {
            logger.info("🧪 UI 测试模式，跳过真正的同步")
            return .success("Sync complete (mock)")
        }

        // isSyncing 已经在点击同步按钮时设置为 true
        // 同步完成后重置为 false
        defer { isSyncing = false }
        return await syncAll()
    }

    /// 完整同步：Cloudflare（Session 列表）+ Gateway（对话内容）
    /// - Returns: 同步结果（成功/失败消息）
    @MainActor
    func syncAll() async -> Result<String, Error> {
        // 先检查 Gateway 是否已连接
        guard gatewayClient?.connected ?? false else {
            return .failure(
                NSError(
                    domain: "DeckViewModel", code: 400,
                    userInfo: [NSLocalizedDescriptionKey: "Gateway not connected"]
                )
            )
        }

        guard let gatewayUrl = UserDefaults.standard.string(forKey: "openclaw.deck.gatewayUrl"),
              let url = URL(string: gatewayUrl)
        else {
            return .failure(
                NSError(
                    domain: "DeckViewModel", code: 400,
                    userInfo: [NSLocalizedDescriptionKey: "Gateway URL not configured"]
                )
            )
        }

        do {
            logger.info("🔄 Starting full sync...")

            // ✅ 立即显示加载动画
            appState = .connecting(.fetchingSessions, 0.1)

            // 1. 从 Cloudflare 同步 Session 列表
            let result = try await CloudflareKV.shared.syncAndGet()

            // 处理冲突情况
            if result.source == .conflict {
                logger.info("⚠️ Conflict detected during sync, showing conflict dialog")
                await handleSyncConflict(result: result)
                return .failure(
                    NSError(
                        domain: "DeckViewModel", code: 409,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Sync conflict: please select data source",
                        ]
                    )
                )
            }

            // 更新本地 sessions
            sessionOrder = result.data.sessions.map { $0.lowercased() }
            createSessionStates()
            saveSessionsToStorage()

            logger.info("✅ Session list updated: \(result.data.sessions.count) sessions")

            appState = .connecting(.fetchingMessages, 0.5)

            // 清空所有 Session 的当前消息
            for session in sessions.values {
                session.messages.removeAll()
                session.messageLoadState = .notLoaded
            }

            // 并发加载所有 Session 的对话内容
            await loadAllSessionHistoryConcurrent()

            logger.info("✅ Sync complete (concurrent): \(result.data.sessions.count) sessions")

            appState = .connected

            return .success("Sync complete: \(result.data.sessions.count) sessions")
        } catch {
            logger.error("❌ Sync failed: \(error.localizedDescription)")
            return .failure(error)
        }
    }

    // MARK: - Load History

    /// 加载所有 Session 的历史消息（已优化为并发版本）
    @MainActor
    func loadAllSessionHistory() async {
        // 使用并发版本
        await loadAllSessionHistoryConcurrent()
    }

    /// 加载单个 Session 的历史消息（保留用于向后兼容）
    @MainActor
    private func loadSessionHistoryLegacy(sessionKey: String) async {
        guard let client = gatewayClient, client.connected else {
            return
        }

        // 设置加载状态（大小写不敏感匹配）
        if let session = sessions.values.first(where: {
            $0.sessionKey.lowercased() == sessionKey.lowercased()
        }) {
            session.messageLoadState = .loading
        }

        do {
            let messages = try await client.getSessionHistory(sessionKey: sessionKey) ?? []

            // 更新 Session 的消息（大小写不敏感匹配）
            if let session = sessions.values.first(where: {
                $0.sessionKey.lowercased() == sessionKey.lowercased()
            }) {
                session.messages = messages
                session.messageLoadState = .loaded
                logger.info("  ↳ 加载 \(messages.count) 条消息")
            }
        } catch {
            logger.error("❌ 加载 Session \(sessionKey) 历史失败：\(error.localizedDescription)")
            if let session = sessions.values.first(where: {
                $0.sessionKey.lowercased() == sessionKey.lowercased()
            }) {
                session.messageLoadState = .error(error.localizedDescription)
            }
        }
    }

    func loadSessionHistory(sessionKey: String) async {
        guard let client = gatewayClient, client.connected else {
            return
        }

        // 设置加载状态（大小写不敏感匹配）
        if let session = sessions.values.first(where: {
            $0.sessionKey.lowercased() == sessionKey.lowercased()
        }) {
            session.messageLoadState = .loading
        }

        do {
            let messages = try await client.getSessionHistory(sessionKey: sessionKey) ?? []

            // 更新 Session 的消息（大小写不敏感匹配）
            if let session = sessions.values.first(where: {
                $0.sessionKey.lowercased() == sessionKey.lowercased()
            }) {
                session.messages = messages
                session.messageLoadState = .loaded
                logger.info("  ↳ 加载 \(messages.count) 条消息")
            }
        } catch {
            logger.error("❌ 加载 Session \(sessionKey) 历史失败：\(error.localizedDescription)")
            if let session = sessions.values.first(where: {
                $0.sessionKey.lowercased() == sessionKey.lowercased()
            }) {}
        }
    }

    // MARK: - Send Message

    /// 发送消息（统一入口）
    /// - Parameters:
    ///   - sessionId: Session ID
    ///   - text: 消息文本
    func sendMessage(sessionId: String, text: String) async {
        // ✅ 检查连接，未连接则入队
        guard let client = gatewayClient, client.connected else {
            // 未连接，添加到队列
            logger.info("⏳ 网络未连接，消息已加入队列：\(text.prefix(20))...")
            messageQueue.append((sessionId, text))
            return
        }

        // ✅ 已连接，正常发送
        await sendOrRequeueMessage(sessionId: sessionId, text: text)
    }

    // MARK: - Message Queue

    /// 发送队列中的消息（重连成功后调用）
    @MainActor
    private func flushMessageQueue() async {
        guard !messageQueue.isEmpty else { return }
        guard !isFlushingQueue else {
            logger.warning("⚠️ 队列正在处理中，跳过")
            return
        }

        isFlushingQueue = true
        logger.info("📤 开始发送队列中的 \(self.messageQueue.count) 条消息...")

        // 复制队列，避免并发问题
        let queue = messageQueue
        messageQueue.removeAll()

        for (sessionId, text) in queue {
            logger.info("📤 发送队列消息：\(text.prefix(30))...")
            await sendOrRequeueMessage(sessionId: sessionId, text: text)

            // 小延迟，避免过快发送
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 秒
        }

        isFlushingQueue = false

        // 如果队列中还有消息（发送失败的），继续等待下次重连
        if !messageQueue.isEmpty {
            logger.warning("⚠️ 队列中还有 \(self.messageQueue.count) 条消息发送失败，等待下次重连")
        } else {
            logger.info("✅ 队列消息全部发送完成")
        }
    }

    /// 发送消息或重新排队（内部方法）
    /// - Parameters:
    ///   - sessionId: Session ID
    ///   - text: 消息文本
    private func sendOrRequeueMessage(sessionId: String, text: String) async {
        guard let client = gatewayClient, client.connected else {
            // 发送时断网，重新排队
            logger.warning("⚠️ 发送失败，消息已重新加入队列：\(text.prefix(20))...")
            messageQueue.append((sessionId, text))
            return
        }

        guard let session = getSession(sessionId: sessionId) else {
            return
        }

        // 1. 先添加用户消息到 UI（乐观更新）
        let userMsg = ChatMessage(
            id: UUID().uuidString,
            role: .user,
            text: text,
            timestamp: Date()
        )
        session.messages.append(userMsg)

        // 2. 设置状态
        session.status = .thinking
        session.activeRunId = "pending-\(UUID().uuidString)"

        // 3. 后台调用 runAgent
        Task { [weak self] in
            guard let self else { return }

            do {
                _ = try await client.runAgent(
                    agentId: config.mainAgentId,
                    message: text,
                    sessionKey: session.sessionKey
                )
                // ✅ 发送成功

            } catch {
                logger.error("❌ 发送失败，加入队列重试：\(error.localizedDescription)")
                await MainActor.run {
                    // ✅ 保留消息，不移除
                    // 消息会保持显示，等待队列重发成功

                    // ✅ 重新加入队列（等待重连后重发）
                    self.messageQueue.append((sessionId, text))

                    // 重置 session 状态（避免 UI 卡住）
                    session.status = .idle
                    session.activeRunId = nil
                }
            }
        }
    }

    /// 显示连接错误弹窗（多语言）
    private func showConnectionErrorAlert() {
        messageSendErrorText = "connection_error_please_reconnect".localized
        showMessageSendError = true
    }

    // MARK: - Event Handling

    /// 处理 Gateway 事件
    /// - Parameter event: Gateway 事件
    func handleGatewayEvent(_ event: GatewayEvent) {
        // 📝 聊天事件日志
        if event.event == "chat" {
            // 保留关键错误信息
            if let payload = event.payload as? [String: Any],
               let state = payload["state"] as? String,
               state == "error",
               let errorMessage = payload["errorMessage"] as? String
            {
                logger.error("❌ Chat event error: \(errorMessage)")
            }
        }

        switch event.event {
        case "agent":
            // 新的 agent 事件格式：{ runId, stream, data, sessionKey }
            handleAgentEvent(event)
        case "agent.content":
            // 兼容旧的 agent.content 事件格式（增量事件，不记录日志）
            handleAgentContent(event)
        case "agent.thinking", "agent.tool_use", "agent.status", "agent.parameter":
            // 忽略 thinking、tool_use、status、parameter 事件，不显示这些消息
            break
        case "agent.done":
            handleAgentDone(event)
        case "agent.error":
            logger.error("Agent error")
            handleAgentError(event)
        // 忽略保活和健康检查事件
        case "tick", "health", "heartbeat":
            break
        default:
            // 忽略未知事件类型
            break
        }
    }

    /// 处理 agent 事件（新格式）
    private func handleAgentEvent(_ event: GatewayEvent) {
        guard let payload = event.payload as? [String: Any],
              let runId = payload["runId"] as? String,
              let stream = payload["stream"] as? String
        else {
            logger.error("Invalid agent event payload")
            return
        }

        logger.info("📥 Agent event: stream=\(stream), runId=\(runId)")

        // 查找对应的 session
        guard let session = findSessionForEvent(event) else {
            logger.warning("⚠️ Session not found for agent event: stream=\(stream)")
            return
        }

        switch stream {
        case "assistant":
            // 流式内容：{ data: { delta: "..." } } 或 { data: { text: "..." } }
            if let data = payload["data"] as? [String: Any] {
                let seq = payload["seq"] as? Int
                let delta = data["delta"] as? String
                let text = data["text"] as? String

                logger.info("📥 Assistant event: delta=\(delta?.count ?? 0) chars, text=\(text?.count ?? 0) chars, seq=\(seq ?? -1), runId=\(runId)")

                // 如果有 seq，检查是否已处理（去重）
                if let seq {
                    let alreadyProcessed = session.messages.contains { $0.seq == seq }
                    if alreadyProcessed {
                        logger.debug("⏭️ Message already processed, skipping: seq=\(seq)")
                        return
                    }
                }

                // 优先使用 delta 追加（流式更新）
                if let delta, !delta.isEmpty {
                    appendToAssistantMessage(session: session, runId: runId, text: delta, seq: seq)
                }
                // 后备：使用 text（只在没有 delta 且没有同 runId 消息时）
                else if let text, !text.isEmpty {
                    let hasExistingMessage = session.messages.contains {
                        $0.runId == runId && $0.role == .assistant
                    }

                    if !hasExistingMessage {
                        createAssistantMessage(session: session, runId: runId, text: text, seq: seq)
                    } else {
                        logger.warning("⚠️ Existing message found for runId=\(runId), skipping text")
                    }
                }
            }

        case "lifecycle":
            // 生命周期：{ data: { phase: "start" | "end" } }
            if let data = payload["data"] as? [String: Any],
               let phase = data["phase"] as? String,
               let runId = payload["runId"] as? String
            {
                switch phase {
                case "start":
                    session.status = .thinking
                    // ✅ 设置 activeRunId（此时 Gateway 已创建 AbortController）
                    session.activeRunId = runId
                case "end":
                    session.hasUnreadMessage = true // 总是标记为未读
                    session.status = .idle
                    session.activeRunId = nil

                    // 🎯 发送通知：agent 运行结束就通知（和消息类型无关）
                    NotificationService.shared.sendNewMessageNotification(
                        sessionName: session.sessionId,
                        messageText: "任务完成"
                    )

                    // 🎵 播放提示音（如果启用）- agent 完成就播放
                    if playSoundOnMessage {
                        SoundService.shared.playMessageNotification()
                    }

                    // 清除所有消息的 streaming 状态
                    for i in session.messages.indices {
                        if session.messages[i].streaming == true {
                            session.messages[i].streaming = false
                        }
                    }
                default:
                    break
                }
            }

        case "tool":
            // 工具调用事件：{ data: { name: "exec", phase: "start"|"result", meta: "...", ... } }
            if let data = payload["data"] as? [String: Any],
               let toolName = data["name"] as? String
            {
                logger.info("🔍 Processing tool event: toolName=\(toolName)")

                // 提取参数信息（优先使用 meta，其次使用 args）
                var argsText: String?
                if let meta = data["meta"] as? String, !meta.isEmpty {
                    // 使用 meta 字段（包含工具调用的详细信息）
                    argsText = meta
                } else if let args = data["args"] as? [String: Any], !args.isEmpty {
                    let params = args.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                    if !params.isEmpty {
                        argsText = params
                    }
                } else if let args = data["args"] as? String, !args.isEmpty {
                    argsText = args
                }

                // 如果没有参数，不创建消息
                guard let args = argsText else {
                    logger.info("⚠️ Tool call has no args, skipping message: \(toolName)")
                    return
                }

                // 创建工具调用消息
                let toolMessage = ChatMessage(
                    id: UUID().uuidString,
                    role: .tool,
                    text: "🔧 Tool: **\(toolName)**\nArgs: \(args)",
                    timestamp: Date(),
                    runId: runId,
                    seq: payload["seq"] as? Int
                )

                session.messages.append(toolMessage)
                logger.info("✅ Tool message added: sessionId=\(session.sessionId), messages.count=\(session.messages.count)")
            } else {
                logger.error("❌ Failed to parse tool event data")
            }

        default:
            break
        }
    }

    /// 更新或创建最后一条 assistant 消息（实时流式更新）
    private func updateOrCreateLastAssistantMessage(
        session: SessionState, runId: String, text: String, seq: Int?
    ) {
        session.status = .streaming

        // 查找最后一条同 runId 的 streaming 消息
        guard
            let index = session.messages.enumerated().last(where: { _, msg in
                msg.role == .assistant && msg.runId == runId && msg.streaming == true
            })?.offset
        else {
            // 没有找到，创建新消息
            let assistantMsg = ChatMessage(
                id: UUID().uuidString,
                role: .assistant,
                text: text,
                timestamp: Date(),
                streaming: true,
                runId: runId,
                seq: seq
            )
            session.messages.append(assistantMsg)
            session.activeRunId = runId
            return
        }

        // 更新现有消息（替换文本）
        let message = session.messages[index]
        session.messages[index] = ChatMessage(
            id: message.id,
            role: message.role,
            text: text,
            timestamp: message.timestamp,
            streaming: message.streaming,
            thinking: message.thinking,
            toolUse: message.toolUse,
            runId: message.runId,
            seq: message.seq ?? seq,
            isLoaded: message.isLoaded
        )
    }

    /// 创建或更新最后一条 assistant 消息
    /// - Parameters:
    ///   - session: Session 状态
    ///   - runId: 运行 ID
    ///   - text: 消息文本（累积）
    ///   - seq: Gateway 事件序号
    private func createOrUpdateLastAssistantMessage(
        session: SessionState, runId: String, text: String, seq: Int?
    ) {
        session.status = .streaming

        // 查找最后一条同 runId 的 streaming 消息
        guard
            let index = session.messages.enumerated().last(where: { _, msg in
                msg.role == .assistant && msg.runId == runId && msg.streaming == true
            })?.offset
        else {
            // 没有找到，创建新消息
            let assistantMsg = ChatMessage(
                id: UUID().uuidString,
                role: .assistant,
                text: text,
                timestamp: Date(),
                streaming: true,
                runId: runId,
                seq: seq
            )
            session.messages.append(assistantMsg)
            session.activeRunId = runId
            return
        }

        // 更新现有消息（替换文本）
        let message = session.messages[index]
        session.messages[index] = ChatMessage(
            id: message.id,
            role: message.role,
            text: text, // 替换为累积文本
            timestamp: message.timestamp,
            streaming: message.streaming,
            thinking: message.thinking,
            toolUse: message.toolUse,
            runId: message.runId,
            seq: message.seq ?? seq,
            isLoaded: message.isLoaded
        )
    }

    /// 创建新的 assistant 消息（用于完整文本模式）
    /// - Parameters:
    ///   - session: Session 状态
    ///   - runId: 运行 ID
    ///   - text: 消息文本
    ///   - seq: Gateway 事件序号（用于去重）
    private func createAssistantMessage(
        session: SessionState, runId: String, text: String, seq: Int?
    ) {
        // 设置状态为 streaming
        session.status = .streaming

        // 检查是否已有相同 seq 的消息（避免重复）
        if let seq {
            let existingMsg = session.messages.first {
                $0.runId == runId && $0.seq == seq
            }

            if existingMsg != nil {
                // 消息已存在，跳过
                logger.debug("Message with seq \(seq) already exists, skipping")
                return
            }
        }

        // 创建新消息
        let assistantMsg = ChatMessage(
            id: UUID().uuidString,
            role: .assistant,
            text: text,
            timestamp: Date(),
            streaming: true,
            runId: runId,
            seq: seq
        )
        session.messages.append(assistantMsg)
        session.activeRunId = runId
    }

    /// 替换 assistant 消息内容（用于累积文本模式 - 兼容旧格式）
    private func replaceAssistantMessage(session: SessionState, runId: String, text: String) {
        // 设置状态为 streaming
        session.status = .streaming

        // 查找对应的消息
        guard
            let index = session.messages.enumerated().first(where: { _, msg in
                msg.role == .assistant && msg.runId == runId
            })?.offset
        else {
            // 如果没有找到消息，创建一个新的
            let assistantMsg = ChatMessage(
                id: UUID().uuidString,
                role: .assistant,
                text: text,
                timestamp: Date(),
                streaming: true,
                runId: runId
            )
            session.messages.append(assistantMsg)
            session.activeRunId = runId
            return
        }

        // 替换文本
        let message = session.messages[index]
        session.messages[index] = ChatMessage(
            id: message.id,
            role: message.role,
            text: text, // 替换而不是追加
            timestamp: message.timestamp,
            streaming: message.streaming,
            thinking: message.thinking,
            toolUse: message.toolUse,
            runId: message.runId,
            isLoaded: message.isLoaded
        )
    }

    /// 追加内容到 assistant 消息（用于 delta 流式更新）
    private func appendToAssistantMessage(
        session: SessionState, runId: String, text: String, seq: Int?
    ) {
        // 设置状态为 streaming
        session.status = .streaming

        // ✅ 1. 用 seq 去重
        if let seq, session.messages.contains(where: { $0.seq == seq }) {
            logger.debug("⏭️ Message already processed, skipping: seq=\(seq)")
            return
        }

        // ✅ 2. 检查最后一条消息
        let lastMsg = session.messages.last
        if let lastMsg, lastMsg.role == .assistant, lastMsg.streaming == true {
            // 最后一条是 assistant 且还在 streaming → 追加
            session.messages[session.messages.count - 1] = ChatMessage(
                id: lastMsg.id,
                role: lastMsg.role,
                text: lastMsg.text + text,
                timestamp: lastMsg.timestamp,
                streaming: lastMsg.streaming,
                thinking: lastMsg.thinking,
                toolUse: lastMsg.toolUse,
                runId: lastMsg.runId,
                seq: lastMsg.seq ?? seq,
                isLoaded: lastMsg.isLoaded
            )
            logger.debug("➕ Appended to last assistant message: runId=\(runId)")
        } else {
            // 最后一条是 tool / user / system 或 assistant 已结束 → 创建新消息
            let assistantMsg = ChatMessage(
                id: UUID().uuidString,
                role: .assistant,
                text: text,
                timestamp: Date(),
                streaming: true,
                runId: runId,
                seq: seq
            )
            session.messages.append(assistantMsg)
            session.activeRunId = runId
            logger.debug("➕ Created new assistant message: runId=\(runId), seq=\(seq ?? -1)")
        }
    }

    /// 处理 agent.content 事件（旧格式兼容）
    private func handleAgentContent(_ event: GatewayEvent) {
        // 从 payload 中提取文本
        guard let payload = event.payload as? [String: Any],
              let text = payload["text"] as? String
        else {
            return
        }

        // 找到对应的 Session
        guard let session = findSessionForEvent(event) else {
            return
        }

        // 使用 runId 查找消息，如果没有 runId 则使用 activeRunId
        let runId = payload["runId"] as? String ?? session.activeRunId
        let seq = payload["seq"] as? Int

        if let runId {
            appendToAssistantMessage(session: session, runId: runId, text: text, seq: seq)
        } else {
            // 后备：追加到最后一条 assistant 消息
            if let lastMessage = session.messages.last, lastMessage.role == .assistant {
                session.appendToLastMessage(text: text)
            } else {
                // 创建新的 assistant 消息
                let assistantMsg = ChatMessage(
                    id: UUID().uuidString,
                    role: .assistant,
                    text: text,
                    timestamp: Date(),
                    streaming: true
                )
                session.messages.append(assistantMsg)
            }
        }
    }

    /// 处理 agent.done 事件
    private func handleAgentDone(_ event: GatewayEvent) {
        // 查找对应的 session
        if let session = findSessionForEvent(event) {
            session.status = .idle
            session.activeRunId = nil
        }
    }

    /// 处理 agent.error 事件
    private func handleAgentError(_ event: GatewayEvent) {
        guard let payload = event.payload as? [String: Any],
              let message = payload["message"] as? String
        else {
            return
        }

        // 查找对应的 session
        guard let session = findSessionForEvent(event) else {
            return
        }

        session.status = .error(message)
        session.activeRunId = nil

        // 添加错误消息
        let errorMsg = ChatMessage(
            id: UUID().uuidString,
            role: .system,
            text: "Error: \(message)",
            timestamp: Date()
        )
        session.messages.append(errorMsg)
    }

    // MARK: - Session 查找

    /// 查找 Session（支持 sessionId 或 sessionKey）
    private func findSession(sessionId: String? = nil, sessionKey: String? = nil) -> SessionState? {
        if let sessionId {
            return sessions.values.first { $0.sessionId.lowercased() == sessionId.lowercased() }
        }
        if let sessionKey {
            return sessions.values.first { $0.sessionKey.lowercased() == sessionKey.lowercased() }
        }
        return nil
    }

    /// 根据事件找到对应的 Session（严格使用 sessionKey 匹配）
    private func findSessionForEvent(_ event: GatewayEvent) -> SessionState? {
        guard let payload = event.payload as? [String: Any] else {
            logger.error("❌ Invalid event payload")
            return nil
        }

        // ✅ 1. 从 payload 中提取 sessionKey
        var sessionKey = payload["sessionKey"] as? String

        // ✅ 2. 如果 payload 中没有，检查 payload.data
        if sessionKey == nil || sessionKey!.isEmpty,
           let data = payload["data"] as? [String: Any],
           let dataSessionKey = data["sessionKey"] as? String
        {
            sessionKey = dataSessionKey
        }

        // ✅ 3. 如果还是没有 sessionKey，返回 nil
        guard let key = sessionKey, !key.isEmpty else {
            logger.warning("⚠️ Event missing sessionKey: event=\(event.event)")
            return nil
        }

        // ✅ 4. 严格使用 sessionKey 匹配
        let session = findSession(sessionKey: key)
        if session == nil {
            logger.warning("⚠️ Session not found for sessionKey: \(key)")
        }
        return session
    }
}
