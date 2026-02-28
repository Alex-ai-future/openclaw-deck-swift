// DeckCommonContainer.swift
// OpenClaw Deck Swift
//
// 共用的容器组件 - 提取 DeckView 和 SessionListView 的共同逻辑

import SwiftUI
import os.log

private let logger = Logger(subsystem: "com.openclaw.deck", category: "DeckCommonContainer")

/// Deck 共用容器 - 管理共同的状态和 UI 组件
struct DeckCommonContainer<Content: View>: View {
  @Bindable var viewModel: DeckViewModel
  @Binding var showingSettings: Bool
  @Binding var showingNewSessionSheet: Bool

  // 可选的配置（用于 SessionListView）
  var gatewayUrl: Binding<String>?
  var token: Binding<String>?

  // 内部状态管理
  @State private var showingSortSheet = false
  @State private var showingSyncAlert = false
  @State private var showingConflictAlert = false

  // 平台特定的内容
  @ViewBuilder let content: Content

  var body: some View {
    content
      .navigationTitle("OpenClaw Deck")
      .toolbar {
        DeckToolbar(
          viewModel: viewModel,
          showingSettings: $showingSettings,
          showingNewSessionSheet: $showingNewSessionSheet,
          showingSortSheet: $showingSortSheet,
          showingSyncAlert: $showingSyncAlert,
          showingConflictAlert: $showingConflictAlert
        )
      }

      // Settings Sheet
      .sheet(isPresented: $showingSettings) {
          SettingsView(
            gatewayUrl: gatewayUrl ?? .constant(""),
            token: token ?? .constant(""),
            isConnected: .constant(viewModel.gatewayConnected),
            onDisconnect: {
              viewModel.disconnect()
              showingSettings = false
            },
            onApplyAndReconnect: {
              // Save new config first
              if let url = gatewayUrl?.wrappedValue, !url.isEmpty {
                UserDefaultsStorage.shared.saveGatewayUrl(url)
              }
              if let token = token?.wrappedValue {
                UserDefaultsStorage.shared.saveToken(token)
              }

              Task {
                await viewModel.initialize(
                  url: gatewayUrl?.wrappedValue ?? UserDefaultsStorage.shared.loadGatewayUrl()
                    ?? "",
                  token: token?.wrappedValue ?? UserDefaultsStorage.shared.loadToken()
                )
              }
              showingSettings = false
            },
            onConnect: {
              // Save new config first
              if let url = gatewayUrl?.wrappedValue, !url.isEmpty {
                UserDefaultsStorage.shared.saveGatewayUrl(url)
              }
              if let token = token?.wrappedValue {
                UserDefaultsStorage.shared.saveToken(token)
              }

              Task {
                await viewModel.initialize(
                  url: gatewayUrl?.wrappedValue ?? UserDefaultsStorage.shared.loadGatewayUrl()
                    ?? "",
                  token: token?.wrappedValue ?? UserDefaultsStorage.shared.loadToken()
                )
                showingSettings = false
              }
            },
            onResetDeviceIdentity: {
              // Save new config first
              if let url = gatewayUrl?.wrappedValue, !url.isEmpty {
                UserDefaultsStorage.shared.saveGatewayUrl(url)
              }
              if let token = token?.wrappedValue {
                UserDefaultsStorage.shared.saveToken(token)
              }

              viewModel.resetDeviceIdentity()
              Task {
                await viewModel.initialize(
                  url: gatewayUrl?.wrappedValue ?? UserDefaultsStorage.shared.loadGatewayUrl()
                    ?? "",
                  token: token?.wrappedValue ?? UserDefaultsStorage.shared.loadToken()
                )
                showingSettings = false
              }
            },
            onClose: {
              showingSettings = false
            },
            viewModel: viewModel
          )
        }

        // New Session Sheet
        .sheet(isPresented: $showingNewSessionSheet) {
          NewSessionSheet(
            viewModel: viewModel,
            isPresented: $showingNewSessionSheet
          )
        }

        // Sort Sheet
        .sheet(isPresented: $showingSortSheet) {
          SessionSortView(viewModel: viewModel)
        }

        // Sync Alerts
        .deckSyncAlerts(
          viewModel: viewModel,
          showingSyncAlert: $showingSyncAlert,
          showingConflictAlert: $showingConflictAlert
        ) { newValue in
          if newValue {
            showingConflictAlert = true
            logger.info("🔔 Conflict alert triggered, showingConflictAlert = true")
          } else {
            showingConflictAlert = false
            logger.info("🔔 Conflict alert dismissed, showingConflictAlert = false")
          }
        }
    }
  }
}

#Preview("iPad") {
  NavigationStack {
    DeckCommonContainer(
      viewModel: DeckViewModel(),
      showingSettings: .constant(false),
      showingNewSessionSheet: .constant(false)
    ) {
      Text("iPad Content")
    }
  }
}

#Preview("iPhone") {
  NavigationStack {
    DeckCommonContainer(
      viewModel: DeckViewModel(),
      showingSettings: .constant(false),
      showingNewSessionSheet: .constant(false)
    ) {
      List {
        Text("iPhone Content")
      }
    }
  }
}
