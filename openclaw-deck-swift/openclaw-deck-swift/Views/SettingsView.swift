// SettingsView.swift
// OpenClaw Deck Swift
//
// 设置页面 - 已连接时显示

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
        // Gateway Config Input (公用组件)
        Section {
          GatewayConfigInput(
            gatewayUrl: $gatewayUrl,
            token: $token,
            onConnect: onConnect,
            isConnected: isConnected
          )
        } header: {
          Text("Configuration")
        } footer: {
          Text("Modify and apply to reconnect with new settings")
        }

        // Status
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
          Text("Status")
        }

        // Actions - Apply & Reconnect
        if hasChanges {
          Section {
            Button {
              onApplyAndReconnect()
            } label: {
              HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                Text("Apply & Reconnect")
              }
            }
          } footer: {
            Text("Save changes and reconnect to Gateway with new settings")
          }
        }

        // Actions - Reset Device Identity
        Section {
          Button(role: .destructive) {
            showingResetAlert = true
          } label: {
            HStack {
              Image(systemName: "trash.fill")
              Text("Reset Device Identity")
            }
          }
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
        } footer: {
          Text("Clear stored device identity and token, then reconnect")
        }

        // Actions - Disconnect
        Section {
          Button(role: .destructive) {
            onDisconnect()
          } label: {
            HStack {
              Image(systemName: "xmark.square.fill")
              Text("Disconnect")
            }
          }
        } footer: {
          Text("Disconnect from Gateway and return to welcome screen")
        }

        // Notifications
        if viewModel != nil {
          Section {
            Toggle(
              "Play Sound on Message",
              isOn: .init(
                get: { viewModel?.playSoundOnMessage ?? true },
                set: { viewModel?.playSoundOnMessage = $0 }
              ))
          } header: {
            Text("Notifications")
          } footer: {
            Text("Play a sound when a message is received")
          }
        }

        // Cloudflare KV Sync
        Section {
          NavigationLink {
            CloudflareSettingsView(onClose: onClose, viewModel: viewModel)
          } label: {
            HStack {
              Image(systemName: "icloud.and.arrow.down")
              Text("Cloudflare KV Sync")

              Spacer()

              if CloudflareKV.shared.isConfigured {
                Image(systemName: "checkmark.circle.fill")
                  .foregroundColor(.green)
              }
            }
          }
        } header: {
          Text("Multi-Device Sync")
        } footer: {
          Text("Sync sessions to multiple devices using Cloudflare KV (free tier)")
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
    onApplyAndReconnect: {}, onConnect: {}
  )
}
