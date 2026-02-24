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

  var body: some View {
    Group {
      if viewModel.gatewayConnected || viewModel.isInitializing {
        // Main deck view
        DeckView(
          viewModel: viewModel,
          showingSettings: $showingSettings,
          showingNewSessionSheet: $showingNewSessionSheet
        )

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
        onConnect: {
          Task {
            await viewModel.initialize(url: gatewayUrl, token: token)
          }
        },
        onDisconnect: {
          viewModel.disconnect()
        }
      )
    }
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

  @FocusState private var isUrlFocused: Bool

  var body: some View {
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

      // Connection form
      VStack(spacing: 16) {
        TextField("Gateway URL", text: $gatewayUrl)
          .textFieldStyle(.roundedBorder)
          .focused($isUrlFocused)
          .onSubmit {
            onConnect()
          }

        SecureField("Token (optional)", text: $token)
          .textFieldStyle(.roundedBorder)
          .onSubmit {
            onConnect()
          }

        Button(action: onConnect) {
          HStack {
            if isConnecting {
              ProgressView()
                .scaleEffect(0.8)
            } else {
              Image(systemName: "plug")
            }
            Text(isConnecting ? "Connecting..." : "Connect to Gateway")
          }
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isConnecting)

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
        }
      }
      .padding()

      // Footer
      VStack(spacing: 8) {
        Text("Default Gateway URL:")
          .font(.caption)
          .foregroundColor(.secondary)

        Text(gatewayUrl)
          .font(.caption)
          .foregroundColor(.blue)
      }

      Spacer()
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.adaptiveBackground)
    #if os(macOS)
      .onAppear {
        isUrlFocused = true
      }
    #endif
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
