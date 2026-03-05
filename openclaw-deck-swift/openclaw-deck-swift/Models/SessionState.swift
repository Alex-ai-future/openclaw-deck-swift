// SessionState.swift
// OpenClaw Deck Swift
//
// SwiftData Session 模型

import SwiftData
import Foundation

/// Session 状态（SwiftData 模型）
@Model
final class SessionState: Hashable, Identifiable {
    @Attribute(.unique) var id: String
    var sessionKey: String
    var name: String
    var context: String?
    var isHidden: Bool
    var sortOrder: Int
    var createdAt: Date
    var lastActivityAt: Date
    
    // 内存属性（不持久化）
    @Transient var messages: [ChatMessage] = []
    @Transient var status: SessionStatus = .idle
    @Transient var hasUnreadMessage: Bool = false
    @Transient var activeRunId: String?
    @Transient var messageCount: Int { messages.count }
    
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
    
    // MARK: - Hashable
    
    static func == (lhs: SessionState, rhs: SessionState) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
