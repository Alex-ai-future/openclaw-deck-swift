// SessionState.swift
// OpenClaw Deck Swift
//
// SwiftData Session 模型（支持 Codable 用于 Cloudflare 同步）

import Foundation
import SwiftData

/// Session 状态（SwiftData 模型 + Codable）
@Model
final class SessionState: Hashable, Identifiable, Codable {
    @Attribute(.unique) var id: String
    var sessionKey: String
    var name: String
    var context: String?
    var isHidden: Bool
    var sortOrder: Int
    var createdAt: Date
    var lastActivityAt: Date

    // 内存属性（不持久化，不编码）
    @Transient var messages: [ChatMessage] = []
    @Transient var status: SessionStatus = .idle
    @Transient var hasUnreadMessage: Bool = false
    @Transient var activeRunId: String?
    @Transient var messageLoadState: MessageLoadState = .notLoaded
    @Transient var isHistoryLoading: Bool = false
    @Transient var isLoadingMessages: Bool = false
    @Transient var historyLoaded: Bool = false

    // MARK: - Computed Properties

    var sessionId: String {
        id
    }

    var messageCount: Int {
        messages.count
    }

    var lastMessageAt: Date? {
        messages.last?.timestamp
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, sessionKey, name, context, isHidden, sortOrder, createdAt, lastActivityAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        sessionKey = try container.decode(String.self, forKey: .sessionKey)
        name = try container.decode(String.self, forKey: .name)
        context = try container.decodeIfPresent(String.self, forKey: .context)
        isHidden = try container.decode(Bool.self, forKey: .isHidden)
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastActivityAt = try container.decode(Date.self, forKey: .lastActivityAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(sessionKey, forKey: .sessionKey)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(context, forKey: .context)
        try container.encode(isHidden, forKey: .isHidden)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastActivityAt, forKey: .lastActivityAt)
    }

    // MARK: - Init

    init(
        id: String,
        sessionKey: String,
        name: String,
        context: String?,
        isHidden: Bool,
        sortOrder: Int,
        createdAt: Date,
        lastActivityAt: Date
    ) {
        self.id = id
        self.sessionKey = sessionKey
        self.name = name
        self.context = context
        self.isHidden = isHidden
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.lastActivityAt = lastActivityAt
    }

    /// 便利初始化器（用于测试预览）
    convenience init(sessionId: String, sessionKey: String) {
        self.init(
            id: sessionId,
            sessionKey: sessionKey,
            name: sessionId,
            context: nil,
            isHidden: false,
            sortOrder: 0,
            createdAt: Date(),
            lastActivityAt: Date()
        )
    }

    // MARK: - Hashable

    static func == (lhs: SessionState, rhs: SessionState) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Message Management

    func appendMessage(_ message: ChatMessage) {
        messages.append(message)
    }

    func updateLastMessage(text: String) {
        guard let index = messages.indices.last else { return }
        let message = messages[index]
        messages[index] = ChatMessage(
            id: message.id,
            role: message.role,
            text: text,
            timestamp: message.timestamp,
            streaming: message.streaming,
            thinking: message.thinking,
            toolUse: message.toolUse,
            runId: message.runId,
            seq: message.seq,
            isLoaded: message.isLoaded
        )
    }

    func appendToLastMessage(text: String) {
        guard let index = messages.indices.last else { return }
        let message = messages[index]
        guard message.role == .assistant else { return }

        messages[index] = ChatMessage(
            id: message.id,
            role: message.role,
            text: message.text + text,
            timestamp: message.timestamp,
            streaming: message.streaming,
            thinking: message.thinking,
            toolUse: message.toolUse,
            runId: message.runId,
            seq: message.seq,
            isLoaded: message.isLoaded
        )
    }

    func clearMessages() {
        messages.removeAll()
        messageLoadState = .notLoaded
    }
}

// MARK: - Supporting Types

enum MessageLoadState: Equatable {
    case notLoaded
    case loading
    case loaded
    case error(String)
}
