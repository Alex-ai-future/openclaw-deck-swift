// SessionColumnView.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/24/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import SwiftUI
import MarkdownView

/// Session 列视图 - 单个聊天会话
struct SessionColumnView: View {
    @ObservedObject var session: SessionState
    @State private var inputText = ""
    @State private var isSending = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Message list
            messageList
            
            Divider()
            
            // Input area
            chatInput
        }
    }
    
    // MARK: - Message List
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(session.messages) { message in
                        MessageView(message: message)
                            .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: session.messages.count) { _, newValue in
                if newValue > 0 {
                    withAnimation {
                        proxy.scrollTo(session.messages.last?.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color(NSColor.textBackgroundColor))
    }
    
    // MARK: - Chat Input
    
    private var chatInput: some View {
        HStack(spacing: 12) {
            TextField(
                "Message...",
                text: $inputText,
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            .onSubmit {
                sendMessage()
            }
            .disabled(isSending || session.status == .streaming)
            
            Button {
                sendMessage()
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.title2)
                    .padding(10)
                    .background(inputText.isEmpty || isSending ? Color.secondary : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(inputText.isEmpty || isSending || session.status == .streaming)
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        guard !inputText.isEmpty, !isSending else { return }
        
        let text = inputText
        inputText = ""
        isSending = true
        
        Task {
            // TODO: Need to pass sessionId from parent
            // await viewModel.sendMessage(sessionId: session.sessionId, text: text)
            isSending = false
        }
    }
}

// MARK: - Message View

struct MessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                // Role badge
                HStack {
                    Image(systemName: iconForRole)
                        .font(.caption2)
                    Text(roleName)
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
                
                // Message content
                if message.role == .assistant && !message.text.isEmpty {
                    // Use MarkdownView for assistant messages
                    MarkdownView(message.text)
                } else {
                    Text(message.text)
                        .font(.body)
                }
                
                // Status indicators
                statusIndicators
                
                // Timestamp
                Text(formatTimestamp(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(backgroundColor)
            .cornerRadius(12)
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var iconForRole: String {
        switch message.role {
        case .user:
            return "person.fill"
        case .assistant:
            return "cpu.fill"
        case .system:
            return "info.circle.fill"
        }
    }
    
    private var roleName: String {
        switch message.role {
        case .user:
            return "You"
        case .assistant:
            return "Agent"
        case .system:
            return "System"
        }
    }
    
    private var backgroundColor: Color {
        switch message.role {
        case .user:
            return Color.blue.opacity(0.1)
        case .assistant:
            return Color(NSColor.controlBackgroundColor)
        case .system:
            return Color.orange.opacity(0.1)
        }
    }
    
    private var statusIndicators: some View {
        Group {
            if message.streaming == true {
                HStack {
                    ProgressView()
                        .scaleEffect(0.5)
                    Text("Streaming...")
                        .font(.caption2)
                }
                .foregroundColor(.blue)
            }
            
            if message.thinking == true {
                HStack {
                    Image(systemName: "brain.fill")
                        .font(.caption2)
                    Text("Thinking...")
                        .font(.caption2)
                }
                .foregroundColor(.purple)
            }
            
            if let toolUse = message.toolUse {
                HStack {
                    Image(systemName: "wrench.fill")
                        .font(.caption2)
                    Text("\(toolUse.toolName): \(toolUse.status)")
                        .font(.caption2)
                }
                .foregroundColor(.orange)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    SessionColumnView(
        session: SessionState(sessionId: "test", sessionKey: "agent:main:test")
    )
}
