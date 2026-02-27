// CloudflareSettingsView.swift
// OpenClaw Deck Swift
//
// Cloudflare KV Configuration View

import SwiftUI

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

  var body: some View {
    NavigationStack {
      Form {
        // Description
        Section {
          VStack(alignment: .leading, spacing: 8) {
            Text("Cloudflare KV Sync")
              .font(.headline)

            Text("Use Cloudflare KV for multi-device session synchronization")
              .font(.subheadline)
              .foregroundColor(.secondary)

            Link("View Configuration Guide", destination: URL(string: "https://dash.cloudflare.com")!)
              .font(.caption)
          }
          .padding(.vertical, 4)
        } footer: {
          Text("Free tier: 100K reads/day, 1K writes/day, 1GB storage")
        }

        // Configuration Input
        Section {
          TextField("User ID (custom, e.g., email)", text: $userId)
            .focused($focusedField, equals: .userId)
            .submitLabel(.done)
            .onSubmit {
              focusedField = nil
            }
            .onChange(of: userId) { _, _ in
              autoSave()
            }

          TextField("Account ID", text: $accountId)
            .focused($focusedField, equals: .accountId)
            .submitLabel(.done)
            .onSubmit {
              focusedField = nil
            }
            .onChange(of: accountId) { _, _ in
              autoSave()
            }

          TextField("Namespace ID", text: $namespaceId)
            .focused($focusedField, equals: .namespaceId)
            .submitLabel(.done)
            .onSubmit {
              focusedField = nil
            }
            .onChange(of: namespaceId) { _, _ in
              autoSave()
            }

          TextField("API Token", text: $apiToken)
            .focused($focusedField, equals: .apiToken)
            .submitLabel(.done)
            .onSubmit {
              focusedField = nil
            }
            .onChange(of: apiToken) { _, _ in
              autoSave()
            }
        } header: {
          Text("Cloudflare Configuration")
        } footer: {
          Text("API Token is encrypted and stored in Keychain")
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
          Text("Status")
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
              Text("Test Connection")
            }
          }
          .disabled(isTesting || !isFormValid)

          if isConfigured {
            Button(role: .destructive) {
              clearConfig()
            } label: {
              HStack {
                Image(systemName: "trash.fill")
                Text("Clear Configuration")
              }
            }
          }
        } header: {
          Text("Actions")
        } footer: {
          if isTesting {
            Text("Testing connection...")
              .foregroundColor(.secondary)
          } else if let result = testResult {
            Text(result)
              .foregroundColor(result.contains("Success") || result.contains("✓") ? .green : .red)
          }
        }
      }
      .navigationTitle("Cloudflare Sync")
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
    accountId =
      UserDefaults.standard.string(
        forKey: "openclaw.deck.cloudflare.accountId") ?? ""
    namespaceId =
      UserDefaults.standard.string(
        forKey: "openclaw.deck.cloudflare.namespaceId") ?? ""
    userId = UserDefaults.standard.string(forKey: "openclaw.deck.cloudflare.userId") ?? ""
    apiToken = KeychainWrapper.shared.string(forKey: "openclaw.deck.cloudflare.apiToken") ?? ""

    isConfigured = CloudflareKV.shared.isConfigured
  }

  private func autoSave() {
    guard isFormValid else {
      saveStatus = ""
      return
    }
    do {
      try CloudflareKV.shared.saveConfig(
        accountId: accountId.trimmingCharacters(in: .whitespaces),
        namespaceId: namespaceId.trimmingCharacters(in: .whitespaces),
        userId: userId.trimmingCharacters(in: .whitespaces),
        apiToken: apiToken.trimmingCharacters(in: .whitespaces))
      isConfigured = true
      saveStatus = "Saved"
      testResult = nil
      // Clear status after 2 seconds
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

    print("[CloudflareSettings] Starting connection test...")
    print("[CloudflareSettings] Account ID: \(accountId.prefix(10))...")
    print("[CloudflareSettings] Namespace ID: \(namespaceId.prefix(10))...")
    print("[CloudflareSettings] User ID: \(userId)")

    // Save configuration first
    do {
      try CloudflareKV.shared.saveConfig(
        accountId: accountId.trimmingCharacters(in: .whitespaces),
        namespaceId: namespaceId.trimmingCharacters(in: .whitespaces),
        userId: userId.trimmingCharacters(in: .whitespaces),
        apiToken: apiToken.trimmingCharacters(in: .whitespaces))
      print("[CloudflareSettings] Configuration saved")
    } catch {
      print("[CloudflareSettings] Failed to save configuration: \(error)")
      testResult = "Failed to save: \(error.localizedDescription)"
      isTesting = false
      return
    }

    // Test connection
    do {
      print("[CloudflareSettings] Starting sync...")
      _ = try await CloudflareKV.shared.syncAndGet()
      print("[CloudflareSettings] Sync successful")
      testResult = "✓ Connection successful"
    } catch {
      print("[CloudflareSettings] Sync failed: \(error)")
      testResult = "✗ Connection failed: \(error.localizedDescription)"
    }

    isTesting = false
  }
}

#Preview {
  CloudflareSettingsView()
}
