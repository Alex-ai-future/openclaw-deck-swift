// SessionDetailView.swift
// OpenClaw Deck Swift
//
// Session 详情视图 - 极简布局

import SwiftUI

/// Session 详情视图 - 极简布局
struct SessionDetailView: View {
    let session: SessionState
    var viewModel: DeckViewModel?
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingArchiveAlert = false

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

                // MARK: - 归档并继续

                Section {
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

                    Text("archive_description".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("archive_section_header".localized)
                }

                // MARK: - 危险操作

                Section {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("delete_session".localized)
                            Spacer()
                        }
                    }

                    Text("delete_description".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("delete_section_header".localized)
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
