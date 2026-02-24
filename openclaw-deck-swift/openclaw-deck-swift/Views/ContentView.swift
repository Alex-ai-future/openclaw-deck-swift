// ContentView.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import SwiftUI

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
            } else {
                // Welcome screen - show settings
                WelcomeView(
                    gatewayUrl: $gatewayUrl,
                    token: $token,
                    onConnect: {
                        Task {
                            await viewModel.initialize(url: gatewayUrl, token: token)
                        }
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
    let onConnect: () -> Void
    
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
                        Image(systemName: "plug")
                        Text("Connect to Gateway")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
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
        .background(Color(.systemBackground))
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
              color.count >= 3 else {
            return nil
        }
        
        let r = Int(color[0] * 255)
        let g = Int(color[1] * 255)
        let b = Int(color[2] * 255)
        
        return String(format: "#%02X%02X%02X", r, g, b)
        #else
        guard let components = UIColor(self).cgColor.components,
              components.count >= 3 else {
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
