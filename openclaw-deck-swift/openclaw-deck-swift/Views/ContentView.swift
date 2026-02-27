// ContentView.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import SwiftUI

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

  init() {
    // 从 UserDefaults 加载保存的配置
    let storage = UserDefaultsStorage.shared
    if let savedUrl = storage.loadGatewayUrl() {
      _gatewayUrl = State(initialValue: savedUrl)
    }
    if let savedToken = storage.loadToken() {
      _token = State(initialValue: savedToken)
    }
  }

  var body: some View {
    Group {
      if viewModel.gatewayConnected {
        // Main deck view
        DeckView(
          viewModel: viewModel,
          showingSettings: $showingSettings,
          showingNewSessionSheet: $showingNewSessionSheet
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)

      } else if viewModel.isInitializing {
        // Connecting state - show loading
        ConnectingView()

        // Spacer to push content to top when empty
        Spacer()
      } else {
        // Welcome screen - show settings
        WelcomeView(
          gatewayUrl: $gatewayUrl,
          token: $token,
          connectionError: viewModel.connectionError,
          isConnecting: viewModel.isInitializing,
          onConnect: {
            Task {
              await viewModel.initialize(url: gatewayUrl, token: token)
            }
          },
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
        gatewayUrl: $gatewayUrl,
        token: $token,
        isConnected: .init(
          get: { viewModel.gatewayConnected },
          set: { _ in }
        ),
        onDisconnect: {
          viewModel.disconnect()
          showingSettings = false
        },
        onApplyAndReconnect: {
          Task {
            await viewModel.initialize(url: gatewayUrl, token: token)
          }
          showingSettings = false
        },
        onConnect: {
          Task {
            await viewModel.initialize(url: gatewayUrl, token: token)
          }
        },
        onResetDeviceIdentity: {
          viewModel.resetDeviceIdentity()
          Task {
            await viewModel.initialize(url: gatewayUrl, token: token)
          }
        },
        onClose: {
          showingSettings = false
        }
      )
    }
    .sheet(isPresented: $showingWelcomeSettings) {
      SettingsView(
        gatewayUrl: $gatewayUrl,
        token: $token,
        isConnected: .constant(false),
        onDisconnect: {
          viewModel.disconnect()
          showingWelcomeSettings = false
        },
        onApplyAndReconnect: {
          Task {
            await viewModel.initialize(url: gatewayUrl, token: token)
          }
          showingWelcomeSettings = false
        },
        onConnect: {
          Task {
            await viewModel.initialize(url: gatewayUrl, token: token)
          }
        },
        onResetDeviceIdentity: {
          viewModel.resetDeviceIdentity()
          Task {
            await viewModel.initialize(url: gatewayUrl, token: token)
          }
        },
        onClose: {
          showingWelcomeSettings = false
        }
      )
    }
    .task {
      // Auto-connect on first launch if credentials exist
      guard !hasAttemptedAutoConnect && !viewModel.gatewayConnected else { return }
      hasAttemptedAutoConnect = true

      print("[ContentView] Attempting auto-connect...")
      if let savedUrl = UserDefaultsStorage.shared.loadGatewayUrl() {
        let savedToken = UserDefaultsStorage.shared.loadToken()
        print("[ContentView] Found saved credentials: \(savedUrl)")
        await viewModel.initialize(url: savedUrl, token: savedToken)
      } else {
        print("[ContentView] No saved credentials found")
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

      Text("Connecting to Gateway...")
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
  let onConnect: () -> Void
  let onClearError: () -> Void
  let onShowSettings: () -> Void

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 40) {
          // Logo and title
          VStack(spacing: 16) {
            Image(systemName: "message.badge.filled.fill")
              .font(.system(size: 80))
              .foregroundColor(.blue)
            
            Text("OpenClaw Deck")
              .font(.largeTitle)
              .fontWeight(.bold)
            
            Text("Multi-Session Chat Client")
              .font(.title2)
              .foregroundColor(.secondary)
          }
          .frame(maxWidth: .infinity)
          
          // Settings hint
          VStack(spacing: 12) {
            Image(systemName: "gearshape")
              .font(.system(size: 40))
              .foregroundColor(.secondary)
            
            Text("Tap Settings to Configure")
              .font(.body)
              .foregroundColor(.secondary)
          }
          .frame(maxWidth: .infinity)
          
          // Error message
          if let error = connectionError {
            VStack(spacing: 8) {
              HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                  .foregroundColor(.red)
                Text("Connection Failed")
                  .fontWeight(.semibold)
                  .foregroundColor(.red)
                Spacer()
                Button("Dismiss", action: onClearError)
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
          }
          
          Spacer()
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        #if os(macOS)
          .frame(minHeight: NSScreen.main?.frame.height ?? 800)
        #else
          .frame(minHeight: 800)
        #endif
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.adaptiveBackground)
      .navigationTitle("")
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button {
              onShowSettings()
            } label: {
              Image(systemName: "gear")
                .font(.title2)
            }
          }
        }
      #else
        .toolbar {
          ToolbarItem {
            Button {
              onShowSettings()
            } label: {
              Image(systemName: "gear")
                .font(.title2)
            }
          }
        }
      #endif
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
