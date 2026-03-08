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
            // Session 列表
            List {
                ForEach(viewModel.sessionOrder, id: \.self) { sessionId in
                    if let session = viewModel.getSession(sessionId: sessionId) {
                        NavigationLink(value: session) {
                            SessionRowView(
                                session: session,
                                style: .list,
                                showStatus: true,
                                showLastMessage: true,
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
            .navigationTitle("")
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
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .onAppear {
                    session.hasUnreadMessage = false
                }
            }
            .task {
                guard !hasAttemptedAutoConnect, !(viewModel.gatewayClient?.connected ?? false) else { return }
                hasAttemptedAutoConnect = true

                if let savedUrl = UserDefaultsStorage.shared.loadGatewayUrl() {
                    let savedToken = UserDefaultsStorage.shared.loadToken()
                    await viewModel.initialize(url: savedUrl, token: savedToken)
                }

                logSessionData()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(isConnected: (viewModel.gatewayClient?.connected ?? false), viewModel: viewModel)
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
            "📊 SessionListView: sessionOrder=\(viewModel.sessionOrder.count), sessions=\(viewModel.sessions.count), connected=\((viewModel.gatewayClient?.connected ?? false))"
        )
    }
}

// MARK: - Preview

#Preview {
    SessionListView(viewModel: DeckViewModel())
}
