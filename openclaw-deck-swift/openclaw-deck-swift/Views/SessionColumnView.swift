// SessionColumnView.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/24/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import MarkdownView
import SwiftUI

#if os(macOS)
  import AppKit
#else
  import UIKit
#endif

/// Session 列视图 - 单个聊天会话
struct SessionColumnView: View {
  @Bindable var session: SessionState
  @Bindable var viewModel: DeckViewModel
  let isSelected: Bool
  let onSelect: () -> Void
  let onDelete: () -> Void

  @State private var inputText = ""
  @State private var showingDeleteAlert = false

  var body: some View {
    VStack(spacing: 0) {
      // Column header with delete button
      columnHeader

      Divider()

      // Message list
      messageList

      Divider()

      // Input area
      chatInput
    }
    .background(isSelected ? Color.adaptiveSecondaryBackground : Color.adaptiveBackground)
    .cornerRadius(12)
    .shadow(
      color: isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.1),
      radius: isSelected ? 4 : 2, x: 0, y: 1
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
    )
    .contentShape(Rectangle())
    .onTapGesture {
      onSelect()
    }
    .alert("Delete Session?", isPresented: $showingDeleteAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {
        onDelete()
      }
    } message: {
      Text(
        "This will remove the session from the deck. Messages are stored in Gateway and can be reloaded."
      )
    }
  }

  // MARK: - Column Header

  private var columnHeader: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text(session.sessionId)
          .font(.caption)
          .fontWeight(.semibold)
          .lineLimit(1)

        Text("\(session.messageCount) messages")
          .font(.caption2)
          .foregroundColor(.secondary)
      }

      Spacer()

      // Status indicator
      switch session.status {
      case .idle:
        Image(systemName: "checkmark.circle.fill")
          .foregroundColor(.green)
          .font(.caption)
      case .thinking:
        ProgressView()
          .scaleEffect(0.5)
      case .streaming:
        Image(systemName: "waveform.circle.fill")
          .foregroundColor(.blue)
          .font(.caption)
      case .error:
        Image(systemName: "exclamationmark.circle.fill")
          .foregroundColor(.red)
          .font(.caption)
      }

      // Delete button
      Button {
        showingDeleteAlert = true
      } label: {
        Image(systemName: "trash")
          .foregroundColor(.secondary)
          .font(.caption)
      }
      .buttonStyle(.plain)
      .padding(.leading, 4)
    }
    .padding(8)
    .background(Color.adaptiveBackground)
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
      .onChange(of: session.messages.last?.id) { _, newLastMessageId in
        // 当有新消息或消息更新时，滚动到底部
        if let lastId = newLastMessageId {
          withAnimation(.smooth(duration: 0.2)) {
            proxy.scrollTo(lastId, anchor: .bottom)
          }
        }
      }
    }
    .background(Color.adaptiveBackground)
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
      .background(Color.adaptiveSecondaryBackground)
      .cornerRadius(10)
      .onSubmit {
        sendMessage()
      }
      .disabled(session.status == .streaming || !viewModel.gatewayConnected)

      Button {
        sendMessage()
      } label: {
        Image(systemName: sendIcon)
          .font(.title3)
          .fontWeight(.semibold)
          .padding(10)
          .background(sendButtonColor)
          .foregroundColor(.white)
          .cornerRadius(10)
      }
      .buttonStyle(.plain)
      .disabled(inputText.isEmpty || session.status == .streaming || !viewModel.gatewayConnected)
    }
    .padding()
  }

  // MARK: - Computed Properties

  private var sendIcon: String {
    if session.status == .streaming || session.status == .thinking {
      return "ellipsis.circle.fill"
    }
    return "paperplane.fill"
  }

  private var sendButtonColor: Color {
    if inputText.isEmpty || session.status == .streaming || session.status == .thinking
      || !viewModel.gatewayConnected
    {
      return .secondary
    }
    return .blue
  }

  // MARK: - Actions

  private func sendMessage() {
    guard !inputText.isEmpty, !viewModel.isInitializing, viewModel.gatewayConnected else { return }

    let text = inputText
    inputText = ""

    Task {
      // 发送消息到 viewModel（不等待响应）
      await viewModel.sendMessage(sessionId: session.sessionId, text: text)
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
      return Color.adaptiveSecondaryBackground
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
    session: SessionState(sessionId: "test", sessionKey: "agent:main:test"),
    viewModel: DeckViewModel(),
    isSelected: true,
    onSelect: {},
    onDelete: {}
  )
}
