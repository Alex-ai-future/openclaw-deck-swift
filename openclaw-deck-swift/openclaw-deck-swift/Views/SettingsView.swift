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
  var onResetDeviceIdentity: (() -> Void)?

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
            onConnect: {},
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
              .fill(Color.green)
              .frame(width: 10, height: 10)

            Text("Connected")
              .foregroundColor(.primary)
              .fontWeight(.medium)

            Spacer()
          }
        } header: {
          Text("Status")
        }

        // Actions
        Section {
          if hasChanges {
            Button {
              onApplyAndReconnect()
            } label: {
              HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                Text("Apply & Reconnect")
              }
            }
          }

          // Reset Device Identity
          Button(role: .destructive) {
            showingResetAlert = true
          } label: {
            HStack {
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

          Button(role: .destructive) {
            onDisconnect()
          } label: {
            HStack {
              Image(systemName: "plug.disconnected")
              Text("Disconnect")
            }
          }
        } footer: {
          if hasChanges {
            Text("Apply changes and reconnect")
          } else {
            Text("Disconnect to return to login")
          }
        }
      }
      .navigationTitle("Settings")
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
    onApplyAndReconnect: {}
  )
}
