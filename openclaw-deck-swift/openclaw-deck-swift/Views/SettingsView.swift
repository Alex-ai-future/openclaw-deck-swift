// SettingsView.swift
// OpenClaw Deck Swift
//
// Settings view - organized by functional groups

import SwiftUI

struct SettingsView: View {
  @Binding var gatewayUrl: String
  @Binding var token: String
  @Binding var isConnected: Bool
  var onDisconnect: () -> Void
  var onApplyAndReconnect: () -> Void
  var onConnect: () -> Void
  var onResetDeviceIdentity: (() -> Void)?
  var onClose: (() -> Void)?

  // ViewModel binding for settings
  var viewModel: DeckViewModel?

  @State private var hasChanges = false
  @State private var originalUrl = ""
  @State private var originalToken = ""
  @State private var showingResetAlert = false

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
          Label("CONNECTION", systemImage: "network")
        } footer: {
          if isConnected {
            Text("Gateway: \(gatewayUrl)")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }

        // MARK: - 2. GATEWAY CONFIG (Editable)

        Section {
          GatewayConfigInput(
            gatewayUrl: $gatewayUrl,
            token: $token,
            onConnect: onConnect,
            isConnected: isConnected
          )
        } header: {
          Label("GATEWAY", systemImage: "server.rack")
        } footer: {
          Text("Modify and apply to reconnect with new settings")
        }

        // Apply & Reconnect button (only when changes exist)
        if hasChanges {
          Section {
            Button {
              onApplyAndReconnect()
            } label: {
              HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                Text("Apply & Reconnect")
                  .fontWeight(.medium)
              }
            }
          } footer: {
            Text("Save changes and reconnect to Gateway")
          }
        }

        // MARK: - 3. APP SETTINGS

        Section {
          // Notifications
          Toggle(
            "Sound on Message", systemImage: "speaker.wave.2",
            isOn: .init(
              get: { viewModel?.playSoundOnMessage ?? true },
              set: { viewModel?.playSoundOnMessage = $0 }
            ))

          // Cloudflare KV Sync
          NavigationLink {
            CloudflareSettingsView(onClose: onClose, viewModel: viewModel)
          } label: {
            Label("Multi-Device Sync", systemImage: "icloud.and.arrow.down")

            Spacer()

            if CloudflareKV.shared.isConfigured {
              Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            }
          }
        } header: {
          Label("APP", systemImage: "app.badge")
        } footer: {
          Text("Notifications and cloud sync settings")
        }

        // MARK: - 4. DEVICE MANAGEMENT

        Section {
          Button {
            showingResetAlert = true
          } label: {
            HStack {
              Image(systemName: "trash.fill")
              Text("Reset Device Identity")
                .fontWeight(.medium)
            }
          }
          .tint(.orange)
          .alert("Reset Device Identity?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
              onResetDeviceIdentity?()
            }
          } message: {
            Text(
              "This will clear the stored device identity and token, then reconnect using the token you entered."
            )
          }
        } header: {
          Label("DEVICE", systemImage: "iphone")
        } footer: {
          Text("Clear stored device identity and token")
        }

        // MARK: - 5. DISCONNECT (Separate section for safety)

        Section {
          Button {
            onDisconnect()
          } label: {
            HStack {
              Image(systemName: "xmark.square.fill")
              Text("Disconnect")
                .fontWeight(.medium)
            }
          }
          .tint(.red)
        } header: {
          Label("DISCONNECT", systemImage: "slash.circle")
        } footer: {
          Text("Disconnect from Gateway and return to welcome screen")
        }

        // MARK: - 6. HELP

        Section {
          NavigationLink {
            UserGuideView()
          } label: {
            Label("User Guide", systemImage: "book")
          }
        } header: {
          Label("HELP", systemImage: "questionmark.circle")
        } footer: {
          Text("View complete usage instructions and troubleshooting guide")
        }

        // MARK: - 7. ABOUT

        Section {
          HStack {
            Text("Version")
            Spacer()
            Text("1.0.0")
              .foregroundColor(.secondary)
          }
          .font(.caption)

          Link("OpenClaw Documentation", destination: URL(string: "https://docs.openclaw.ai")!)
            .font(.caption)
        } header: {
          Label("ABOUT", systemImage: "info.circle")
        }
      }
      .navigationTitle("Settings")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            onClose?()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Done") {
            onClose?()
          }
          .fontWeight(.semibold)
          .keyboardShortcut(.defaultAction)
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
}

#Preview {
  SettingsView(
    gatewayUrl: .constant("ws://127.0.0.1:18789"),
    token: .constant(""),
    isConnected: .constant(true),
    onDisconnect: {},
    onApplyAndReconnect: {},
    onConnect: {}
  )
}
