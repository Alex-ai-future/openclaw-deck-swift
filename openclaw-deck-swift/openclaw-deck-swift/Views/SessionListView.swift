import SwiftUI

// SessionListView.swift
// OpenClaw Deck Swift
//
// Session 列表视图 - 用于 iPhone 单列布局
import os.log

private let logger = Logger(subsystem: "com.openclaw.deck", category: "SessionListView")

/// Session 列表视图 - iPhone 专用
struct SessionListView: View {
    @State private var viewModel: DeckViewModel
    @State private var navigationPath = NavigationPath()
    @State private var showingSettings = false
    @State private var showingNewSessionSheet = false
    @State private var gatewayUrl = "ws://127.0.0.1:18789"
    @State private var token = ""
    @State private var hasAttemptedAutoConnect = false
    @State private var showingDeleteAlert = false
    @State private var deleteSessionId: String?

    init(viewModel: DeckViewModel) {
        _viewModel = State(initialValue: viewModel)

        // 从 UserDefaults 加载配置
        let storage = UserDefaultsStorage.shared
        if let savedUrl = storage.loadGatewayUrl() {
            _gatewayUrl = State(initialValue: savedUrl)
        }
        if let savedToken = storage.loadToken() {
            _token = State(initialValue: savedToken)
        }
    }

    // 内部状态管理
    @State private var showingSyncAlert = false
    @State private var showingConflictAlert = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                // Session 列表
                ForEach(viewModel.sortedSessionIds, id: \.self) { sessionId in
                    if let session = viewModel.getSession(sessionId: sessionId) {
                        NavigationLink(value: session) {
                            SessionRowView(
                                session: session,
                                onRequestDelete: {
                                    // 请求删除：设置待删除的 sessionId，显示弹窗
                                    deleteSessionId = session.sessionId
                                    showingDeleteAlert = true
                                }
                            )
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("openclaw_deck".localized)
            .accessibilityIdentifier("SessionList")
            .toolbar {
                DeckToolbar(
                    viewModel: viewModel,
                    showingSettings: $showingSettings,
                    showingNewSessionSheet: $showingNewSessionSheet,

                    showingSyncAlert: $showingSyncAlert,
                    showingConflictAlert: $showingConflictAlert
                )
            }
            .navigationDestination(for: SessionState.self) { session in
                // 跳转到聊天详情页面（使用现有的 SessionColumnView）
                #if os(iOS)
                    SessionColumnView(
                        session: session,
                        viewModel: viewModel,
                        isSelected: true,
                        onSelect: {
                            viewModel.selectSession(session.sessionId)
                        },
                        onDelete: {
                            viewModel.deleteSession(sessionId: session.sessionId)
                        }
                    )
                    .navigationBarTitleDisplayMode(.inline)
                    .onAppear {
                        // 进入对话时自动标记为已读
                        session.hasUnreadMessage = false
                    }
                #else
                    SessionColumnView(
                        session: session,
                        viewModel: viewModel,
                        isSelected: true,
                        onSelect: {
                            viewModel.selectSession(session.sessionId)
                        },
                        onDelete: {
                            viewModel.deleteSession(sessionId: session.sessionId)
                        }
                    )
                    .onAppear {
                        // 进入对话时自动标记为已读
                        session.hasUnreadMessage = false
                    }
                #endif
            }
            .task {
                // Auto-connect on first launch if credentials exist
                guard !hasAttemptedAutoConnect, !viewModel.gatewayConnected else { return }
                hasAttemptedAutoConnect = true

                if let savedUrl = UserDefaultsStorage.shared.loadGatewayUrl() {
                    let savedToken = UserDefaultsStorage.shared.loadToken()
                    await viewModel.initialize(url: savedUrl, token: savedToken)
                }

                // 调试：打印会话数据
                logSessionData()
            }
            .onAppear {
                // 调试：每次视图出现时打印会话数据
                logSessionData()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(
                    gatewayUrl: $gatewayUrl,
                    token: $token,
                    isConnected: $viewModel.gatewayConnected,
                    onDisconnect: {
                        viewModel.disconnect()
                        showingSettings = false
                    },
                    onApplyAndReconnect: {
                        UserDefaultsStorage.shared.saveGatewayUrl(gatewayUrl)
                        UserDefaultsStorage.shared.saveToken(token)
                        Task {
                            await viewModel.initialize(url: gatewayUrl, token: token)
                        }
                        showingSettings = false
                    },
                    onConnect: {
                        UserDefaultsStorage.shared.saveGatewayUrl(gatewayUrl)
                        UserDefaultsStorage.shared.saveToken(token)
                        Task {
                            await viewModel.initialize(url: gatewayUrl, token: token)
                        }
                        showingSettings = false
                    },
                    onResetDeviceIdentity: {
                        viewModel.resetDeviceIdentity()
                        Task {
                            await viewModel.initialize(url: gatewayUrl, token: token)
                        }
                        showingSettings = false
                    },
                    onClose: {
                        showingSettings = false
                    },
                    viewModel: viewModel
                )
            }
            .sheet(isPresented: $showingNewSessionSheet) {
                NewSessionSheet(
                    viewModel: viewModel,
                    isPresented: $showingNewSessionSheet
                )
            }

            .deckSyncAlerts(
                viewModel: viewModel,
                showingSyncAlert: $showingSyncAlert,
                showingConflictAlert: $showingConflictAlert
            ) { newValue in
                if newValue {
                    showingConflictAlert = true
                } else {
                    showingConflictAlert = false
                }
            }
            // 消息发送失败弹窗
            .alert("message_send_failed".localized, isPresented: $viewModel.showMessageSendError) {
                Button("cancel".localized, role: .cancel) {}
                Button("retry".localized) {
                    Task {
                        // 1. 先重连 Gateway
                        await viewModel.reconnect()

                        // 2. 等待连接成功（最多 3 秒）
                        var waitCount = 0
                        while !viewModel.gatewayConnected, waitCount < 30 {
                            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 秒
                            waitCount += 1
                        }

                        // 3. 检查连接状态
                        if viewModel.gatewayConnected {
                            // 连接成功，发送消息
                            await viewModel.sendCurrentInput()
                        } else {
                            // 仍然失败，更新错误提示
                            viewModel.messageSendErrorText = "cannot_reconnect_check_settings".localized
                            viewModel.showMessageSendError = true
                        }
                    }
                }
            } message: {
                Text("gateway_not_connected_message".localized)
            }
            .deleteSessionAlert(isPresented: $showingDeleteAlert) {
                // 用户确认删除
                if let sessionId = deleteSessionId {
                    viewModel.deleteSession(sessionId: sessionId)
                    deleteSessionId = nil
                }
            }
        }
    }

    // MARK: - Debug

    private func logSessionData() {
        logger.debug(
            "📊 SessionListView: sessionOrder=\(viewModel.sortedSessionIds.count), sessions=\(viewModel.sessions.count), connected=\(viewModel.gatewayConnected)"
        )
    }
}

// MARK: - Session Row View

/// Session 行视图 - 用于列表展示
struct SessionRowView: View {
    @Bindable var session: SessionState
    var onRequestDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Session 图标
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)

                Text(session.sessionId.prefix(1).uppercased())
                    .font(.headline)
                    .foregroundColor(.blue)
            }

            // Session 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(session.sessionId)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if let lastMessage = session.messages.last {
                    Text(lastMessage.text)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("no_messages".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 状态标记：进行中（黄色）优先于未读消息（绿色）
            if session.isProcessing {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
            } else if session.hasUnreadMessage {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            // 左滑：根据当前状态显示已读/未读
            if session.hasUnreadMessage {
                // 当前是未读 → 显示"已读"按钮
                Button {
                    session.hasUnreadMessage = false
                } label: {
                    Label("mark_as_read".localized, systemImage: "checkmark.circle")
                }
                .tint(.green)
            } else {
                // 当前是已读 → 显示"未读"按钮
                Button {
                    session.hasUnreadMessage = true
                } label: {
                    Label("mark_as_unread".localized, systemImage: "circle")
                }
                .tint(.orange)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            // 右滑：删除按钮（全滑动）
            Button(role: .destructive) {
                onRequestDelete()
            } label: {
                Label("delete_session_action".localized, systemImage: "trash")
            }
        }
    }
}

#Preview {
    SessionListView(viewModel: DeckViewModel())
}
