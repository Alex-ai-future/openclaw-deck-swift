// SessionState.swift
// OpenClaw Deck Swift
//
// SwiftData Session 模型（支持 Codable 用于 Cloudflare 同步）

import SwiftData
import Foundation

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
    @Transient var messageCount: Int { messages.count }
    
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
    
    // MARK: - Hashable
    
    static func == (lhs: SessionState, rhs: SessionState) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
