// ContentView.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import SwiftUI
import os.log

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
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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

  /// 判断是否为 iPad
  var isIPad: Bool {
    DeviceUtils.isIPad
  }

  var body: some View {
    Group {
      if viewModel.gatewayConnected {
        // 根据设备类型选择布局
        if isIPad {
          // iPad - 多列布局
          DeckView(
            viewModel: viewModel,
            showingSettings: $showingSettings,
            showingNewSessionSheet: $showingNewSessionSheet
          )
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          // iPhone - 单列布局
          SessionListView(viewModel: viewModel)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

      } else if viewModel.isReconnecting {
        // Reconnecting state - show reconnecting view
        ReconnectingView(
          attempts: viewModel.reconnectAttempts,
          maxAttempts: 5,
          onCancel: {
            viewModel.disconnect()
          }
        )

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
            // 连接成功后关闭设置页面
            await MainActor.run {
              showingSettings = false
            }
          }
        },
        onResetDeviceIdentity: {
          viewModel.resetDeviceIdentity()
          Task {
            await viewModel.initialize(url: gatewayUrl, token: token)
            // 重置成功后关闭设置页面
            await MainActor.run {
              showingSettings = false
            }
          }
        },
        onClose: {
          showingSettings = false
        },
        viewModel: viewModel
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
            // 连接成功后关闭设置页面
            await MainActor.run {
              showingWelcomeSettings = false
            }
          }
        },
        onResetDeviceIdentity: {
          viewModel.resetDeviceIdentity()
          Task {
            await viewModel.initialize(url: gatewayUrl, token: token)
            // 重置成功后关闭设置页面
            await MainActor.run {
              showingWelcomeSettings = false
            }
          }
        },
        onClose: {
          showingWelcomeSettings = false
        },
        viewModel: viewModel
      )
    }
    .task {
      // Auto-connect on first launch if credentials exist
      guard !hasAttemptedAutoConnect && !viewModel.gatewayConnected else { return }
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
    .onChange(of: scenePhase) { oldPhase, newPhase in
      // 当应用从后台进入前台时，检查是否需要自动重连
      guard newPhase == .active else { return }

      // 如果已连接或正在连接，不需要重连
      guard !viewModel.gatewayConnected && !viewModel.isInitializing else { return }

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

      Text("Connecting to Gateway...")
        .font(.headline)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.adaptiveBackground)
  }
}

// MARK: - Reconnecting View

struct ReconnectingView: View {
  let attempts: Int
  let maxAttempts: Int
  let onCancel: () -> Void

  var body: some View {
    VStack(spacing: 20) {
      ProgressView()
        .scaleEffect(1.5)

      Text("Reconnecting...")
        .font(.headline)

      Text("Attempt \(attempts)/\(maxAttempts)")
        .font(.subheadline)
        .foregroundColor(.secondary)

      Button("Cancel", action: onCancel)
        .buttonStyle(.bordered)
        .padding(.top, 20)
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
      VStack(spacing: 24) {
        // Logo and title
        VStack(spacing: 12) {
          Image(systemName: "message.badge.filled.fill")
            .font(.system(size: 64))
            .foregroundColor(.blue)

          Text("OpenClaw Deck")
            .font(.largeTitle)
            .fontWeight(.bold)

          Text("Multi-Session Chat Client")
            .font(.title3)
            .foregroundColor(.secondary)
        }
        .padding(.top, 60)

        // Simple guide
        Text("Tap the ⚙️ in the top right\nto get started")
          .font(.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.top, 40)

        Spacer()

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
          .padding(.bottom, 24)
        }
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
