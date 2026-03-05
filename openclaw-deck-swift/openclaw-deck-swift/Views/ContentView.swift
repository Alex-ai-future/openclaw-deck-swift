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

    /// 判断是否为 iPad
    var isIPad: Bool {
        DeviceUtils.isIPad
    }

    var body: some View {
        Group {
            if isUITesting {
                // UI Test 模式
                mainInterface
            } else if isReady {
                // 已连接且加载完成
                mainInterface
            } else if isLoading {
                // 加载中
                LoadingView(stage: viewModel.loadingStage, progress: viewModel.loadingProgress)
            } else {
                // Welcome screen
                welcomeInterface
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(isConnected: viewModel.gatewayConnected, viewModel: viewModel)
        }
        .sheet(isPresented: $showingWelcomeSettings) {
            SettingsView(isConnected: false, viewModel: viewModel)
        }
        .task {
            await setupAndAutoConnect()
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    // MARK: - Computed Properties

    private var isUITesting: Bool {
        ProcessInfo.processInfo.environment["UITESTING"] == "YES"
    }

    private var isReady: Bool {
        viewModel.gatewayConnected
    }

    private var isLoading: Bool {
        viewModel.loadingStage != .idle
    }

    // MARK: - Subviews

    @ViewBuilder
    private var mainInterface: some View {
        #if os(macOS)
            DeckView(
                viewModel: viewModel,
                showingSettings: $showingSettings,
                showingNewSessionSheet: $showingNewSessionSheet
            )
        #elseif os(iOS)
            if isIPad {
                DeckView(
                    viewModel: viewModel,
                    showingSettings: $showingSettings,
                    showingNewSessionSheet: $showingNewSessionSheet
                )
            } else {
                SessionListView(viewModel: viewModel)
            }
        #else
            SessionListView(viewModel: viewModel)
        #endif
    }

    private var welcomeInterface: some View {
        WelcomeView(
            gatewayUrl: $gatewayUrl,
            token: $token,
            connectionError: viewModel.connectionError,
            isConnecting: viewModel.isInitializing,
            onClearError: {
                viewModel.connectionError = nil
            },
            onShowSettings: {
                showingWelcomeSettings = true
            }
        )
    }

    // MARK: - Setup

    private func setupAndAutoConnect() async {
        // 加载配置
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

        // Auto-connect
        guard !hasAttemptedAutoConnect, !viewModel.gatewayConnected else { return }
        hasAttemptedAutoConnect = true

        if let savedUrl = UserDefaultsStorage.shared.loadGatewayUrl() {
            let savedToken = UserDefaultsStorage.shared.loadToken()
            await viewModel.initialize(url: savedUrl, token: savedToken)
            
            // ✅ 初始化完成后自动选中第一个 Session
            if let firstSessionId = viewModel.sessionOrder.first {
                await viewModel.selectSession(firstSessionId)
            }
        }
    }

    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        guard newPhase == .active else { return }
        guard !viewModel.gatewayConnected, !viewModel.isInitializing else { return }
        guard let savedUrl = UserDefaultsStorage.shared.loadGatewayUrl() else { return }

        logger.debug("应用进入前台，自动重连...")
        let savedToken = UserDefaultsStorage.shared.loadToken()
        Task {
            await viewModel.initialize(url: savedUrl, token: savedToken)
        }
    }
}

#Preview {
    ContentView()
}
