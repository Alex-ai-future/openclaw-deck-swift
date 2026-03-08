// SettingsView.swift
// OpenClaw Deck Swift
//
// Settings view - organized by functional groups

import OSLog
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var gatewayUrl: String
    @State private var token: String
    var isConnected: Bool

    /// ViewModel binding for settings
    var viewModel: DeckViewModel?

    /// Gateway 发现服务
    @StateObject private var discovery = GatewayDiscoveryService.shared

    /// 语言管理器
    @ObservedObject private var languageManager = LanguageManager.shared

    private let logger = Logger(subsystem: "com.openclaw.deck", category: "SettingsView")

    @State private var hasChanges = false
    @State private var originalUrl = ""
    @State private var originalToken = ""
    @State private var showingResetAlert = false

    init(
        isConnected: Bool,
        viewModel: DeckViewModel? = nil
    ) {
        // 从 UserDefaults 加载初始值
        let storage = UserDefaultsStorage.shared
        _gatewayUrl = State(initialValue: storage.loadGatewayUrl() ?? "ws://127.0.0.1:18789")
        _token = State(initialValue: storage.loadToken() ?? "")
        self.isConnected = isConnected
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 1. GATEWAY CONFIG (Editable)

                Section {
                    GatewayConfigInput(
                        gatewayUrl: $gatewayUrl,
                        token: $token,
                        isConnected: isConnected
                    )

                    // Open Web Client
                    if let webUrl = webClientUrl {
                        Link(
                            destination: webUrl
                        ) {
                            HStack {
                                Image(systemName: "globe")
                                Text("open_web_client".localized)
                            }
                        }
                    }
                } header: {
                    Label("gateway".localized, systemImage: "server.rack")
                } footer: {
                    Text("web_client_description".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // MARK: - 2. APP SETTINGS

                Section {
                    // Language Selector
                    Picker(
                        "language".localized,
                        selection: Binding(
                            get: { languageManager.selectedLanguage },
                            set: { languageManager.setLanguage($0) }
                        )
                    ) {
                        ForEach(LanguageManager.Language.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }

                    // Notifications
                    Toggle(
                        "sound_on_message".localized, systemImage: "speaker.wave.2",
                        isOn: .init(
                            get: { viewModel?.playSoundOnMessage ?? true },
                            set: { viewModel?.playSoundOnMessage = $0 }
                        )
                    )

                    // Cloudflare KV Sync
                    NavigationLink {
                        CloudflareSettingsView(viewModel: viewModel)
                    } label: {
                        HStack {
                            Label(
                                "multi_device_sync".localized, systemImage: "icloud.and.arrow.down"
                            )
                            Spacer()
                            if CloudflareKV.shared.isConfigured {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                } header: {
                    Label("app".localized, systemImage: "app.badge")
                } footer: {
                    Text("notifications_and_cloud_sync_settings".localized)
                }

                // MARK: - 3. LAN GATEWAY DISCOVERY

                Section {
                    // 发现结果列表
                    if !discovery.gateways.isEmpty {
                        ForEach(discovery.gateways) { gateway in
                            Button {
                                // 点击使用此 Gateway（使用主机名，更稳定）
                                gatewayUrl = gateway.wsURL
                                logger.info("✅ 已选择 Gateway: \(gateway.name) @ \(gateway.displayAddress)")
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(gateway.name)
                                        .font(.headline)

                                    HStack {
                                        Image(systemName: "network")
                                        Text(gateway.displayAddress)
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                    // IP 地址仅用于调试/诊断
                                    if let ip = gateway.ipAddress {
                                        HStack {
                                            Image(systemName: "info.circle")
                                            Text("IP: \(ip) (自动跟踪)")
                                        }
                                        .font(.caption2)
                                        .foregroundColor(.secondary.opacity(0.7))
                                    }
                                }
                            }
                        }
                    }

                    // 扫描状态提示
                    if discovery.isScanning {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(360))
                                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: discovery.isScanning)
                            Text("Scanning...")
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                    }
                } header: {
                    Label("LAN Gateway Discovery", systemImage: "wifi.router")
                } footer: {
                    Text("Automatically scans when settings is open")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // MARK: - 4. DEVICE MANAGEMENT

                Section {
                    Button {
                        showingResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("reset_device_identity".localized)
                                .fontWeight(.medium)
                        }
                    }
                    .tint(.orange)
                    .alert("reset_device_identity_alert".localized, isPresented: $showingResetAlert) {
                        Button("cancel".localized, role: .cancel) {}
                        Button("reset".localized, role: .destructive) {
                            viewModel?.resetDeviceIdentity()
                            dismiss()
                        }
                    } message: {
                        Text(
                            "this_will_clear_the_stored_device_identity_and_token_then_reconnect_using_the_token_you_entered"
                                .localized
                        )
                    }
                } header: {
                    Label("device".localized, systemImage: "iphone")
                } footer: {
                    Text("clear_stored_device_identity_and_token".localized)
                }

                // MARK: - 5. DISCONNECT (Separate section for safety)

                Section {
                    Button {
                        viewModel?.disconnect()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.square.fill")
                            Text("disconnect".localized)
                                .fontWeight(.medium)
                        }
                    }
                    .tint(.red)
                } header: {
                    Label("disconnect".localized, systemImage: "slash.circle")
                } footer: {
                    Text("disconnect_from_gateway_and_return_to_welcome_screen".localized)
                }

                // MARK: - 7. HELP

                Section {
                    Link(
                        destination: URL(
                            string:
                            "https://alex-ai-future.github.io/openclaw-deck-swift/USER_GUIDE.html"
                        )!
                    ) {
                        Label("user_guide".localized, systemImage: "book.fill")
                    }

                    Link(
                        destination: URL(
                            string:
                            "https://alex-ai-future.github.io/openclaw-deck-swift/USAGE_EXAMPLES.html"
                        )!
                    ) {
                        Label("usage_examples".localized, systemImage: "list.bullet.rectangle")
                    }

                    Link(
                        destination: URL(
                            string:
                            "https://alex-ai-future.github.io/openclaw-deck-swift/PRIVACY.html"
                        )!
                    ) {
                        Label("privacy_policy".localized, systemImage: "shield.fill")
                    }
                } header: {
                    Label("help".localized, systemImage: "questionmark.circle")
                } footer: {
                    Text("view_complete_usage_instructions_and_troubleshooting_guide".localized)
                }

                // MARK: - 7. ABOUT

                Section {
                    HStack {
                        Text("version".localized)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)

                    Link(
                        "OpenClaw Documentation",
                        destination: URL(string: "https://docs.openclaw.ai")!
                    )
                    .font(.caption)
                } header: {
                    Label("about".localized, systemImage: "info.circle")
                }
            }
            .navigationTitle("settings".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }

                ToolbarItem(placement: .primaryAction) {
                    if isConnected {
                        if hasChanges {
                            // 已连接 + 有修改：显示"连接"，保存并重新连接
                            Button("connect".localized) {
                                UserDefaultsStorage.shared.saveGatewayUrl(gatewayUrl)
                                UserDefaultsStorage.shared.saveToken(token)
                                Task {
                                    await viewModel?.initialize(url: gatewayUrl, token: token)
                                    // 延迟关闭，让用户看到加载动画
                                    try? await Task.sleep(nanoseconds: 500_000_000)
                                    dismiss()
                                }
                            }
                            .fontWeight(.semibold)
                        } else {
                            // 已连接 + 无修改：显示"完成"，只关闭
                            Button("done".localized) {
                                dismiss()
                            }
                            .fontWeight(.semibold)
                        }
                    } else {
                        // 未连接：始终显示"连接"按钮
                        Button("connect".localized) {
                            UserDefaultsStorage.shared.saveGatewayUrl(gatewayUrl)
                            UserDefaultsStorage.shared.saveToken(token)
                            Task {
                                await viewModel?.initialize(url: gatewayUrl, token: token)
                                // 延迟关闭，让用户看到加载动画
                                try? await Task.sleep(nanoseconds: 500_000_000)
                                dismiss()
                            }
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            originalUrl = gatewayUrl
            originalToken = token
            hasChanges = false
            // 打开设置页面时自动开始扫描
            discovery.start()
        }
        .onDisappear {
            // 关闭设置页面时自动停止扫描
            discovery.stop()
        }
        .onChange(of: gatewayUrl) { _, _ in
            checkChanges()
        }
        .onChange(of: token) { _, _ in
            checkChanges()
        }
    }

    private func checkChanges() {
        hasChanges = (gatewayUrl != originalUrl || token != originalToken)
    }

    // MARK: - Computed Properties

    /// Web Client URL (converted from WebSocket URL)
    private var webClientUrl: URL? {
        let httpUrl = gatewayUrl
            .replacingOccurrences(of: "ws://", with: "http://")
            .replacingOccurrences(of: "wss://", with: "https://")
        return URL(string: httpUrl)
    }
}

#Preview {
    SettingsView(
        isConnected: true,
        viewModel: nil
    )
}
