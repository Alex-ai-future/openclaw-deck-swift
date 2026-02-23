// SessionConfig.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation

/// Session 配置信息（本地管理）
struct SessionConfig: Identifiable, Codable {
    /// 本地生成的唯一标识（用于 UI 显示和本地存储）
    let id: String

    /// 用于 Gateway 的 session key（"agent:main:{sessionId}"）
    let sessionKey: String

    /// 创建时间
    let createdAt: Date

    /// 可选的用户自定义名称（显示在 UI 上）
    var name: String?

    /// 可选的图标（显示在 UI 上）
    var icon: String?

    /// 可选的主题色（显示在 UI 上）
    var accentColor: String?

    /// 可选的上下文描述（用于 AI Agent 理解场景）
    var context: String?

    /// 生成 Session ID
    ///
    /// - Parameter name: 用户输入的会话名称（用于生成 ID）
    /// - Returns: 生成的 Session ID（小写，替换特殊字符为连字符）
    static func generateId(from name: String) -> String {
        let sanitized = name
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        return sanitized.isEmpty ? "session-\(Date().timeIntervalSince1970)" : sanitized
    }

    /// 生成 Session Key
    ///
    /// - Parameter sessionId: 本地生成的 Session ID
    /// - Returns: 生成的 Session Key（格式："agent:main:{sessionId}"）
    static func generateSessionKey(sessionId: String) -> String {
        return "agent:main:\(sessionId)"
    }
}

// MARK: - Extensions

extension SessionConfig {
    /// 检查是否是默认的空配置（仅用于初始化）
    var isEmpty: Bool {
        return id == "" && sessionKey == "" && name == nil && icon == nil && accentColor == nil && context == nil
    }
}
