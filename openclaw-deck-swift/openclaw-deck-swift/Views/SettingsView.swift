// SettingsView.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/24/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import SwiftUI

/// 设置页面 - Gateway 配置
struct SettingsView: View {
    @Binding var gatewayUrl: String
    @Binding var token: String
    @Binding var isConnected: Bool
    var onConnect: () -> Void
    var onDisconnect: () -> Void
    
    @State private var showingToken = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Gateway URL", text: $gatewayUrl)
                        .textContentType(.URL)

                    if showingToken {
                        TextField("Token (optional)", text: $token)
                            .textContentType(.password)
                    } else {
                        SecureField("Token (optional)", text: $token)
                            .textContentType(.password)
                    }

                    HStack {
                        Button(showingToken ? "Hide" : "Show") {
                            showingToken.toggle()
                        }
                        .buttonStyle(.plain)
                        .font(.caption)

                        Spacer()
                    }
                } header: {
                    Text("Gateway Configuration")
                } footer: {
                    Text("Enter your OpenClaw Gateway WebSocket URL and optional authentication token.")
                }
                
                Section {
                    HStack {
                        Circle()
                            .fill(isConnected ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                        
                        Text(isConnected ? "Connected" : "Disconnected")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if isConnected {
                            Button("Disconnect") {
                                onDisconnect()
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        } else {
                            Button("Connect") {
                                onConnect()
                            }
                            .buttonStyle(.bordered)
                            .tint(.green)
                        }
                    }
                } header: {
                    Text("Connection Status")
                } footer: {
                    Text(isConnected 
                         ? "Successfully connected to Gateway. You can now send messages."
                         : "Tap Connect to establish a WebSocket connection to the Gateway.")
                }
                
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Main Agent ID: main")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "ipad")
                            .foregroundColor(.blue)
                        Text("Platform: iPadOS / macOS")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("OpenClaw Deck Swift - A multi-session chat client for OpenClaw Gateway.")
                }
            }
            .navigationTitle("Settings")
        }
        .formStyle(.grouped)
    }
}

#Preview {
    SettingsView(
        gatewayUrl: .constant("ws://127.0.0.1:18789"),
        token: .constant(""),
        isConnected: .constant(false),
        onConnect: {},
        onDisconnect: {}
    )
}
