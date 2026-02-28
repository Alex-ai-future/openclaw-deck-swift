// SessionListView.swift
// OpenClaw Deck Swift
//
// Session 列表视图 - 用于 iPhone 单列布局

import SwiftUI

/// Session 列表视图 - iPhone 专用
struct SessionListView: View {
  @State private var viewModel: DeckViewModel
  @State private var navigationPath = NavigationPath()
  @State private var showingSettings = false
  @State private var showingNewSessionSheet = false
  @State private var gatewayUrl = "ws://127.0.0.1:18789"
  @State private var token = ""
  @State private var hasAttemptedAutoConnect = false

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

  var body: some View {
    NavigationStack(path: $navigationPath) {
      DeckCommonContainer(
        viewModel: viewModel,
        showingSettings: $showingSettings,
        showingNewSessionSheet: $showingNewSessionSheet,
        gatewayUrl: $gatewayUrl,
        token: $token
      ) {
        List {
          // Session 列表
          ForEach(viewModel.sessionOrder, id: \.self) { sessionId in
            if let session = viewModel.getSession(sessionId: sessionId) {
              NavigationLink(value: session) {
                SessionRowView(session: session)
              }
            }
          }
          .onDelete(perform: deleteSessions)
        }
        .listStyle(.plain)
      }
      .navigationDestination(for: SessionState.self) { session in
        // 跳转到聊天详情页面（使用现有的 SessionColumnView）
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
      }
      .task {
        // Auto-connect on first launch if credentials exist
        guard !hasAttemptedAutoConnect && !viewModel.gatewayConnected else { return }
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
    }
  }

  // MARK: - Debug

  private func logSessionData() {
    print("📊 SessionListView: sessionOrder.count = \(viewModel.sessionOrder.count)")
    print("📊 SessionListView: sessions.count = \(viewModel.sessions.count)")
    print("📊 SessionListView: gatewayConnected = \(viewModel.gatewayConnected)")
  }

  // MARK: - Delete Sessions

  private func deleteSessions(at offsets: IndexSet) {
    for index in offsets {
      if index < viewModel.sessionOrder.count {
        let sessionId = viewModel.sessionOrder[index]
        viewModel.deleteSession(sessionId: sessionId)
      }
    }
  }
}

// MARK: - Session Row View

/// Session 行视图 - 用于列表展示
struct SessionRowView: View {
  @Bindable var session: SessionState

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
          Text("No messages")
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
  }
}

#Preview {
  SessionListView(viewModel: DeckViewModel())
}
