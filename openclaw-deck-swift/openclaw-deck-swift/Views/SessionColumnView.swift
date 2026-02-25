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
    NavigationStack {
      VStack(spacing: 0) {
        // Message list
        messageList

        Divider()

        // Input area
        chatInput
      }
      .navigationTitle(session.sessionKey)
      .toolbar {
        #if os(macOS)
          /// Left: Status indicator
          ToolbarItem {
            StatusIndicator(status: session.status)
          }
        #else
          // Left: Status indicator
          ToolbarItem(placement: .topBarLeading) {
            StatusIndicator(status: session.status)
          }
        #endif

        // Center: Session key and message count
        ToolbarItem(placement: .principal) {
          VStack(spacing: 1) {
            Text(session.sessionKey)
              .font(.caption)
              .fontWeight(.medium)
              .lineLimit(1)

            Text("\(session.messageCount) messages")
              .font(.caption2)
              .foregroundColor(.secondary)
              .lineLimit(1)
          }
        }

        #if os(macOS)
          // Right: Delete button
          ToolbarItem {
            Button("Delete", role: .destructive) {
              showingDeleteAlert = true
            }
          }
        #else
          // Right: Delete button
          ToolbarItem(placement: .topBarTrailing) {
            Button("Delete", role: .destructive) {
              showingDeleteAlert = true
            }
          }
        #endif

      }
    }
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

  // MARK: - Status Indicator

  /// Status indicator - maps status to icon and color only
  struct StatusIndicator: View {
    let status: SessionStatus

    var body: some View {
      statusLabel
        .frame(minWidth: 80, alignment: .center)
    }

    @ViewBuilder
    private var statusIcon: some View {
      switch status {
      case .idle:
        Circle()
          .fill(.green)
          .frame(width: 6, height: 6)

      case .thinking:
        ProgressView()
          .scaleEffect(0.7)
          .tint(.purple)

      case .streaming:
        Circle()
          .fill(.blue)
          .frame(width: 6, height: 6)

      case .error:
        Circle()
          .fill(.red)
          .frame(width: 6, height: 6)
      }
    }

    private var statusLabel: some View {
      Text(statusText)
        .foregroundColor(.primary)
        .lineLimit(1)
    }

    private var statusText: String {
      switch status {
      case .idle:
        return "Ready"
      case .thinking:
        return "Thinking"
      case .streaming:
        return "Working"
      case .error:
        return "Error"
      }
    }
  }

  // MARK: - Message List

  private var messageList: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 12) {
          // Loading indicator
          if session.isHistoryLoading {
            HStack {
              Spacer()
              ProgressView()
                .scaleEffect(0.8)
              Text("Loading history...")
                .font(.caption)
                .foregroundColor(.secondary)
              Spacer()
            }
            .padding(.vertical, 8)
          }

          // Messages
          ForEach(session.messages) { message in
            MessageView(message: message)
              .id(message.id)
          }
        }
        .padding()
      }
      .onChange(of: session.messages.last?.id) { _, newLastMessageId in
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
    HStack(spacing: 8) {
      // Input field - iOS 26 Liquid Glass style
      TextField(
        "Message",
        text: $inputText,
        axis: .vertical
      )
      .textFieldStyle(.plain)
      .padding(.horizontal, 14)
      .frame(height: 36)
      .background(
        RoundedRectangle(cornerRadius: 20)
          .fill(.regularMaterial)
      )
      .onSubmit {
        sendMessage()
      }

      // Send button - native iOS glass style
      Button {
        if !inputText.isEmpty {
          sendMessage()
        }

      } label: {
        Text("Send")
      }
      .buttonStyle(.glass)
      .frame(height: 36)
      .opacity(inputText.isEmpty ? 0.5 : 1.0)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background(Color.clear)
  }

  // MARK: - Actions

  private func sendMessage() {
    guard !inputText.isEmpty, !viewModel.isInitializing, viewModel.gatewayConnected else { return }

    let text = inputText
    inputText = ""

    Task {
      await viewModel.sendMessage(sessionId: session.sessionId, text: text)
    }
  }
}

// MARK: - Corner Radius Extension (iOS only)

#if os(iOS) || os(visionOS)
  extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
      clipShape(RoundedCorner(radius: radius, corners: corners))
    }
  }

  struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
      let path = UIBezierPath(
        roundedRect: rect,
        byRoundingCorners: corners,
        cornerRadii: CGSize(width: radius, height: radius))
      return Path(path.cgPath)
    }
  }
#endif

// MARK: - Message View

#if os(iOS) || os(visionOS)
  /// iMessage 风格的消息视图 (iOS)
  struct MessageView: View {
    let message: ChatMessage

    var body: some View {
      messageBody
    }

    @ViewBuilder
    private var messageBody: some View {
      HStack {
        if message.role == .user {
          Spacer()
        }

        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 2) {
          // Message bubble
          messageContent
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(backgroundColor)
            .cornerRadius(18, corners: cornerMask)

          // Timestamp outside the bubble
          timestamp
            .padding(.horizontal, 4)
        }

        if message.role == .assistant {
          Spacer()
        }
      }
    }

    @ViewBuilder
    private var messageContent: some View {
      if message.role == .assistant && message.text.isEmpty && (message.streaming ?? false) {
        // 正在传输中但内容为空时，显示 Thinking 占位
        HStack {
          ProgressView()
            .scaleEffect(0.8)
          Text("Thinking...")
            .font(.body)
        }
        .foregroundColor(.secondary)
      } else if message.role == .assistant && !message.text.isEmpty {
        MarkdownView(message.text)
          .font(.body)
          .foregroundColor(.primary)
      } else if message.role == .system {
        Text(message.text)
          .font(.body)
          .foregroundColor(.orange)
      } else {
        Text(message.text)
          .font(.body)
          .foregroundColor(.white)
      }
    }

    private var timestamp: some View {
      Text(formatTimestamp(message.timestamp))
        .font(.caption2)
        .foregroundColor(.secondary)
    }

    private var backgroundColor: Color {
      switch message.role {
      case .user:
        return Color.blue
      case .assistant:
        return Color.adaptiveSecondaryBackground
      case .system:
        return Color.orange.opacity(0.15)
      }
    }

    private var cornerMask: UIRectCorner {
      switch message.role {
      case .user:
        return [.topLeft, .topRight, .bottomLeft]
      case .assistant, .system:
        return [.topLeft, .topRight, .bottomRight]
      }
    }

    private func formatTimestamp(_ date: Date) -> String {
      let formatter = DateFormatter()
      formatter.timeStyle = .short
      return formatter.string(from: date)
    }
  }
#else
  /// iMessage 风格的消息视图 (macOS)
  struct MessageView: View {
    let message: ChatMessage

    var body: some View {
      messageBody
    }

    @ViewBuilder
    private var messageBody: some View {
      HStack {
        if message.role == .user {
          Spacer()
        }

        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 2) {
          // Message bubble
          messageContent
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(backgroundColor)
            .cornerRadius(18)

          // Timestamp outside the bubble
          timestamp
            .padding(.horizontal, 4)
        }

        if message.role == .assistant {
          Spacer()
        }
      }
    }

    @ViewBuilder
    private var messageContent: some View {
      if message.role == .assistant && message.text.isEmpty && (message.streaming ?? false) {
        // 正在传输中但内容为空时，显示 Thinking 占位
        HStack {
          ProgressView()
            .scaleEffect(0.8)
          Text("Thinking...")
            .font(.body)
        }
        .foregroundColor(.secondary)
      } else if message.role == .assistant && !message.text.isEmpty {
        MarkdownView(message.text)
          .font(.body)
          .foregroundColor(.primary)
      } else if message.role == .system {
        Text(message.text)
          .font(.body)
          .foregroundColor(.orange)
      } else {
        Text(message.text)
          .font(.body)
          .foregroundColor(.white)
      }
    }

    private var timestamp: some View {
      Text(formatTimestamp(message.timestamp))
        .font(.caption2)
        .foregroundColor(.secondary)
    }

    private var backgroundColor: Color {
      switch message.role {
      case .user:
        return Color.blue
      case .assistant:
        return Color.adaptiveSecondaryBackground
      case .system:
        return Color.orange.opacity(0.15)
      }
    }

    private func formatTimestamp(_ date: Date) -> String {
      let formatter = DateFormatter()
      formatter.timeStyle = .short
      return formatter.string(from: date)
    }
  }
#endif

// MARK: - Preview

#Preview("Multi-turn Conversation") {
  SessionColumnView(
    session: createSampleSession(),
    viewModel: DeckViewModel(),
    isSelected: true,
    onSelect: {},
    onDelete: {}
  )
}

#Preview("Empty Session") {
  SessionColumnView(
    session: SessionState(sessionId: "empty", sessionKey: "agent:main:empty"),
    viewModel: DeckViewModel(),
    isSelected: true,
    onSelect: {},
    onDelete: {}
  )
}

#Preview("Streaming State") {
  SessionColumnView(
    session: createStreamingSession(),
    viewModel: DeckViewModel(),
    isSelected: true,
    onSelect: {},
    onDelete: {}
  )
}

// MARK: - Preview Helpers

private func createSampleSession() -> SessionState {
  let session = SessionState(
    sessionId: "demo",
    sessionKey: "agent:main:demo"
  )

  // Round 1 - User asks about Swift
  session.messages.append(
    ChatMessage(
      id: "msg-1",
      role: .user,
      text: "What is SwiftUI?",
      timestamp: Date().addingTimeInterval(-300)
    ))

  session.messages.append(
    ChatMessage(
      id: "msg-2",
      role: .assistant,
      text: """
        **SwiftUI** is Apple's modern declarative UI framework for building user interfaces across all Apple platforms.

        ## Key Features

        - **Declarative Syntax**: Describe your UI in a straightforward manner
        - **Cross-platform**: Works on iOS, iPadOS, macOS, watchOS, and tvOS
        - **State-driven**: Automatically updates UI when data changes
        - **Preview support**: See your UI in real-time while coding

        Here's a simple example:

        ```swift
        struct ContentView: View {
            @State private var count = 0

            var body: some View {
                VStack {
                    Text("Count: \\(count)")
                    Button("Increment") {
                        count += 1
                    }
                }
            }
        }
        ```

        Would you like to know more about any specific SwiftUI feature?
        """,
      timestamp: Date().addingTimeInterval(-240)
    ))

  // Round 2 - User asks about state management
  session.messages.append(
    ChatMessage(
      id: "msg-3",
      role: .user,
      text: "How does @State work?",
      timestamp: Date().addingTimeInterval(-120)
    ))

  session.messages.append(
    ChatMessage(
      id: "msg-4",
      role: .assistant,
      text: """
        `@State` is a property wrapper that manages **local state** in SwiftUI views.

        ## How it works

        1. **Value type storage**: Stores value types (structs, enums)
        2. **Source of truth**: The view owns this data
        3. **Automatic updates**: When `@State` changes, SwiftUI re-renders the view

        ## Example

        ```swift
        struct CounterView: View {
            @State private var count = 0

            var body: some View {
                Text("Count: \\(count)")
                    .onTapGesture { count += 1 }
            }
        }
        ```

        ## When to use

        - ✅ Local UI state (toggle, text field, selection)
        - ❌ Shared state between views (use `@Binding` or `@Observable`)
        """,
      timestamp: Date().addingTimeInterval(-60)
    ))

  // Round 3 - User asks a follow-up
  session.messages.append(
    ChatMessage(
      id: "msg-5",
      role: .user,
      text: "What about @Observable?",
      timestamp: Date().addingTimeInterval(-30)
    ))

  session.messages.append(
    ChatMessage(
      id: "msg-6",
      role: .assistant,
      text: """
        `@Observable` is the **new macro** introduced in iOS 17/macOS 14 for managing observable data.

        ## Key differences from ObservableObject

        | Feature | @Observable | ObservableObject |
        |---------|-------------|------------------|
        | Protocol | None needed | ObservableObject |
        | Wrappers | No @Published | @Published required |
        | Performance | Better | Good |
        | iOS Support | iOS 17+ | iOS 13+ |

        ## Example

        ```swift
        @Observable
        class UserStore {
            var users: [User] = []

            func addUser(_ user: User) {
                users.append(user)
            }
        }
        ```

        No `@Published` needed - the macro handles everything automatically!
        """,
      timestamp: Date().addingTimeInterval(-15)
    ))

  return session
}

private func createStreamingSession() -> SessionState {
  let session = SessionState(
    sessionId: "streaming",
    sessionKey: "agent:main:streaming"
  )

  session.messages.append(
    ChatMessage(
      id: "msg-1",
      role: .user,
      text: "Explain async/await in Swift",
      timestamp: Date().addingTimeInterval(-60)
    ))

  session.messages.append(
    ChatMessage(
      id: "msg-2",
      role: .assistant,
      text: """
        Swift's **async/await** is a modern concurrency model introduced in Swift 5.5.

        ## Basics

        - `async` functions can be suspended without blocking threads
        - `await` marks suspension points where you wait for async results

        ```swift
        func fetchData() async throws -> Data {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        }
        ```

        ## Structured Concurrency

        Swift uses **structured concurrency** with tasks and task groups:

        ```swift
        Task {
            let (image, data) = try await (
                loadImage(from: url1),
                loadImage(from: url2)
            )
        }
        ```

        ## Actors

        Actors provide thread-safe access to mutable state:

        ```swift
        actor Counter {
            var value = 0
            func increment() { value += 1 }
        }
        ```

        ---

        The framework also includes:
        - **Sendable** types for safe concurrent access
        - **MainActor** for UI updates
        - **Task priorities** for resource management

        Would you like examples of any specific concurrency pattern?
        """,
      timestamp: Date().addingTimeInterval(-45),
      streaming: true
    ))

  session.status = .streaming
  session.activeRunId = "run-streaming"

  return session
}
