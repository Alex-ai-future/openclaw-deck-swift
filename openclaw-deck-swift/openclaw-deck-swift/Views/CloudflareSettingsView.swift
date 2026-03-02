// CloudflareSettingsView.swift
// OpenClaw Deck Swift
//
// Cloudflare KV Configuration View

import os.log
import SwiftUI

private let logger = Logger(subsystem: "com.openclaw.deck", category: "CloudflareSettingsView")

struct CloudflareSettingsView: View {
    @State private var accountId: String = ""
    @State private var namespaceId: String = ""
    @State private var userId: String = ""
    @State private var apiToken: String = ""

    @State private var isConfigured: Bool = false
    @State private var showingTestAlert = false
    @State private var testResult: String?
    @State private var isTesting = false
    @State private var saveStatus: String = ""

    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case userId
        case accountId
        case namespaceId
        case apiToken
    }

    var onClose: (() -> Void)?
    var viewModel: DeckViewModel?

    var body: some View {
        NavigationStack {
            Form {
                // Description
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("cloudflare_kv_sync".localized)
                            .font(.headline)

                        Text("sync_sessions_across_multiple_devices_using_cloudflare_kv".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Link(
                            "Setup Guide", destination: URL(string: "https://dash.cloudflare.com")!
                        )
                        .font(.caption)
                    }
                    .padding(.vertical, 4)
                } footer: {
                    Text("free_tier_100k_readsday_1k_writesday_1gb_storage".localized)
                }

                // Configuration Input
                Section {
                    TextField("user_id_custom_eg_email".localized, text: $userId)
                        .focused($focusedField, equals: .userId)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                        }
                        .onChange(of: userId) { _, _ in
                            autoSave()
                        }

                    TextField("account_id".localized, text: $accountId)
                        .focused($focusedField, equals: .accountId)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                        }
                        .onChange(of: accountId) { _, _ in
                            autoSave()
                        }

                    TextField("namespace_id".localized, text: $namespaceId)
                        .focused($focusedField, equals: .namespaceId)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                        }
                        .onChange(of: namespaceId) { _, _ in
                            autoSave()
                        }

                    TextField("api_token".localized, text: $apiToken)
                        .focused($focusedField, equals: .apiToken)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                        }
                        .onChange(of: apiToken) { _, _ in
                            autoSave()
                        }
                } header: {
                    Text("configuration".localized)
                } footer: {
                    Text("api_token_is_encrypted_in_keychain".localized)
                }

                // Status
                Section {
                    HStack {
                        Circle()
                            .fill(isConfigured ? Color.green : Color.orange)
                            .frame(width: 10, height: 10)

                        Text(isConfigured ? "Configured" : "Not Configured")
                            .foregroundColor(.primary)
                            .fontWeight(.medium)

                        Spacer()

                        if !saveStatus.isEmpty {
                            Text(saveStatus)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                } header: {
                    Text("status".localized)
                }

                // Actions
                Section {
                    Button {
                        Task {
                            await testConnection()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                            Text("test_connection".localized)
                        }
                    }
                    .disabled(isTesting || !isFormValid)

                    if isConfigured {
                        Button(role: .destructive) {
                            clearConfig()
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("clear_configuration".localized)
                            }
                        }
                    }
                } header: {
                    Text("actions".localized)
                } footer: {
                    if isTesting {
                        Text("testing".localized)
                            .foregroundColor(.secondary)
                    } else if let result = testResult {
                        Text(result)
                            .foregroundColor(result.contains("Success") || result.contains("✓") ? .green : .red)
                    }
                }
            }
            .navigationTitle("cloudflare_sync".localized)
            .toolbar {
                // No cancel button - navigation back is sufficient
            }
            .onAppear {
                loadConfig()
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Private Methods

    private var isFormValid: Bool {
        !accountId.trimmingCharacters(in: .whitespaces).isEmpty
            && !namespaceId.trimmingCharacters(in: .whitespaces).isEmpty
            && !userId.trimmingCharacters(in: .whitespaces).isEmpty
            && !apiToken.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func loadConfig() {
        if let config = CloudflareConfig.load() {
            accountId = config.accountId
            namespaceId = config.namespaceId
            userId = config.userId
            apiToken = config.apiToken
        } else {
            accountId = ""
            namespaceId = ""
            userId = ""
            apiToken = ""
        }

        isConfigured = CloudflareKV.shared.isConfigured
    }

    private func autoSave() {
        guard isFormValid else {
            saveStatus = ""
            return
        }
        do {
            try CloudflareKV.shared.saveConfig(
                accountId: accountId,
                namespaceId: namespaceId,
                userId: userId,
                apiToken: apiToken
            )
            isConfigured = true
            saveStatus = "Saved"
            testResult = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                saveStatus = ""
            }
        } catch {
            saveStatus = "Save failed"
        }
    }

    private func clearConfig() {
        CloudflareKV.shared.clearConfig()
        accountId = ""
        namespaceId = ""
        userId = ""
        apiToken = ""
        isConfigured = false
        testResult = "Configuration cleared"
        saveStatus = ""
    }

    private func testConnection() async {
        guard isFormValid else {
            testResult = "Please fill in all fields"
            return
        }

        isTesting = true
        testResult = nil

        // Save configuration first
        do {
            try CloudflareKV.shared.saveConfig(
                accountId: accountId,
                namespaceId: namespaceId,
                userId: userId,
                apiToken: apiToken
            )
        } catch {
            testResult = "Failed to save: \(error.localizedDescription)"
            isTesting = false
            return
        }

        // Test connection
        do {
            _ = try await CloudflareKV.shared.syncAndGet()
            testResult = "✓ Connection successful"
        } catch {
            testResult = "✗ Connection failed: \(error.localizedDescription)"
        }

        isTesting = false
    }
}

#Preview {
    CloudflareSettingsView()
}
