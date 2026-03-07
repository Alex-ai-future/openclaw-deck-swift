// SessionDetailView.swift
// OpenClaw Deck Swift
//
// Session 详情视图 - 重构布局

import SwiftUI

/// Session 详情视图 - 重构布局
struct SessionDetailView: View {
    let session: SessionState
    var viewModel: DeckViewModel?
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingArchiveAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 会话信息

                Section {
                    // 基础信息
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

                    // 状态
                    Divider()
                        .padding(.vertical, 8)

                    HStack {
                        Text("status".localized)
                        Spacer()
                        Text(sessionStatusText)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("processing_label".localized)
                        Spacer()
                        Text(session.status == .thinking || session.status == .streaming ? "yes".localized : "no".localized)
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
                } header: {
                    Label("session_info".localized, systemImage: "info.circle")
                }

                // MARK: - 消息

                Section {
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

                    // 工具消息开关
                    Divider()
                        .padding(.vertical, 8)

                    Toggle(
                        "show_tool_messages".localized, systemImage: "wrench.and.screwdriver",
                        isOn: .init(
                            get: { session.showToolMessages },
                            set: { session.showToolMessages = $0 }
                        )
                    )
                } header: {
                    Label("messages".localized, systemImage: "message")
                }

                // MARK: - 时间线

                Section {
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

                    // 加载状态
                    Divider()
                        .padding(.vertical, 8)

                    HStack {
                        Text("history_load_label".localized)
                        Spacer()
                        Text(session.messageLoadState == .loaded ? "history_loaded_status".localized : "history_not_loaded_status".localized)
                            .foregroundColor(.secondary)
                    }

                    if session.messageLoadState == .loading {
                        Text("loading_history_ellipsis".localized)
                            .foregroundColor(.secondary)
                    }

                    if session.messageLoadState == .loading {
                        Text("loading_messages_ellipsis".localized)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Label("timeline".localized, systemImage: "clock")
                }

                // MARK: - 操作

                Section {
                    // 归档并继续
                    Button {
                        showingArchiveAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "archivebox.fill")
                            Text("archive_button".localized)
                            Spacer()
                            Text("\(session.messages.count) msg")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // 删除会话
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("delete_session".localized)
                            Spacer()
                        }
                    }
                    .accessibilityIdentifier("deleteSessionButton")
                } header: {
                    Label("actions".localized, systemImage: "gear")
                } footer: {
                    Text("session_actions_footer".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                .alert("confirm_archive".localized, isPresented: $showingArchiveAlert) {
                    Button("cancel".localized, role: .cancel) {}
                    Button("archive_action".localized) {
                        sendArchiveCommand()
                    }
                } message: {
                    Text(String(format: "archive_confirm_message".localized, session.messages.count))
                }
                .deleteSessionAlert(isPresented: $showingDeleteAlert) {
                    viewModel?.deleteSession(sessionId: session.sessionId)
                    dismiss()
                }
        }
    }

    // MARK: - Actions

    private func sendArchiveCommand() {
        viewModel?.globalInputState.selectedSessionId = session.sessionId
        viewModel?.globalInputState.inputText = "/new"
        Task {
            await viewModel?.sendCurrentInput()
        }
        dismiss()
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
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    SessionDetailView(
        session: SessionState(sessionId: "test", sessionKey: "agent:main:test"),
        viewModel: DeckViewModel()
    )
}
