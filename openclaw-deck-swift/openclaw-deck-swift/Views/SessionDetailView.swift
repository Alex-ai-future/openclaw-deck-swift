// SessionDetailView.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 3/2/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import SwiftUI

/// Session 详情视图 - 简洁的表单布局
struct SessionDetailView: View {
    let session: SessionState
    let onDelete: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 基础信息

                Section("basic_info".localized) {
                    Label(session.sessionId, systemImage: "circle.fill")

                    Label(session.sessionKey, systemImage: "tag")
                        .font(.caption.monospaced())
                        .textSelection(.enabled)

                    if let context = session.context, !context.isEmpty {
                        Label("Context", systemImage: "text.alignleft")
                        Text(context)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                }

                // MARK: - 状态

                Section("status".localized) {
                    HStack {
                        Image(systemName: sessionStatusIcon)
                            .foregroundColor(sessionStatusColor)
                        Text(sessionStatusText)
                            .foregroundColor(sessionStatusColor)
                    }

                    HStack {
                        Image(systemName: session.isProcessing ? "gearshape.fill" : "gearshape")
                            .foregroundColor(session.isProcessing ? .orange : .secondary)
                        Text(session.isProcessing ? "processing".localized : "idle".localized)
                            .foregroundColor(session.isProcessing ? .orange : .secondary)
                    }

                    HStack {
                        Image(systemName: session.hasUnreadMessage ? "circle.fill" : "circle")
                            .foregroundColor(session.hasUnreadMessage ? .green : .secondary)
                        Text(session.hasUnreadMessage ? "unread_messages".localized : "all_read".localized)
                            .foregroundColor(session.hasUnreadMessage ? .green : .secondary)
                    }

                    if let runId = session.activeRunId {
                        Label("Active Run", systemImage: "play.circle.fill")
                        Text(runId)
                            .font(.caption.monospaced())
                            .foregroundColor(.blue)
                            .textSelection(.enabled)
                    }
                }

                // MARK: - 消息统计

                Section("message_stats".localized) {
                    Label("\(session.messages.count) " + "total_messages".localized, systemImage: "message.fill")

                    HStack {
                        Label("\(userMessageCount)", systemImage: "person.fill")
                            .foregroundColor(.blue)
                        Spacer()
                        Label("\(assistantMessageCount)", systemImage: "cpu.fill")
                            .foregroundColor(.purple)
                    }
                    .font(.caption)
                }

                // MARK: - 时间信息

                Section("timeline".localized) {
                    if let lastActivity = session.lastMessageAt {
                        Label("last_activity".localized, systemImage: "clock.fill")
                        Text(formatRelativeDate(lastActivity))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDate(lastActivity))
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary.opacity(0.7))
                    }

                    if let firstMessage = session.messages.first {
                        Label("first_message".localized, systemImage: "arrow.up.right.circle.fill")
                        Text(formatRelativeDate(firstMessage.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDate(firstMessage.timestamp))
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }

                // MARK: - 加载状态

                Section("load_status".localized) {
                    HStack {
                        Image(systemName: session.historyLoaded ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(session.historyLoaded ? .green : .secondary)
                        Text("history_loaded".localized)
                            .foregroundColor(session.historyLoaded ? .green : .secondary)
                    }

                    if session.isHistoryLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("loading_history".localized)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }

                    if session.isLoadingMessages {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("loading_messages".localized)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }

                // MARK: - 删除会话

                Section {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("delete_session".localized, systemImage: "trash.fill")
                    }
                }
            }
            .navigationTitle("session_details".localized)
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("done".localized) {
                            dismiss()
                        }
                    }
                }
                .alert("confirm_delete".localized, isPresented: $showingDeleteAlert) {
                    Button("cancel".localized, role: .cancel) {}
                    Button("delete".localized, role: .destructive) {
                        // 删除会话
                        onDelete()
                        dismiss()
                    }
                } message: {
                    Text("delete_session_confirm_message".localized)
                }
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

#Preview {
    SessionDetailView(
        session: createSampleSession(),
        onDelete: {}
    )
}

// MARK: - Preview Helper

private func createSampleSession() -> SessionState {
    let session = SessionState(
        sessionId: "demo-session",
        sessionKey: "agent:main:demo-session-key-12345",
        context: "这是一个测试会话的上下文描述。"
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

    session.status = .idle
    session.isProcessing = false
    session.hasUnreadMessage = true
    session.historyLoaded = true

    return session
}
