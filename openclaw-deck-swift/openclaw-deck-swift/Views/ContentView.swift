// ContentView.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var viewModel = DeckViewModel()
    @State private var showingSettings = false
    @State private var gatewayUrl = "ws://127.0.0.1:18789"
    @State private var token = ""
    @State private var showingNewSessionSheet = false
    
    // New Session form state
    @State private var newSessionName = ""
    @State private var newSessionIcon = ""
    @State private var newSessionColor = "#a78bfa"
    @State private var newSessionContext = ""
    
    var body: some View {
        NavigationSplitView {
            // Sidebar - Session list
            sessionList
        } detail: {
            // Detail - Selected session or empty state
            if let selectedId = selectedSessionId,
               let session = viewModel.getSession(sessionId: selectedId) {
                SessionColumnView(session: session)
            } else {
                EmptyStateView(onNewSession: { showingNewSessionSheet = true })
            }
        }
        .navigationTitle("OpenClaw Deck")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
                }
            }
            
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    showingNewSessionSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(!viewModel.gatewayConnected)
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
        .sheet(isPresented: $showingNewSessionSheet) {
            newSessionSheet
        }
    }
    
    // MARK: - Session List
    
    private var sessionList: some View {
        List(viewModel.sessionOrder, id: \.self, selection: $selectedSessionId) { sessionId in
            if let session = viewModel.sessions[sessionId] {
                SessionRowView(session: session)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Sessions")
    }
    
    // MARK: - New Session Sheet
    
    private var newSessionSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $newSessionName)
                        .textContentType(.name)
                    
                    TextField("Icon (optional)", text: $newSessionIcon)
                        .textContentType(.nickname)
                    
                    ColorPicker("Color", selection: Binding(
                        get: { Color(hex: newSessionColor) ?? .purple },
                        set: { newSessionColor = $0.hexString ?? "#a78bfa" }
                    ))
                    
                    TextField("Context (optional)", text: $newSessionContext, axis: .vertical)
                        .textContentType(.fullStreetAddress)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingNewSessionSheet = false
                        resetNewSessionForm()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createSession()
                    }
                    .disabled(newSessionName.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func createSession() {
        _ = viewModel.createSession(
            name: newSessionName,
            icon: newSessionIcon.isEmpty ? nil : newSessionIcon,
            accentColor: newSessionColor,
            context: newSessionContext.isEmpty ? nil : newSessionContext
        )
        showingNewSessionSheet = false
        resetNewSessionForm()
    }
    
    private func resetNewSessionForm() {
        newSessionName = ""
        newSessionIcon = ""
        newSessionColor = "#a78bfa"
        newSessionContext = ""
    }
    
    // MARK: - State
    
    @State private var selectedSessionId: String?
}

// MARK: - Session Row View

struct SessionRowView: View {
    @ObservedObject var session: SessionState
    
    var body: some View {
        HStack {
            // Icon
            Text(session.sessionId.prefix(2).uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 32, height: 32)
                .background(Color.purple.opacity(0.2))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.sessionId)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("\(session.messageCount) messages")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status indicator
            switch session.status {
            case .idle:
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.green)
            case .thinking:
                ProgressView()
                    .scaleEffect(0.5)
            case .streaming:
                Image(systemName: "waveform")
                    .foregroundColor(.blue)
            case .error:
                Image(systemName: "exclamationmark.circle")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    var onNewSession: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "message.badge.filled.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Session Selected")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Select a session from the sidebar or create a new one to start chatting.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("New Session") {
                onNewSession()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
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
