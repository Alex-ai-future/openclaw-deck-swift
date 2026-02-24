// DeckView.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/24/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import SwiftUI

/// Deck 视图 - 多列布局容器
struct DeckView: View {
    @Bindable var viewModel: DeckViewModel
    @Binding var showingSettings: Bool
    @Binding var showingNewSessionSheet: Bool
    @State private var selectedSessionId: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Top toolbar
            topToolbar
            
            Divider()
            
            // Horizontal scrollable session columns
            sessionColumns
        }
        .sheet(isPresented: $showingNewSessionSheet) {
            NewSessionSheet(
                viewModel: viewModel,
                isPresented: $showingNewSessionSheet
            )
        }
    }
    
    // MARK: - Top Toolbar
    
    private var topToolbar: some View {
        HStack {
            Text("OpenClaw Deck")
                .font(.headline)
                .padding(.leading)
            
            Spacer()
            
            // New Session button - always visible
            Button {
                showingNewSessionSheet = true
            } label: {
                Label("New Session", systemImage: "plus")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.bordered)
            .disabled(!viewModel.gatewayConnected)
            
            // Settings button
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gear")
            }
            .buttonStyle(.plain)
            .padding(.trailing)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Session Columns
    
    private var sessionColumns: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: 1) {
                // Session columns
                ForEach(viewModel.sessionOrder, id: \.self) { sessionId in
                    if let session = viewModel.sessions[sessionId] {
                        SessionColumnView(
                            session: session,
                            isSelected: sessionId == selectedSessionId,
                            onSelect: {
                                withAnimation {
                                    selectedSessionId = sessionId
                                }
                            },
                            onDelete: {
                                viewModel.deleteSession(sessionId: sessionId)
                                if selectedSessionId == sessionId {
                                    selectedSessionId = nil
                                }
                            }
                        )
                        .frame(width: 400)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }

                // Add Session column - always visible
                AddSessionColumnView(
                    isEnabled: viewModel.gatewayConnected,
                    onTap: {
                        showingNewSessionSheet = true
                    }
                )
                .frame(width: 80)
            }
            .padding(.vertical)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Add Session Column View

struct AddSessionColumnView: View {
    let isEnabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack {
            Button(action: onTap) {
                VStack {
                    Spacer()
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(isEnabled ? .blue : .gray)
                    
                    Text("New")
                        .font(.caption)
                        .foregroundColor(isEnabled ? .blue : .gray)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
            .contentShape(Rectangle())
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 4)
    }
}

// MARK: - New Session Sheet

struct NewSessionSheet: View {
    @Bindable var viewModel: DeckViewModel
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var icon = ""
    @State private var color = "#a78bfa"
    @State private var context = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                    
                    TextField("Icon (optional)", text: $icon)
                        .textContentType(.nickname)
                    
                    ColorPicker("Color", selection: Binding(
                        get: { Color(hex: color) ?? .purple },
                        set: { color = $0.hexString ?? "#a78bfa" }
                    ))
                    
                    TextField("Context (optional)", text: $context, axis: .vertical)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                        resetForm()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createSession()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        #if os(macOS)
        .frame(width: 400, height: 500)
        #endif
    }
    
    private func createSession() {
        _ = viewModel.createSession(
            name: name,
            icon: icon.isEmpty ? nil : icon,
            accentColor: color,
            context: context.isEmpty ? nil : context
        )
        isPresented = false
        resetForm()
    }
    
    private func resetForm() {
        name = ""
        icon = ""
        color = "#a78bfa"
        context = ""
    }
}

#Preview {
    DeckView(
        viewModel: DeckViewModel(),
        showingSettings: .constant(false),
        showingNewSessionSheet: .constant(false)
    )
}
