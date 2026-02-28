// DeckViewModel.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/24/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation
import os

private let logger = Logger(subsystem: "com.openclaw.deck", category: "DeckViewModel")

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

    let description: String
    if isOrderOnly {
      description =
        "Local and remote have the same \(localCount) sessions but in different order.\n\n• Use Local: Keep your order (overwrite cloud)\n• Use Cloud: Merge cloud order with local"
    } else if localCount == remoteCount {
      description =
        "Local and remote both have \(localCount) sessions but with different content.\n\n• Use Local: Keep local sessions (overwrite cloud)\n• Use Cloud: Merge cloud sessions with local"
    } else {
      description =
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

  /// Gateway 客户端
  var gatewayClient: GatewayClient?

  /// 所有 Session 状态（按 sessionId 索引）
  var sessions: [String: SessionState] = [:]

  /// Session 顺序（用于 UI 展示顺序）
  var sessionOrder: [String] = []

  /// Gateway 连接状态
  var gatewayConnected: Bool = false

  /// 连接错误信息
  var connectionError: String?

  /// 是否正在重连
  var isReconnecting: Bool = false

  /// 重连尝试次数
  var reconnectAttempts: Int = 0

  /// 应用配置
  var config: AppConfig = .default

  /// 是否正在初始化
  var isInitializing: Bool = false

  /// 是否正在同步
  var isSyncing: Bool = false

  /// 全局输入状态（唯一实例）
  var globalInputState: GlobalInputStateProtocol

  /// 是否播放消息提示音
  var playSoundOnMessage: Bool = true {
    didSet {
      UserDefaults.standard.set(playSoundOnMessage, forKey: "playSoundOnMessage")
    }
  }

  /// UserDefaults 存储
  private let storage: UserDefaultsStorageProtocol

  // MARK: - Initialization

  /// 初始化
  /// - Parameters:
  ///   - storage: UserDefaultsStorage 实例（默认为 shared）
  ///   - globalInputState: GlobalInputState 实例（默认为新实例）
  @MainActor init(
    storage: UserDefaultsStorageProtocol? = nil,
    globalInputState: GlobalInputStateProtocol? = nil
  ) {
    self.storage = storage ?? UserDefaultsStorage.shared
    self.globalInputState = globalInputState ?? GlobalInputState()
    setupGatewayCallbacks()

    // 加载配置
    playSoundOnMessage = UserDefaults.standard.object(forKey: "playSoundOnMessage") as? Bool ?? true

    // 从 UserDefaults 加载 Session
    loadSessionsFromStorage()
  }

  /// 设置 Gateway 回调
  private func setupGatewayCallbacks() {
    // 回调将在 initialize() 中设置
  }

  // MARK: - Gateway Connection

  /// 初始化并连接 Gateway
  func initialize(url: String, token: String?) async {
    guard !isInitializing else { return }
    isInitializing = true

    // Clear previous error
    connectionError = nil

    config.gatewayUrl = url
    config.token = token

    // 保存到 UserDefaults
    storage.saveGatewayUrl(url)
    if let token = token {
      storage.saveToken(token)
    }

    guard let gatewayUrl = URL(string: url) else {
      logger.error("Invalid gateway URL: \(url)")
      connectionError = "Invalid gateway URL: \(url)"
      isInitializing = false
      return
    }

    // 创建 GatewayClient
    let client = GatewayClient(url: gatewayUrl, token: token)

    // 设置事件回调
    client.onEvent = { [weak self] event in
      Task { @MainActor in
        self?.handleGatewayEvent(event)
      }
    }

    // 设置连接状态回调
    client.onConnection = { [weak self] connected in
      Task { @MainActor in
        self?.gatewayConnected = connected
        if connected {
          // 重连时重置所有 session 的处理状态
          if let sessions = self?.sessions {
            for session in sessions.values {
              session.isProcessing = false
              session.status = .idle
              session.activeRunId = nil
            }
          }
          // 重置重连状态
          logger.info("🔗 Gateway 已连接，开始下载所有 Session 消息...")
          await self?.loadAllSessionHistory()
        } else {
          logger.info("🔌 Gateway 已断开")
        }
      }
    }

    self.gatewayClient = client

    // 连接 Gateway
    await client.connect()

    // Sync error state from client
    connectionError = client.connectionError

    isInitializing = false
  }

  /// 清除连接错误
  func clearConnectionError() {
    connectionError = nil
    gatewayClient?.clearError()
  }

  /// 断开 Gateway 连接
  func disconnect() {
    // 清空所有 Session 的消息和状态
    for session in sessions.values {
      session.messages.removeAll()
      session.historyLoaded = false
      session.isHistoryLoading = false
      session.isProcessing = false
      session.status = .idle
      session.activeRunId = nil
      session.hasUnreadMessage = false
    }

    gatewayClient?.disconnect()
    gatewayConnected = false

    logger.info("🧹 已断开连接并清空所有 Session 消息")
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

  /// 创建新 Session
  /// - Parameters:
  ///   - name: Session 名称
  ///   - icon: 可选的图标
  ///   - context: 可选的上下文描述
  /// - Returns: 创建的 SessionConfig
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
      context: context
    )

    // 5. 添加到 sessions（使用小写 key 确保与 Gateway 一致）
    let sessionIdLower = sessionId.lowercased()
    sessions[sessionIdLower] = sessionState
    sessionOrder.insert(sessionIdLower, at: 0)  // 插入到开头，让新 Session 在最左边

    // 6. 保存到 UserDefaults
    saveSessionsToStorage()

    // 7. 如果已连接，加载历史消息
    if gatewayConnected {
      Task {
        await loadSessionHistory(sessionKey: sessionKey)
      }
    }

    return sessionConfig
  }

  /// 创建 Welcome Session（当没有 session 时自动创建）
  private func createWelcomeSession() {
    // 使用 createSession 方法创建
    _ = createSession(name: "Welcome")
  }

  /// 删除 Session
  /// - Parameter sessionId: 要删除的 Session ID
  func deleteSession(sessionId: String) {
    // 1. 从 sessions 中移除（使用小写 key）
    sessions.removeValue(forKey: sessionId.lowercased())

    // 2. 从 sessionOrder 中移除
    sessionOrder.removeAll { $0 == sessionId.lowercased() }

    // 3. 保存到 UserDefaults
    saveSessionsToStorage()

    // 4. 如果删除后没有 session 了，创建 welcome session
    if sessions.isEmpty {
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
  private func loadSessionsFromStorage() {
    logger.log("📥 加载 Sessions...")

    // 测试环境下跳过 Cloudflare 同步，避免网络请求
    #if TESTING
      logger.log("🧪 测试环境，使用本地数据")
      loadFromLocalOnly()
    #else
      // 尝试从 Cloudflare 同步（如果已配置）
      if CloudflareKV.shared.isConfigured {
        logger.log("☁️ Cloudflare 已配置，开始同步...")
        Task {
          await loadSessionsWithCloudflareSync()
        }
      } else {
        logger.log("📱 未配置 Cloudflare，使用本地数据")
        // 没有配置 Cloudflare，使用本地数据
        loadFromLocalOnly()
      }
    #endif
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

        // 如果 Gateway 已连接，立即加载历史消息
        if gatewayConnected {
          logger.log("🔗 Gateway 已连接，加载历史消息...")
          Task {
            await loadAllSessionHistory()
          }
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
      data.lastUpdated, forKey: "openclaw.deck.sessionOrder.lastUpdated")

    // If selected remote or merge, save to cloud
    if data != conflictLocalData {
      do {
        try await CloudflareKV.shared.save(data)
      } catch {
        logger.error("❌ Failed to save to cloud: \(error.localizedDescription)")
      }
    }

    logger.log("✅ Sync complete: \(data.sessions.count) sessions")

    // If Gateway connected, load history
    if gatewayConnected {
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
      return
    }

    // 使用小写 key 确保与 Gateway 一致
    for config in configs {
      let idLower = config.id.lowercased()
      sessions[idLower] = SessionState(
        sessionId: config.id,
        sessionKey: config.sessionKey
      )
    }

    // 也小写化 sessionOrder
    if order.isEmpty {
      sessionOrder = configs.map { $0.id.lowercased() }
    } else {
      sessionOrder = order.map { $0.lowercased() }
    }

    logger.log("✅ 加载完成：\(self.sessionOrder.count) 个 sessions")

    // 默认选中第一个 Session
    if let firstSessionId = sessionOrder.first {
      globalInputState.selectedSessionId = firstSessionId
      logger.log("🎯 选中 Session: \(firstSessionId)")
    }

    // 如果 Gateway 已连接，立即加载历史消息
    if gatewayConnected {
      logger.log("🔗 Gateway 已连接，加载历史消息...")
      Task {
        await loadAllSessionHistory()
      }
    }
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

    logger.log("✅ 创建完成：\(self.sessions.count) 个 Session 状态")
  }

  /// 保存 Sessions 到 UserDefaults（并同步到 Cloudflare）
  func saveSessionsToStorage() {
    let configs = sessionOrder.compactMap { id -> SessionConfig? in
      guard let state = sessions[id] else { return nil }
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

    // 如果配置了 Cloudflare，异步同步到云端
    if CloudflareKV.shared.isConfigured {
      Task {
        await syncToCloudflare()
      }
    }
  }

  /// 同步到 Cloudflare KV
  private func syncToCloudflare() async {
    do {
      let syncData = SyncData(
        sessions: sessionOrder, lastUpdated: ISO8601DateFormatter().string(from: Date()))
      try await CloudflareKV.shared.save(syncData)
      logger.info("Synced to Cloudflare KV")
    } catch {
      logger.error("Cloudflare sync failed: \(error.localizedDescription)")
    }
  }

  // MARK: - Sync

  /// 同步操作（带状态管理）
  /// - Returns: 同步结果（成功/失败消息）
  @MainActor
  func handleSync() async -> Result<String, Error> {
    isSyncing = true
    defer { isSyncing = false }
    return await syncAll()
  }

  /// 完整同步：Cloudflare（Session 列表）+ Gateway（对话内容）
  /// - Returns: 同步结果（成功/失败消息）
  @MainActor
  func syncAll() async -> Result<String, Error> {
    guard gatewayConnected else {
      return .failure(
        NSError(
          domain: "DeckViewModel", code: 400,
          userInfo: [NSLocalizedDescriptionKey: "Gateway not connected"]))
    }

    do {
      logger.info("🔄 Starting full sync...")

      // 1. 从 Cloudflare 同步 Session 列表
      logger.info("📥 Syncing session list...")
      let result = try await CloudflareKV.shared.syncAndGet()

      // 处理冲突情况
      if result.source == .conflict {
        // 冲突时让用户选择（弹窗）
        logger.info("⚠️ Conflict detected during sync, showing conflict dialog")
        await handleSyncConflict(result: result)
        return .failure(
          NSError(
            domain: "DeckViewModel", code: 409,
            userInfo: [
              NSLocalizedDescriptionKey: "Sync conflict: please select data source"
            ]))
      }

      // 更新本地 sessions
      sessionOrder = result.data.sessions.map { $0.lowercased() }
      createSessionStates()
      saveSessionsToStorage()

      logger.info("✅ Session list updated: \(result.data.sessions.count) sessions")

      // 2. 清空所有 Session 的当前消息
      logger.info("🧹 Clearing current messages...")
      for session in sessions.values {
        session.messages.removeAll()
        session.historyLoaded = false
      }

      // 3. 重新加载所有 Session 的对话内容
      logger.info("📥 Reloading conversation history...")
      await loadAllSessionHistory()

      logger.info("✅ Sync complete: \(result.data.sessions.count) sessions")
      return .success("Sync complete: \(result.data.sessions.count) sessions")
    } catch {
      logger.error("❌ Sync failed: \(error.localizedDescription)")
      return .failure(error)
    }
  }

  // MARK: - Load History

  /// 加载所有 Session 的历史消息
  func loadAllSessionHistory() async {
    for session in self.sessionOrder.compactMap({ self.sessions[$0] }) {
      await loadSessionHistory(sessionKey: session.sessionKey)
    }
  }

  /// 加载单个 Session 的历史消息
  /// - Parameter sessionKey: Session Key
  func loadSessionHistory(sessionKey: String) async {
    guard let client = gatewayClient, client.connected else {
      return
    }

    // 设置加载状态（大小写不敏感匹配）
    if let session = sessions.values.first(where: {
      $0.sessionKey.lowercased() == sessionKey.lowercased()
    }) {
      session.isHistoryLoading = true
    }

    do {
      logger.info("📥 正在加载 Session \(sessionKey) 的历史消息...")
      let messages = try await client.getSessionHistory(sessionKey: sessionKey) ?? []

      // 更新 Session 的消息（大小写不敏感匹配）
      if let session = sessions.values.first(where: {
        $0.sessionKey.lowercased() == sessionKey.lowercased()
      }) {
        session.messages = messages
        session.historyLoaded = true
        session.isHistoryLoading = false
        logger.info("✅ Session \(sessionKey) 加载完成，共 \(messages.count) 条消息")
      }
    } catch {
      logger.error("❌ 加载 Session \(sessionKey) 历史失败：\(error.localizedDescription)")
      if let session = sessions.values.first(where: {
        $0.sessionKey.lowercased() == sessionKey.lowercased()
      }) {
        session.isHistoryLoading = false
      }
    }
  }

  // MARK: - Send Message

  /// 发送消息
  /// - Parameters:
  ///   - sessionId: Session ID
  ///   - text: 消息文本
  func sendMessage(sessionId: String, text: String) async {
    guard let client = gatewayClient, client.connected else {
      return
    }

    // Find session by sessionId (case-insensitive)
    guard let session = findSession(sessionId: sessionId) else {
      return
    }

    // 1. 添加用户消息
    let userMsg = ChatMessage(
      id: UUID().uuidString,
      role: .user,
      text: text,
      timestamp: Date()
    )
    session.messages.append(userMsg)
    session.status = .thinking

    // 2. 调用 runAgent（不阻塞 UI，不创建占位消息）
    // Gateway 返回内容时会自动创建 assistant 消息
    Task {
      do {
        let (runId, _) = try await client.runAgent(
          agentId: config.mainAgentId,
          message: text,
          sessionKey: session.sessionKey
        )

        // Agent run started

        // 设置 activeRunId 用于关联响应
        await MainActor.run {
          session.activeRunId = runId
        }
      } catch {
        logger.error("Failed to send message: \(error.localizedDescription)")
        await MainActor.run {
          session.status = .error("Failed to send message: \(error.localizedDescription)")
        }
      }
    }
  }

  // MARK: - Event Handling

  /// 处理 Gateway 事件
  /// - Parameter event: Gateway 事件
  func handleGatewayEvent(_ event: GatewayEvent) {
    // 📝 聊天事件日志
    if event.event == "chat" {
      if let payload = event.payload as? [String: Any] {
        let runId = payload["runId"] as? String ?? "unknown"
        let sessionKey = payload["sessionKey"] as? String ?? "unknown"
        let state = payload["state"] as? String ?? "unknown"
        let errorMessage = payload["errorMessage"] as? String ?? "nil"
        let stopReason = payload["stopReason"] as? String ?? "nil"
        let hasMessage = payload["message"] != nil
        
        logger.info("📡 [ChatEvent] runId=\(runId), sessionKey=\(sessionKey), state=\(state), hasMessage=\(hasMessage), errorMessage=\(errorMessage), stopReason=\(stopReason)")
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
      let stream = payload["stream"] as? String,
      let sessionKey = payload["sessionKey"] as? String
    else {
      logger.error("Invalid agent event payload")
      return
    }

    // Find session by sessionKey (case-insensitive)
    guard let session = findSession(sessionKey: sessionKey) else {
      return
    }

    switch stream {
    case "assistant":
      // 流式内容：{ data: { delta: "..." } } 或 { data: { text: "..." } }
      if let data = payload["data"] as? [String: Any] {
        let seq = payload["seq"] as? Int
        let delta = data["delta"] as? String
        let text = data["text"] as? String

        // 如果有 seq，检查是否已处理（去重）
        if let seq = seq {
          let alreadyProcessed = session.messages.contains { $0.seq == seq }
          if alreadyProcessed {
            return
          }
        }

        // 优先使用 delta 追加（流式更新）
        if let delta = delta, !delta.isEmpty {
          appendToAssistantMessage(session: session, runId: runId, text: delta)
        }
        // 后备：使用 text（只在没有 delta 且没有同 runId 消息时）
        else if let text = text, !text.isEmpty {
          let hasExistingMessage = session.messages.contains {
            $0.runId == runId && $0.role == .assistant
          }

          if !hasExistingMessage {
            createAssistantMessage(session: session, runId: runId, text: text, seq: seq)
          }
        }
      }

    case "lifecycle":
      // 生命周期：{ data: { phase: "start" | "end" } }
      if let data = payload["data"] as? [String: Any],
        let phase = data["phase"] as? String
      {
        // 🔔 打印日志，验证是否收到 lifecycle 事件
        logger.info("🔔 Lifecycle 事件：phase = \(phase), runId = \(runId)")

        switch phase {
        case "start":
          logger.info("✅ 收到新消息开始 - 显示处理中状态")
          session.isProcessing = true
          session.status = .thinking
        case "end":
          logger.info("✅ 消息接收完成 - 隐藏处理中状态")
          session.isProcessing = false
          session.hasUnreadMessage = true  // 总是标记为未读
          session.status = .idle
          session.activeRunId = nil

          // 🎯 发送通知：无论前台后台都发
          if let lastMessage = session.messages.last,
            lastMessage.role == .assistant,
            !lastMessage.text.isEmpty
          {
            NotificationService.shared.sendNewMessageNotification(
              sessionName: session.sessionId,
              messageText: lastMessage.text
            )

            // 🎵 播放提示音（如果启用）
            if playSoundOnMessage {
              SoundService.shared.playMessageNotification()
            }
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

    case "tool_use":
      // 忽略工具调用事件，不显示
      break

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
      text: text,  // 替换为累积文本
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
  private func createAssistantMessage(session: SessionState, runId: String, text: String, seq: Int?)
  {
    // 设置状态为 streaming
    session.status = .streaming

    // 检查是否已有相同 seq 的消息（避免重复）
    if let seq = seq {
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
      text: text,  // 替换而不是追加
      timestamp: message.timestamp,
      streaming: message.streaming,
      thinking: message.thinking,
      toolUse: message.toolUse,
      runId: message.runId,
      isLoaded: message.isLoaded
    )
  }

  /// 追加内容到 assistant 消息（用于 delta 流式更新）
  private func appendToAssistantMessage(session: SessionState, runId: String, text: String) {
    // 设置状态为 streaming
    session.status = .streaming

    // 查找最后一条同 runId 且 streaming 的消息
    guard
      let index = session.messages.enumerated().last(where: { _, msg in
        msg.role == .assistant && msg.runId == runId && msg.streaming == true
      })?.offset
    else {
      // 没有找到，创建一个新的
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

    // 追加文本
    let message = session.messages[index]
    session.messages[index] = ChatMessage(
      id: message.id,
      role: message.role,
      text: message.text + text,
      timestamp: message.timestamp,
      streaming: message.streaming,
      thinking: message.thinking,
      toolUse: message.toolUse,
      runId: message.runId,
      isLoaded: message.isLoaded
    )
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

    if let runId = runId {
      appendToAssistantMessage(session: session, runId: runId, text: text)
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
    // 尝试从 sessionKey 提取 sessionId
    if let session = sessionFromEvent(event) {
      session.status = .idle
      session.activeRunId = nil
      return
    }
    // 后备：使用 findSessionForEvent
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

    // 尝试从 sessionKey 提取 sessionId
    let session = sessionFromEvent(event) ?? findSessionForEvent(event)
    guard let session = session else {
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
    if let sessionId = sessionId {
      return sessions.values.first { $0.sessionId.lowercased() == sessionId.lowercased() }
    }
    if let sessionKey = sessionKey {
      return sessions.values.first { $0.sessionKey.lowercased() == sessionKey.lowercased() }
    }
    return nil
  }

  /// 从事件中提取 sessionId（通过 sessionKey）
  private func sessionFromEvent(_ event: GatewayEvent) -> SessionState? {
    guard let payload = event.payload as? [String: Any],
      let sessionKey = payload["sessionKey"] as? String
    else {
      return nil
    }

    return findSession(sessionKey: sessionKey)
  }

  /// 根据事件找到对应的 Session
  private func findSessionForEvent(_ event: GatewayEvent) -> SessionState? {
    // 优先通过 activeRunId 查找匹配的 Session
    for session in sessions.values {
      if let activeRunId = session.activeRunId {
        // 如果事件 payload 中有 runId，进行匹配
        if let payload = event.payload as? [String: Any],
          let eventRunId = payload["runId"] as? String
        {
          if activeRunId == eventRunId {
            return session
          }
        }
        // 如果没有 runId 信息，返回第一个有 activeRunId 的 session
        return session
      }
    }

    // 如果没有找到 activeRunId，返回最后一个 session（作为后备）
    return sessionOrder.last.flatMap { sessions[$0] }
  }
}
