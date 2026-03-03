// SessionDetailView.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 3/2/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import SwiftUI

/// Session 详情视图 - 极简布局
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
                    HStack {
                        Text("session_id_label".localized)
                        Spacer()
                        Text(session.sessionId)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("session_key_label".localized)
                        Spacer()
                        Text(session.sessionKey)
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }

                    if let context = session.context, !context.isEmpty {
                        HStack {
                            Text("session_context_label".localized)
                            Spacer()
                            Text(context)
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                }

                // MARK: - 状态

                Section("status".localized) {
                    HStack {
                        Text("status".localized)
                        Spacer()
                        Text(sessionStatusText)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("processing_label".localized)
                        Spacer()
                        Text(session.isProcessing ? "yes".localized : "no".localized)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("unread_messages_label".localized)
                        Spacer()
                        Text(session.hasUnreadMessage ? "yes".localized : "no".localized)
                            .foregroundColor(.secondary)
                    }

                    if let runId = session.activeRunId {
                        HStack {
                            Text("active_run_label".localized)
                            Spacer()
                            Text(runId)
                                .font(.caption.monospaced())
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                }

                // MARK: - 消息统计

                Section("message_stats".localized) {
                    HStack {
                        Text("total_messages_label".localized)
                        Spacer()
                        Text("\(session.messages.count)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("user_messages_label".localized)
                        Spacer()
                        Text("\(userMessageCount)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("assistant_messages_label".localized)
                        Spacer()
                        Text("\(assistantMessageCount)")
                            .foregroundColor(.secondary)
                    }
                }

                // MARK: - 时间

                Section("timeline".localized) {
                    if let lastActivity = session.lastMessageAt {
                        HStack {
                            Text("last_activity_label".localized)
                            Spacer()
                            Text("\(formatRelativeDate(lastActivity)) (\(formatDateTime(lastActivity)))")
                                .foregroundColor(.secondary)
                                .font(.caption2)
                        }
                    }

                    if let firstMessage = session.messages.first {
                        HStack {
                            Text("first_message_label".localized)
                            Spacer()
                            Text("\(formatRelativeDate(firstMessage.timestamp)) (\(formatDateTime(firstMessage.timestamp)))")
                                .foregroundColor(.secondary)
                                .font(.caption2)
                        }
                    }
                }

                // MARK: - 加载状态

                Section("load_status".localized) {
                    HStack {
                        Text("history_load_label".localized)
                        Spacer()
                        Text(session.historyLoaded ? "history_loaded_status".localized : "history_not_loaded_status".localized)
                            .foregroundColor(.secondary)
                    }

                    if session.isHistoryLoading {
                        Text("loading_history_ellipsis".localized)
                            .foregroundColor(.secondary)
                    }

                    if session.isLoadingMessages {
                        Text("loading_messages_ellipsis".localized)
                            .foregroundColor(.secondary)
                    }
                }

                // MARK: - 删除会话

                Section {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Text("delete_session".localized)
                    }
                    .accessibilityIdentifier("deleteSessionButton")
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
                        onDelete()
                        dismiss()
                    }
                } message: {
                    Text("delete_session_confirm_message".localized)
                }
        }
    }

    // MARK: - Helpers

    private var sessionStatusText: String {
        switch session.status {
        case .idle: "idle"
        case .thinking: "thinking"
        case .streaming: "streaming"
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

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    SessionDetailView(
        session: createSampleSession(),
        onDelete: {
            print("Delete session (preview)")
        }
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
