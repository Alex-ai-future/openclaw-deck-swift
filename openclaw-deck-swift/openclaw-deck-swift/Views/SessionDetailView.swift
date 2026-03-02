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
                    Text("ID: \(session.sessionId)")
                    Text("Key: \(session.sessionKey)")
                        .font(.caption.monospaced())
                        .textSelection(.enabled)

                    if let context = session.context, !context.isEmpty {
                        Text("备注：\(context)")
                            .textSelection(.enabled)
                    }
                }

                // MARK: - 状态

                Section("status".localized) {
                    Text("状态：\(sessionStatusText)")
                    Text("处理中：\(session.isProcessing ? "是" : "否")")
                    Text("未读消息：\(session.hasUnreadMessage ? "是" : "否")")

                    if let runId = session.activeRunId {
                        Text("活跃 Run: \(runId)")
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                }

                // MARK: - 消息统计

                Section("message_stats".localized) {
                    Text("总消息数：\(session.messages.count)")
                    Text("User 消息：\(userMessageCount)")
                    Text("Assistant 消息：\(assistantMessageCount)")
                }

                // MARK: - 时间

                Section("timeline".localized) {
                    if let lastActivity = session.lastMessageAt {
                        Text("最后活动：\(formatRelativeDate(lastActivity)) (\(formatDateTime(lastActivity)))")
                    }

                    if let firstMessage = session.messages.first {
                        Text("第一条消息：\(formatRelativeDate(firstMessage.timestamp)) (\(formatDateTime(firstMessage.timestamp)))")
                    }
                }

                // MARK: - 加载状态

                Section("load_status".localized) {
                    Text("历史加载：\(session.historyLoaded ? "已完成" : "未完成")")

                    if session.isHistoryLoading {
                        Text("状态：正在加载历史...")
                    }

                    if session.isLoadingMessages {
                        Text("状态：正在加载消息...")
                    }
                }

                // MARK: - 删除会话

                Section {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Text("delete_session".localized)
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
