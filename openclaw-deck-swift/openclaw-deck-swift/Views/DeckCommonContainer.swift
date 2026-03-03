// DeckCommonContainer.swift
// OpenClaw Deck Swift
//
// 共用的容器组件 - 提取 DeckView 和 SessionListView 的共同逻辑

import os.log
import SwiftUI

private let logger = Logger(subsystem: "com.openclaw.deck", category: "DeckCommonContainer")

/// Deck 共用容器 - 管理共同的状态和 UI 组件
struct DeckCommonContainer<Content: View>: View {
    @Bindable var viewModel: DeckViewModel
    @Binding var showingSettings: Bool
    @Binding var showingNewSessionSheet: Bool

    // 可选的配置（用于 SessionListView）
    var gatewayUrl: Binding<String>?
    var token: Binding<String>?

    /// 内部状态管理
    @State private var showingSortSheet = false

    // 本地配置状态（当没有外部传入时使用）
    @State private var localGatewayUrl: String = ""
    @State private var localToken: String = ""

    /// 平台特定的内容
    @ViewBuilder let content: Content

    var body: some View {
        content
            .onAppear {
                // 初始化本地配置（如果没有外部传入）
                if gatewayUrl == nil {
                    localGatewayUrl = UserDefaultsStorage.shared.loadGatewayUrl() ?? "ws://127.0.0.1:18789"
                }
                if token == nil {
                    localToken = UserDefaultsStorage.shared.loadToken() ?? ""
                }
            }
            // Settings Sheet
            .sheet(isPresented: $showingSettings) {
                SettingsView(
                    gatewayUrl: gatewayUrl ?? $localGatewayUrl,
                    token: token ?? $localToken,
                    isConnected: $viewModel.gatewayConnected,
                    onDisconnect: {
                        viewModel.disconnect()
                        showingSettings = false
                    },
                    onApplyAndReconnect: {
                        // 使用当前配置（外部传入或本地状态）
                        let urlToUse = gatewayUrl?.wrappedValue ?? localGatewayUrl
                        let tokenToUse = token?.wrappedValue ?? localToken

                        // Save new config first
                        UserDefaultsStorage.shared.saveGatewayUrl(urlToUse)
                        UserDefaultsStorage.shared.saveToken(tokenToUse)

                        Task {
                            await viewModel.initialize(url: urlToUse, token: tokenToUse)
                        }
                        showingSettings = false
                    },
                    onConnect: {
                        // 使用当前配置（外部传入或本地状态）
                        let urlToUse = gatewayUrl?.wrappedValue ?? localGatewayUrl
                        let tokenToUse = token?.wrappedValue ?? localToken

                        // Save new config first
                        UserDefaultsStorage.shared.saveGatewayUrl(urlToUse)
                        UserDefaultsStorage.shared.saveToken(tokenToUse)

                        Task {
                            await viewModel.initialize(url: urlToUse, token: tokenToUse)
                            showingSettings = false
                        }
                    },
                    onResetDeviceIdentity: {
                        // 使用当前配置（外部传入或本地状态）
                        let urlToUse = gatewayUrl?.wrappedValue ?? localGatewayUrl
                        let tokenToUse = token?.wrappedValue ?? localToken

                        // Save new config first
                        UserDefaultsStorage.shared.saveGatewayUrl(urlToUse)
                        UserDefaultsStorage.shared.saveToken(tokenToUse)

                        viewModel.resetDeviceIdentity()
                        Task {
                            await viewModel.initialize(url: urlToUse, token: tokenToUse)
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
    }
}

#Preview("iPad") {
    NavigationStack {
        DeckCommonContainer(
            viewModel: DeckViewModel(),
            showingSettings: .constant(false),
            showingNewSessionSheet: .constant(false)
        ) {
            Text("ipad_content".localized)
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
                Text("iphone_content".localized)
            }
        }
    }
}
