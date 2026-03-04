// SessionListView.swift
// OpenClaw Deck Swift
//
// Session 列表视图 - iPhone 单列布局（简洁现代设计）

import os.log
import SwiftUI

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

    /// 内部状态管理
    @State private var showingSortSheet = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.sessionOrder.isEmpty {
                    // 空状态
                    EmptySessionListView(onCreateNew: {
                        showingNewSessionSheet = true
                    })
                } else {
                    // Session 列表
                    List {
                        ForEach(viewModel.sessionOrder, id: \.self) { sessionId in
                            if let session = viewModel.getSession(sessionId: sessionId) {
                                NavigationLink(value: session) {
                                    SessionRowView(
                                        session: session,
                                        onRequestDelete: {
                                            deleteSessionId = session.sessionId
                                            showingDeleteAlert = true
                                        }
                                    )
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("openclaw_deck".localized)
            .navigationBarTitleDisplayMode(.large)
            .accessibilityIdentifier("SessionList")
            .toolbar {
                DeckToolbar(
                    viewModel: viewModel,
                    showingSettings: $showingSettings,
                    showingNewSessionSheet: $showingNewSessionSheet,
                    showingSortSheet: $showingSortSheet
                )
            }
            .navigationDestination(for: SessionState.self) { session in
                SessionColumnView(
                    session: session,
                    viewModel: viewModel,
                    isSelected: true
                )
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    session.hasUnreadMessage = false
                }
            }
            .task {
                guard !hasAttemptedAutoConnect, !viewModel.gatewayConnected else { return }
                hasAttemptedAutoConnect = true

                if let savedUrl = UserDefaultsStorage.shared.loadGatewayUrl() {
                    let savedToken = UserDefaultsStorage.shared.loadToken()
                    await viewModel.initialize(url: savedUrl, token: savedToken)
                }

                logSessionData()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(isConnected: $viewModel.gatewayConnected, viewModel: viewModel)
            }
            .sheet(isPresented: $showingNewSessionSheet) {
                NewSessionSheet(viewModel: viewModel, isPresented: $showingNewSessionSheet)
            }
            .sheet(isPresented: $showingSortSheet) {
                SessionSortView(viewModel: viewModel)
            }
            .deleteSessionAlert(isPresented: $showingDeleteAlert) {
                if let sessionId = deleteSessionId {
                    Task.detached { [weak viewModel] in
                        await viewModel?.deleteSession(sessionId: sessionId)
                        await MainActor.run {
                            deleteSessionId = nil
                        }
                    }
                }
            }
        }
    }

    private func logSessionData() {
        logger.debug(
            "📊 SessionListView: sessionOrder=\(viewModel.sessionOrder.count), sessions=\(viewModel.sessions.count), connected=\(viewModel.gatewayConnected)"
        )
    }
}

// MARK: - Empty State View

/// 空状态视图 - 引导用户创建第一个 Session
struct EmptySessionListView: View {
    let onCreateNew: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "message.badge.filled.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.8))

            Text("No sessions yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create your first session to start chatting")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: onCreateNew) {
                HStack {
                    Image(systemName: "plus")
                    Text("New Session")
                }
                .fontWeight(.medium)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Session Row View

/// Session 行视图 - 简洁现代设计
struct SessionRowView: View {
    @Bindable var session: SessionState
    var onRequestDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Session 图标 - 圆角方形
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.blue.opacity(0.05)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Text(session.sessionId.prefix(1).uppercased())
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
            }

            // Session 信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.sessionId)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    // 状态指示器
                    if session.isProcessing {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 6, height: 6)
                            Text("Processing")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.orange)
                        }
                    } else if session.hasUnreadMessage {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("New")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.green)
                        }
                    }
                }

                if let lastMessage = session.messages.last {
                    Text(lastMessage.text)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("No messages yet")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.tertiary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if session.hasUnreadMessage {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        session.hasUnreadMessage = false
                    }
                } label: {
                    Label("Read", systemImage: "checkmark.circle")
                }
                .tint(.green)
            } else {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        session.hasUnreadMessage = true
                    }
                } label: {
                    Label("Unread", systemImage: "circle")
                }
                .tint(.orange)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onRequestDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SessionListView(viewModel: DeckViewModel())
}
