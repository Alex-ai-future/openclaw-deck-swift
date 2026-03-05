// SettingsView.swift
// OpenClaw Deck Swift
//
// Settings view - organized by functional groups

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var gatewayUrl: String
    @State private var token: String
    @Binding var isConnected: Bool

    /// ViewModel binding for settings
    var viewModel: DeckViewModel?

    private let languageManager = LanguageManager.shared

    @State private var hasChanges = false
    @State private var originalUrl = ""
    @State private var originalToken = ""
    @State private var showingResetAlert = false

    init(
        isConnected: Binding<Bool>,
        viewModel: DeckViewModel? = nil
    ) {
        // 从 UserDefaults 加载初始值
        let storage = UserDefaultsStorage.shared
        _gatewayUrl = State(initialValue: storage.loadGatewayUrl() ?? "ws://127.0.0.1:18789")
        _token = State(initialValue: storage.loadToken() ?? "")
        _isConnected = isConnected
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 1. CONNECTION STATUS (Read-only)

                Section {
                    HStack {
                        Circle()
                            .fill(isConnected ? Color.green : Color.orange)
                            .frame(width: 10, height: 10)

                        Text(isConnected ? "Connected" : "Not Connected")
                            .foregroundColor(.primary)
                            .fontWeight(.medium)

                        Spacer()
                    }
                } header: {
                    Label("connection".localized, systemImage: "network")
                } footer: {
                    if isConnected {
                        Text(String(format: "gateway_url_format".localized, gatewayUrl))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // MARK: - 2. GATEWAY CONFIG (Editable)

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
                                    .fontWeight(.medium)
                            }
                        }

                        Text("web_client_description".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Label("gateway".localized, systemImage: "server.rack")
                } footer: {
                    Text("modify_and_apply_to_reconnect_with_new_settings".localized)
                }

                // MARK: - 3. APP SETTINGS

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

                // MARK: - 6. HELP

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
                ToolbarItem(placement: .primaryAction) {
                    if isConnected {
                        Button("done".localized) {
                            dismiss()
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
        isConnected: .constant(true),
        viewModel: nil
    )
}
