// SessionDetailView.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 3/2/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import SwiftUI

/// Session 详情视图 - 显示完整的会话信息
struct SessionDetailView: View {
    let session: SessionState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                sessionDetailContent
                    .padding()
            }
            .navigationTitle("session_details".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Session Detail Content

    private var sessionDetailContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // MARK: - 基础信息

            detailSection(title: "basic_info".localized) {
                VStack(alignment: .leading, spacing: 12) {
                    // Session ID
                    DetailRow(
                        icon: "circle.fill",
                        label: "Session ID",
                        value: session.sessionId,
                        isMonospaced: true
                    )

                    // Session Key（可复制）
                    DetailRow(
                        icon: "tag",
                        label: "Session Key",
                        value: session.sessionKey,
                        isMonospaced: true,
                        isCopyable: true
                    )

                    // 上下文/备注（如果有，完整显示）
                    if let context = session.context, !context.isEmpty {
                        Divider()
                            .padding(.vertical, 8)

                        DetailLabel(icon: "text.alignleft", text: "Context")
                        Text(context)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    }
                }
            }

            // MARK: - 状态信息

            detailSection(title: "status".localized) {
                VStack(alignment: .leading, spacing: 12) {
                    // 会话状态（带颜色）
                    StatusRow(
                        icon: sessionStatusIcon,
                        text: sessionStatusText,
                        color: sessionStatusColor
                    )

                    // 处理中状态
                    StatusRow(
                        icon: session.isProcessing ? "gearshape.fill" : "gearshape",
                        text: session.isProcessing ? "processing".localized : "idle".localized,
                        color: session.isProcessing ? .orange : .secondary
                    )

                    // 未读消息状态
                    StatusRow(
                        icon: session.hasUnreadMessage ? "circle.fill" : "circle",
                        text: session.hasUnreadMessage ? "unread_messages".localized : "all_read".localized,
                        color: session.hasUnreadMessage ? .green : .secondary
                    )

                    // 活跃 Run ID（如果有）
                    if let runId = session.activeRunId {
                        Divider()
                            .padding(.vertical, 8)

                        DetailLabel(icon: "play.circle.fill", text: "Active Run")
                        Text(runId)
                            .font(.caption.monospaced())
                            .foregroundColor(.blue)
                            .lineLimit(nil)
                            .textSelection(.enabled)
                    }
                }
            }

            // MARK: - 消息统计

            detailSection(title: "message_stats".localized) {
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(
                        icon: "message.fill",
                        label: "Total Messages",
                        value: "\(session.messages.count)"
                    )

                    // User / Assistant 消息数统计
                    HStack {
                        StatBadge(
                            icon: "person.fill",
                            value: "\(userMessageCount)",
                            label: "User",
                            color: .blue
                        )

                        Spacer()

                        StatBadge(
                            icon: "cpu.fill",
                            value: "\(assistantMessageCount)",
                            label: "Assistant",
                            color: .purple
                        )
                    }
                }
            }

            // MARK: - 时间信息

            detailSection(title: "timeline".localized) {
                VStack(alignment: .leading, spacing: 12) {
                    // 最后活动时间
                    if let lastActivity = session.lastMessageAt {
                        TimeDetailRow(
                            icon: "clock.fill",
                            label: "Last Activity",
                            relativeTime: formatRelativeDate(lastActivity),
                            absoluteTime: formatDate(lastActivity)
                        )
                    }

                    // 第一条消息时间
                    if let firstMessage = session.messages.first {
                        TimeDetailRow(
                            icon: "arrow.up.right.circle.fill",
                            label: "First Message",
                            relativeTime: formatRelativeDate(firstMessage.timestamp),
                            absoluteTime: formatDate(firstMessage.timestamp)
                        )
                    }
                }
            }

            // MARK: - 加载状态

            detailSection(title: "load_status".localized) {
                VStack(alignment: .leading, spacing: 12) {
                    // 历史加载状态
                    StatusRow(
                        icon: session.historyLoaded ? "checkmark.circle.fill" : "circle",
                        text: "History loaded",
                        color: session.historyLoaded ? .green : .secondary
                    )

                    if session.isHistoryLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading history...")
                                .font(.body)
                                .foregroundColor(.orange)
                        }
                    }

                    if session.isLoadingMessages {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading messages...")
                                .font(.body)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helper Views

    private func detailSection(
        title: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            content()
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.adaptiveSecondaryBackground)
                )
        }
    }

    // MARK: - Helpers

    private var sessionStatusIcon: String {
        switch session.status {
        case .idle: "circle.fill"
        case .thinking: "brain.head.profile"
        case .streaming: "waveform"
        case .error: "exclamationmark.triangle.fill"
        }
    }

    private var sessionStatusColor: Color {
        switch session.status {
        case .idle: .secondary
        case .thinking: .orange
        case .streaming: .blue
        case .error: .red
        }
    }

    private var sessionStatusText: String {
        switch session.status {
        case .idle: "idle".localized
        case .thinking: "thinking".localized
        case .streaming: "streaming".localized
        case let .error(message): "Error: \(message)"
        }
    }

    private var userMessageCount: Int {
        session.messages.count(where: { $0.role == .user })
    }

    private var assistantMessageCount: Int {
        session.messages.count(where: { $0.role == .assistant })
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - Subviews

/// 详情行 - 图标 + 标签 + 值
struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    var isMonospaced: Bool = false
    var isCopyable: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(isMonospaced ? .body.monospaced() : .body)
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .textSelection(isCopyable ? .enabled : .disabled)
            }
        }
    }
}

/// 详情标签
struct DetailLabel: View {
    let icon: String
    let text: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
    }
}

/// 状态行 - 图标 + 文本（带颜色）
struct StatusRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(color)

            Text(text)
                .foregroundColor(color)
        }
    }
}

/// 时间详情行 - 相对时间 + 绝对时间
struct TimeDetailRow: View {
    let icon: String
    let label: String
    let relativeTime: String
    let absoluteTime: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(relativeTime)
                    .font(.body)
                    .foregroundColor(.primary)

                Text(absoluteTime)
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
    }
}

/// 统计徽章
struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    SessionDetailView(
        session: createSampleSession()
    )
}

// MARK: - Preview Helper

private func createSampleSession() -> SessionState {
    let session = SessionState(
        sessionId: "demo-session",
        sessionKey: "agent:main:demo-session-key-12345",
        context: "这是一个测试会话的上下文描述，用于展示完整信息的显示效果。"
    )

    session.messages.append(
        ChatMessage(
            id: "msg-1",
            role: .user,
            text: "Hello",
            timestamp: Date().addingTimeInterval(-3600)
        )
    )

    session.messages.append(
        ChatMessage(
            id: "msg-2",
            role: .assistant,
            text: "Hi there!",
            timestamp: Date().addingTimeInterval(-3500)
        )
    )

    session.messages.append(
        ChatMessage(
            id: "msg-3",
            role: .user,
            text: "How are you?",
            timestamp: Date().addingTimeInterval(-60)
        )
    )

    session.status = .idle
    session.isProcessing = false
    session.hasUnreadMessage = true
    session.historyLoaded = true

    return session
}
