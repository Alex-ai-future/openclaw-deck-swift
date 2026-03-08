// ContentView.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import os.log
import SwiftUI

private let logger = Logger(subsystem: "com.openclaw.deck", category: "ContentView")

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

// MARK: - Cross-Platform Color Extension

extension Color {
    /// Adaptive background color for cross-platform support
    static var adaptiveBackground: Color {
        #if os(macOS)
            if #available(macOS 10.15, *) {
                return Color(NSColor.windowBackgroundColor)
            } else {
                return Color(NSColor.textBackgroundColor)
            }
        #else
            return Color(UIColor.systemBackground)
        #endif
    }

    /// Adaptive secondary background color
    static var adaptiveSecondaryBackground: Color {
        #if os(macOS)
            if #available(macOS 10.15, *) {
                return Color(NSColor.controlBackgroundColor)
            } else {
                return Color(NSColor.controlColor)
            }
        #else
            return Color(UIColor.secondarySystemBackground)
        #endif
    }
}

struct ContentView: View {
    @State private var viewModel = DeckViewModel()
    @State private var showingSettings = false
    @State private var gatewayUrl = "ws://127.0.0.1:18789"
    @State private var token = ""
    @State private var showingNewSessionSheet = false
    @State private var hasAttemptedAutoConnect = false
    @State private var showingWelcomeSettings = false
    @State private var hasLoadedSavedConfig = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            // 🧪 UI Test 模式：跳过连接检查，直接显示主界面
            if ProcessInfo.processInfo.environment["UITESTING"] == "YES" {
                // UI Test 模式，显示主界面
                // 📦 全局布局：内容区 + 全局输入框
                VStack(spacing: 0) {
                    // 内容区 - 使用 ViewThatFits 自动适配屏幕尺寸（iOS 16+）
                    ViewThatFits(in: .horizontal) {
                        // 宽屏 - 多列平铺布局（需要至少 700pt 宽度）
                        DeckView(
                            viewModel: viewModel,
                            showingSettings: $showingSettings,
                            showingNewSessionSheet: $showingNewSessionSheet
                        )
                        .frame(minWidth: 700, maxWidth: .infinity, maxHeight: .infinity)

                        // 窄屏 - 单列列表布局（自动 fallback）
                        SessionListView(viewModel: viewModel)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    // 全局输入框 - 固定在底部（所有视图共用）
                    GlobalInputView(state: viewModel.globalInputState as! GlobalInputState) {
                        await viewModel.sendCurrentInput()
                    }
                }
            } else if viewModel.gatewayClient?.connected ?? false {
                // ✅ 已连接
                if case .connected = viewModel.appState {
                    // 加载完成 → 显示聊天界面
                    // 📦 全局布局：内容区 + 全局输入框
                    VStack(spacing: 0) {
                        // 内容区 - 使用 ViewThatFits 自动适配屏幕尺寸（iOS 16+）
                        ViewThatFits(in: .horizontal) {
                            // 宽屏 - 多列平铺布局（需要至少 700pt 宽度）
                            DeckView(
                                viewModel: viewModel,
                                showingSettings: $showingSettings,
                                showingNewSessionSheet: $showingNewSessionSheet
                            )
                            .frame(minWidth: 700, maxWidth: .infinity, maxHeight: .infinity)

                            // 窄屏 - 单列列表布局（自动 fallback）
                            SessionListView(viewModel: viewModel)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }

                        // 全局输入框 - 固定在底部（所有视图共用）
                        GlobalInputView(state: viewModel.globalInputState as! GlobalInputState) {
                            await viewModel.sendCurrentInput()
                        }
                    }
                } else {
                    // 加载中时显示 LoadingView（带工具栏）
                    LoadingView(
                        appState: viewModel.appState,
                        viewModel: viewModel,
                        onShowSettings: { showingSettings = true }
                    )
                }
            } else if viewModel.appState.isLoading {
                // ✅ 初始化连接中（带工具栏）
                LoadingView(
                    appState: viewModel.appState,
                    viewModel: viewModel,
                    onShowSettings: { showingSettings = true }
                )
            } else {
                // ❌ 未连接
                WelcomeView(
                    gatewayUrl: $gatewayUrl,
                    token: $token,
                    connectionError: viewModel.gatewayClient?.connectionError,
                    isConnecting: viewModel.appState.isLoading,
                    connectionStatus: viewModel.gatewayClient?.connectionStatus ?? .disconnected,
                    onClearError: {
                        viewModel.clearConnectionError()
                    },
                    onShowSettings: {
                        showingWelcomeSettings = true
                    }
                )
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                isConnected: (viewModel.gatewayClient?.connected ?? false),
                viewModel: viewModel
            )
        }
        .sheet(isPresented: $showingWelcomeSettings) {
            SettingsView(
                isConnected: false,
                viewModel: viewModel
            )
        }
        // 新建会话弹窗
        .sheet(isPresented: $showingNewSessionSheet) {
            NewSessionSheet(viewModel: viewModel, isPresented: $showingNewSessionSheet)
        }
        // 同步确认弹窗（全局）
        .alert("sync_all_sessions".localized, isPresented: .init(
            get: { viewModel.isSyncing && !viewModel.showingSyncConflict },
            set: { newValue in
                // 用户点"取消"或关闭弹窗时，重置 isSyncing
                if !newValue {
                    viewModel.isSyncing = false
                }
            }
        )) {
            Button("cancel".localized, role: .cancel) {
                // 点"取消"：重置 isSyncing，不同步
                viewModel.isSyncing = false
            }
            Button("sync".localized) {
                // 点"确定"：直接重新创建 ViewModel（自动处理所有逻辑，包括冲突）
                viewModel.isSyncing = false
                Task {
                    // ✅ 直接重新创建 ViewModel，自动处理所有逻辑（包括冲突）
                    let newViewModel = DeckViewModel()

                    // ✅ 用新的替换旧的
                    self.viewModel = newViewModel

                    // ✅ 新 ViewModel 会自动初始化
                    let gatewayUrl = UserDefaults.standard.string(forKey: "openclaw.deck.gatewayUrl") ?? "ws://127.0.0.1:18789"
                    let token = UserDefaults.standard.string(forKey: "openclaw.deck.token")
                    await newViewModel.initialize(url: gatewayUrl, token: token)
                }
            }
            .tint(.blue)
        } message: {
            Text("this_will_sync_all_sessions_with_the_gateway_continue".localized)
        }

        // 同步冲突弹窗（全局）
        .alert("sync_conflict".localized, isPresented: .init(
            get: { viewModel.showingSyncConflict },
            set: { _ in }
        )) {
            Button("use_local_overwrite_cloud".localized, role: .destructive) {
                Task {
                    await viewModel.resolveSyncConflict(choice: "local")
                }
            }
            Button("use_cloud_merge_with_local".localized) {
                Task {
                    await viewModel.resolveSyncConflict(choice: "remote")
                }
            }
            Button("cancel".localized, role: .cancel) {
                Task {
                    await viewModel.resolveSyncConflict(choice: "cancel")
                }
            }
        } message: {
            if let info = viewModel.conflictInfo {
                Text(info.description)
            } else {
                let localCount = viewModel.conflictLocalData?.sessions.count ?? 0
                let remoteCount = viewModel.conflictRemoteData?.sessions.count ?? 0
                Text(
                    "Local has \(localCount) sessions, Cloud has \(remoteCount) sessions.\n\nChoose which data to use:"
                )
            }
        }

        // 消息发送失败弹窗（全局统一）
        .alert("connection_error".localized, isPresented: $viewModel.showMessageSendError) {
            Button("ok".localized, role: .cancel) {}
        } message: {
            Text(viewModel.messageSendErrorText)
        }

        .task {
            // 首先加载保存的配置到 @State 变量
            if !hasLoadedSavedConfig {
                let storage = UserDefaultsStorage.shared
                if let savedUrl = storage.loadGatewayUrl() {
                    gatewayUrl = savedUrl
                }
                if let savedToken = storage.loadToken() {
                    token = savedToken
                }
                hasLoadedSavedConfig = true
            }

            // Auto-connect on first launch if credentials exist
            guard !hasAttemptedAutoConnect, !(viewModel.gatewayClient?.connected ?? false) else { return }
            // 🧪 UI 测试模式：跳过 Gateway 连接，但需要初始化 Session
            if ProcessInfo.processInfo.environment["UITESTING"] == "YES" {
                hasAttemptedAutoConnect = true
                // UI 测试模式：调用 initialize 但不连接 Gateway
                await viewModel.initialize(url: "http://test", token: nil)
                return
            }
            hasAttemptedAutoConnect = true

            logger.debug("Attempting auto-connect...")
            if let savedUrl = UserDefaultsStorage.shared.loadGatewayUrl() {
                let savedToken = UserDefaultsStorage.shared.loadToken()
                logger.debug("Found saved credentials: \(savedUrl)")
                await viewModel.initialize(url: savedUrl, token: savedToken)
            } else {
                logger.debug("No saved credentials found")
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // 当应用从后台进入前台时，检查是否需要自动重连
            guard newPhase == .active else { return }

            // 如果已连接或正在连接，不需要重连
            guard !(viewModel.gatewayClient?.connected ?? false), !viewModel.appState.isLoading else { return }

            // 检查是否有保存的凭证
            guard let savedUrl = UserDefaultsStorage.shared.loadGatewayUrl() else { return }

            logger.debug("应用进入前台，检测到连接断开，自动重连...")
            let savedToken = UserDefaultsStorage.shared.loadToken()
            Task {
                await viewModel.initialize(url: savedUrl, token: savedToken)
            }
        }
    }
}

// MARK: - Connecting View

struct ConnectingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("connecting_to_gateway".localized)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.adaptiveBackground)
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    @Binding var gatewayUrl: String
    @Binding var token: String
    let connectionError: String?
    let isConnecting: Bool
    let connectionStatus: ConnectionStatus
    let onClearError: () -> Void
    let onShowSettings: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Logo and title
                VStack(spacing: 16) {
                    Image(systemName: "message.badge.filled.fill")
                        .font(.system(size: 72))
                        .foregroundColor(.blue)

                    Text("openclaw_deck".localized)
                        .font(.title)
                        .fontWeight(.bold)

                    Text("multi_session_chat_client".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)

                // First install guide card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.orange)
                        Text("first_install".localized)
                            .font(.headline)
                    }

                    Text("first_install_guide".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Link(destination: URL(string: "https://alex-ai-future.github.io/openclaw-deck-swift/USER_GUIDE.html")!) {
                        HStack {
                            Label("view_user_guide".localized, systemImage: "book.fill")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.adaptiveSecondaryBackground)
                .cornerRadius(12)
                .padding(.horizontal, 24)

                // Login guide card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "hand.point.up.fill")
                            .foregroundColor(.blue)
                        Text("login_required".localized)
                            .font(.headline)
                    }

                    Text("login_guide".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Image(systemName: "gearshape.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("tap_settings_to_configure".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.top, 4)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.adaptiveSecondaryBackground)
                .cornerRadius(12)
                .padding(.horizontal, 24)

                Spacer()

                // Error message
                if let error = connectionError {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("connection_failed".localized)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                            Spacer()
                            Button("dismiss".localized, action: onClearError)
                                .font(.caption)
                        }

                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.adaptiveBackground)
            .navigationTitle("")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    // 使用统一的 DeckToolbar 组件（简化模式：无右侧按钮）
                    DeckToolbar(
                        viewModel: nil,
                        connectionStatus: connectionStatus,
                        showingSettings: .constant(false),
                        onShowSettings: onShowSettings,
                        showingNewSessionSheet: nil,
                        showingSortSheet: nil
                    )
                }
        }
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    var hexString: String? {
        #if os(macOS)
            guard let color = NSColor(self).cgColor.components,
                  color.count >= 3
            else {
                return nil
            }

            let r = Int(color[0] * 255)
            let g = Int(color[1] * 255)
            let b = Int(color[2] * 255)

            return String(format: "#%02X%02X%02X", r, g, b)
        #else
            guard let components = UIColor(self).cgColor.components,
                  components.count >= 3
            else {
                return nil
            }

            let r = Int(components[0] * 255)
            let g = Int(components[1] * 255)
            let b = Int(components[2] * 255)

            return String(format: "#%02X%02X%02X", r, g, b)
        #endif
    }
}

#Preview {
    ContentView()
}
