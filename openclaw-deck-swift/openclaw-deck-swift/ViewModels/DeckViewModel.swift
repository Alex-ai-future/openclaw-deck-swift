// DeckViewModel.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/24/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation

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
    
    // MARK: - Initialization
    
    init() {
        setupGatewayCallbacks()
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

        guard let gatewayUrl = URL(string: url) else {
            print("[DeckViewModel] Invalid gateway URL: \(url)")
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
    ///   - accentColor: 可选的主题色
    ///   - context: 可选的上下文描述
    /// - Returns: 创建的 SessionConfig
    func createSession(
        name: String,
        icon: String? = nil,
        accentColor: String? = nil,
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
            accentColor: accentColor ?? "#a78bfa",
            context: context ?? name
        )
        
        // 4. 创建 SessionState
        let sessionState = SessionState(
            sessionId: sessionId,
            sessionKey: sessionKey
        )
        
        // 5. 添加到 sessions
        sessions[sessionId] = sessionState
        sessionOrder.append(sessionId)
        
        // 6. 如果已连接，加载历史消息
        if gatewayConnected {
            Task {
                await loadSessionHistory(sessionKey: sessionKey)
            }
        }
        
        return sessionConfig
    }
    
    /// 删除 Session
    /// - Parameter sessionId: 要删除的 Session ID
    func deleteSession(sessionId: String) {
        // 1. 从 sessions 中移除
        sessions.removeValue(forKey: sessionId)
        
        // 2. 从 sessionOrder 中移除
        sessionOrder.removeAll { $0 == sessionId }
        
        // 注意：Gateway 中的消息历史不会被删除
        // Session Key 可以继续使用，下次创建同名 Session 会加载历史
    }
    
    /// 获取 Session
    /// - Parameter sessionId: Session ID
    /// - Returns: SessionState（如果存在）
    func getSession(sessionId: String) -> SessionState? {
        sessions[sessionId]
    }
    
    // MARK: - Load History
    
    /// 加载所有 Session 的历史消息
    func loadAllSessionHistory() async {
        for sessionKey in sessionOrder.compactMap { sessions[$0]?.sessionKey } {
            await loadSessionHistory(sessionKey: sessionKey)
        }
    }
    
    /// 加载单个 Session 的历史消息
    /// - Parameter sessionKey: Session Key
    func loadSessionHistory(sessionKey: String) async {
        guard let client = gatewayClient, client.connected else { return }
        
        // 从 sessionKey 中提取 sessionId
        let parts = sessionKey.split(separator: ":")
        guard parts.count >= 3 else { return }
        let sessionId = String(parts[2])
        
        do {
            let messages = try await client.getSessionHistory(sessionKey: sessionKey) ?? []
            
            // 更新 Session 的消息
            if let session = sessions[sessionId] {
                session.messages = messages
                session.historyLoaded = true
            }
        } catch {
            print("[DeckViewModel] Failed to load history for \(sessionId): \(error)")
        }
    }
    
    // MARK: - Send Message
    
    /// 发送消息
    /// - Parameters:
    ///   - sessionId: Session ID
    ///   - text: 消息文本
    func sendMessage(sessionId: String, text: String) async {
        guard let client = gatewayClient, client.connected else {
            print("[DeckViewModel] Gateway not connected")
            return
        }
        
        guard let session = sessions[sessionId] else {
            print("[DeckViewModel] Session not found: \(sessionId)")
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
        
        do {
            // 2. 调用 runAgent
            let (runId, status) = try await client.runAgent(
                agentId: config.mainAgentId,
                message: text,
                sessionKey: session.sessionKey
            )
            
            print("[DeckViewModel] Agent run started: \(runId), status: \(status)")
            
            // 3. 创建 assistant 占位消息
            let assistantMsg = ChatMessage(
                id: UUID().uuidString,
                role: .assistant,
                text: "",
                timestamp: Date(),
                streaming: true,
                runId: runId
            )
            session.messages.append(assistantMsg)
            session.activeRunId = runId
            session.status = .streaming
            
        } catch {
            print("[DeckViewModel] Failed to send message: \(error)")
            session.status = .error("Failed to send message: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Event Handling
    
    /// 处理 Gateway 事件
    /// - Parameter event: Gateway 事件
    func handleGatewayEvent(_ event: GatewayEvent) {
        switch event.event {
        case "agent.content":
            handleAgentContent(event)
        case "agent.thinking":
            handleAgentThinking(event)
        case "agent.tool_use":
            handleAgentToolUse(event)
        case "agent.done":
            handleAgentDone(event)
        case "agent.error":
            handleAgentError(event)
        default:
            print("[DeckViewModel] Unknown event type: \(event.event)")
        }
    }
    
    /// 处理 agent.content 事件
    private func handleAgentContent(_ event: GatewayEvent) {
        // 从 payload 中提取文本
        guard let payload = event.payload as? [String: Any],
              let text = payload["text"] as? String else {
            return
        }
        
        // 找到对应的 Session 和消息
        guard let session = findSessionForEvent(event) else {
            return
        }
        
        // 追加文本到最后一条消息
        session.appendToLastMessage(text: text)
    }
    
    /// 处理 agent.thinking 事件
    private func handleAgentThinking(_ event: GatewayEvent) {
        guard let session = findSessionForEvent(event) else {
            return
        }
        
        session.status = .thinking
    }
    
    /// 处理 agent.tool_use 事件
    private func handleAgentToolUse(_ event: GatewayEvent) {
        guard let payload = event.payload as? [String: Any],
              let session = findSessionForEvent(event) else {
            return
        }
        
        // 提取工具信息
        let toolName = payload["tool_name"] as? String ?? "unknown"
        let input = payload["input"] as? String ?? ""
        let status = payload["status"] as? String ?? "running"
        
        // 创建工具调用信息
        let toolUse = ToolUseInfo(
            toolName: toolName,
            input: input,
            output: nil,
            status: status
        )
        
        // 更新最后一条消息
        if let index = session.messages.indices.last {
            let message = session.messages[index]
            session.messages[index] = ChatMessage(
                id: message.id,
                role: message.role,
                text: message.text,
                timestamp: message.timestamp,
                streaming: message.streaming,
                thinking: message.thinking,
                toolUse: toolUse,
                runId: message.runId,
                isLoaded: message.isLoaded
            )
        }
    }
    
    /// 处理 agent.done 事件
    private func handleAgentDone(_ event: GatewayEvent) {
        guard let session = findSessionForEvent(event) else {
            return
        }
        
        session.status = .idle
        session.activeRunId = nil
    }
    
    /// 处理 agent.error 事件
    private func handleAgentError(_ event: GatewayEvent) {
        guard let payload = event.payload as? [String: Any],
              let message = payload["message"] as? String,
              let session = findSessionForEvent(event) else {
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
    
    /// 根据事件找到对应的 Session
    private func findSessionForEvent(_ event: GatewayEvent) -> SessionState? {
        // 通过 activeRunId 查找
        for session in sessions.values {
            if let activeRunId = session.activeRunId {
                // 如果有 runId 信息，可以匹配
                // 目前简化处理，返回第一个有 activeRunId 的 session
                return session
            }
        }
        
        // 或者通过 seq/stateVersion 查找
        // 这里简化处理，返回最后一个 session
        return sessionOrder.last.flatMap { sessions[$0] }
    }
}
