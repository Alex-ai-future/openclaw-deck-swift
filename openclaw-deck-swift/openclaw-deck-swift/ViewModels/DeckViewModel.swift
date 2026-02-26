// DeckViewModel.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/24/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation
import os

private let logger = Logger(subsystem: "com.openclaw.deck", category: "DeckViewModel")

/// Deck ViewModel - 管理多个 Session
@MainActor
@Observable
class DeckViewModel {
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

  /// 应用配置
  var config: AppConfig = .default

  /// 是否正在初始化
  var isInitializing: Bool = false

  /// UserDefaults 存储
  private let storage: UserDefaultsStorage

  // MARK: - Initialization

  /// 初始化
  /// - Parameter storage: UserDefaultsStorage 实例（默认为 shared）
  init(storage: UserDefaultsStorage = .shared) {
    self.storage = storage
    setupGatewayCallbacks()
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
          await self?.loadAllSessionHistory()
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
    gatewayClient?.disconnect()
    gatewayConnected = false
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
      sessionKey: sessionKey
    )

    // 5. 添加到 sessions（使用小写 key 确保与 Gateway 一致）
    let sessionIdLower = sessionId.lowercased()
    sessions[sessionIdLower] = sessionState
    sessionOrder.append(sessionIdLower)

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
    // 1. 从 sessions 中移除
    sessions.removeValue(forKey: sessionId)

    // 2. 从 sessionOrder 中移除
    sessionOrder.removeAll { $0 == sessionId }

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
    sessions[sessionId]
  }

  // MARK: - Storage

  /// 从 UserDefaults 加载 Sessions
  private func loadSessionsFromStorage() {
    let configs = storage.loadSessions()
    let order = storage.loadSessionOrder()

    // 如果没有 session，创建 welcome session
    if configs.isEmpty {
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

    // 如果 Gateway 已连接，立即加载历史消息
    if gatewayConnected {
      Task {
        await loadAllSessionHistory()
      }
    }
  }

  /// 保存 Sessions 到 UserDefaults
  private func saveSessionsToStorage() {
    let configs = sessionOrder.compactMap { id -> SessionConfig? in
      guard let state = sessions[id] else { return nil }
      return SessionConfig(
        id: state.sessionId,
        sessionKey: state.sessionKey,
        createdAt: Date(),
        name: state.sessionId,
        icon: nil,
        context: nil
      )
    }

    storage.saveSessions(configs)
    storage.saveSessionOrder(sessionOrder)
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
      let messages = try await client.getSessionHistory(sessionKey: sessionKey) ?? []

      // 更新 Session 的消息（大小写不敏感匹配）
      if let session = sessions.values.first(where: {
        $0.sessionKey.lowercased() == sessionKey.lowercased()
      }) {
        session.messages = messages
        session.historyLoaded = true
        session.isHistoryLoading = false
      }
    } catch {
      logger.error("Failed to load history for \(sessionKey): \(error.localizedDescription)")
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
    guard
      let session = sessions.values.first(where: {
        $0.sessionId.lowercased() == sessionId.lowercased()
      })
    else {
      logger.error("Session not found: \(sessionId)")
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
        let (runId, status) = try await client.runAgent(
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
    // 调试：打印所有事件
    logger.info("=== Gateway Event: \(event.event) ===")
    
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
      logger.info("Unknown event type: \(event.event)")
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
    guard
      let session = sessions.values.first(where: {
        $0.sessionKey.lowercased() == sessionKey.lowercased()
      })
    else {
      logger.error("Session not found for sessionKey: \(sessionKey)")
      return
    }

    switch stream {
    case "assistant":
      // 流式内容：{ data: { delta: "..." } } 或 { data: { text: "..." } }
      if let data = payload["data"] as? [String: Any] {
        let seq = payload["seq"] as? Int
        let delta = data["delta"] as? String
        let text = data["text"] as? String
        
        // 调试日志
        logger.info("Assistant event: runId=\(runId), seq=\(seq ?? -1), delta=\(delta?.count ?? 0) chars, text=\(text?.count ?? 0) chars")
        
        // 实时接收时：只更新最后一条消息（累积文本）
        if let text = text, !text.isEmpty {
          updateOrCreateLastAssistantMessage(session: session, runId: runId, text: text, seq: seq)
        }
        // 否则使用 delta 追加（流式更新）
        else if let delta = delta, !delta.isEmpty {
          appendToAssistantMessage(session: session, runId: runId, text: delta)
        }
      }

    case "lifecycle":
      // 生命周期：{ data: { phase: "start" | "end" } }
      if let data = payload["data"] as? [String: Any],
        let phase = data["phase"] as? String
      {
        switch phase {
        case "start":
          session.status = .thinking
        case "end":
          session.status = .idle
          session.activeRunId = nil
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
  private func updateOrCreateLastAssistantMessage(session: SessionState, runId: String, text: String, seq: Int?) {
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
  private func createOrUpdateLastAssistantMessage(session: SessionState, runId: String, text: String, seq: Int?) {
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
  private func createAssistantMessage(session: SessionState, runId: String, text: String, seq: Int?) {
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

  /// 从事件中提取 sessionId（通过 sessionKey）
  private func sessionFromEvent(_ event: GatewayEvent) -> SessionState? {
    guard let payload = event.payload as? [String: Any],
      let sessionKey = payload["sessionKey"] as? String
    else {
      return nil
    }

    // Find session by sessionKey (case-insensitive)
    return sessions.values.first(where: { $0.sessionKey.lowercased() == sessionKey.lowercased() })
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
