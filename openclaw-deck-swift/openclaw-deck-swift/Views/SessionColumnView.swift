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
  @State private var textHeight: CGFloat = 36
  @StateObject private var speechRecognizer = SpeechRecognizer()

  var body: some View {
    ZStack {
      // Message list
      messageList

      // Input area - floating at bottom
      chatInput
    }
    .overlay(alignment: .top) {
      // Top status bar - fixed at top
      topStatusBar
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

  // MARK: - Top Status Bar

  private var topStatusBar: some View {
    HStack {
      // Left: Empty spacer for balance
      Spacer()
        .frame(width: 44, height: 36)

      // Center: Session name glass button
      // Menu button (overlay on right spacer)
      Menu {
        Button(role: .destructive) {
          showingDeleteAlert = true
        } label: {
          Label("Delete Session", systemImage: "trash")
        }
      } label: {
        Button {

        } label: {
          Text(session.sessionKey)
            .font(.subheadline)
            .fontWeight(.medium)
            .lineLimit(1)
            .padding(8)
        }
        .glassEffect()

      }

      // Right: Spacer
      Spacer()
        .frame(width: 44, height: 36)

    }
    .padding(.horizontal, 16)
    .padding(.top, 2)
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
        .padding(.bottom, 80)  // 为悬浮输入框预留空间
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
    VStack {
      Spacer()

      HStack(spacing: 8) {
        // Dictation button - stays outside the input field
        DictationButton(text: $inputText, speechRecognizer: speechRecognizer)
          .frame(width: 36, height: 36)

        // Input field with overlay for send button
        ZStack(alignment: .trailing) {
          // TextField for input with auto-resize
          TextField("Message", text: $inputText, axis: .vertical)
            .font(.body)
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
            .padding(.trailing, 40)
            .lineLimit(1...7)
            .textFieldStyle(.plain)
            .tint(.accentColor)
            .background(GeometryReader { geometry in
              Color.clear
                .preference(key: HeightPreference.self, value: geometry.size.height)
            })

          // Send button - shown only when text is not empty
          if !inputText.isEmpty {
            Button {
              sendMessage()
            } label: {
              Image(systemName: "arrow.up.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)
            }
            .padding(.trailing, 8)
            .transition(.opacity.combined(with: .scale))
          }

          // Placeholder - shown when empty
          if inputText.isEmpty {
            Text("Message")
              .font(.body)
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal, 14)
              .allowsHitTesting(false)
          }
        }
        .frame(height: textHeight)
        .onPreferenceChange(HeightPreference.self) { newHeight in
          let height = max(36, min(newHeight, 150))
          print("📏 Measured: \(newHeight) -> Using: \(height)pt")
          withAnimation(.easeOut(duration: 0.1)) {
            textHeight = height
          }
        }
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(.regularMaterial)
            .overlay(
              RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        )
      }
      .padding(.horizontal, 12)
      .padding(.bottom, 8)
      .padding(.top, 8)
      .contentShape(Rectangle())
      .onTapGesture {
        // Empty gesture handler to prevent event bubbling to parent view
      }
    }
  }

  // MARK: - Actions

  private func sendMessage() {
    guard !inputText.isEmpty, !viewModel.isInitializing, viewModel.gatewayConnected else { return }

    let text = inputText
    
    // 如果正在听写，先停止听写，防止回调继续更新输入框
    if speechRecognizer.isListening {
      speechRecognizer.stopListening()
    }
    
    inputText = ""  // 清空输入框

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
    @State private var showFullContent = false

    var body: some View {
      // 只显示 user 和 assistant 消息
      if message.role != .user && message.role != .assistant {
        EmptyView()
      } else if message.text.isEmpty && !shouldShowEmptyMessage {
        // 对于 assistant 空消息，只有在 streaming 时显示占位
        EmptyView()
      } else {
        messageBody
      }
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
      } else {
        Text(message.text)
          .font(.body)
          .foregroundColor(.white)
      }
    }

    /// 是否应该显示空消息（只有 assistant streaming 时显示占位）
    private var shouldShowEmptyMessage: Bool {
      message.role == .assistant && (message.streaming ?? false)
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
      default:
        return Color.adaptiveSecondaryBackground
      }
    }

    private var cornerMask: UIRectCorner {
      switch message.role {
      case .user:
        return [.topLeft, .topRight, .bottomLeft]
      case .assistant:
        return [.topLeft, .topRight, .bottomRight]
      default:
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
      // 只显示 user 和 assistant 消息
      if message.role != .user && message.role != .assistant {
        EmptyView()
      } else if message.text.isEmpty && !shouldShowEmptyMessage {
        // 对于 assistant 空消息，只有在 streaming 时显示占位
        EmptyView()
      } else {
        messageBody
      }
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
      } else {
        Text(message.text)
          .font(.body)
          .foregroundColor(.white)
      }
    }

    /// 是否应该显示空消息（只有 assistant streaming 时显示占位）
    private var shouldShowEmptyMessage: Bool {
      message.role == .assistant && (message.streaming ?? false)
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
      default:
        return Color.adaptiveSecondaryBackground
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

// MARK: - Preview Tests for TextEditor Height

#Preview("Empty - Single Line") {
  struct TestView: View {
    @State private var text = ""
    
    var body: some View {
      VStack {
        Text("Empty input box - should be 36pt (1 line)")
          .font(.caption)
          .foregroundColor(.secondary)
        
        ZStack(alignment: .trailing) {
          TextEditor(text: $text)
            .font(.body)
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
            .padding(.trailing, 40)
            .multilineTextAlignment(.leading)
            .lineLimit(1...7)
            .frame(minHeight: 36, maxHeight: 150)
            .tint(.accentColor)
          
          if !text.isEmpty {
            Button {
              text = ""
            } label: {
              Image(systemName: "arrow.up.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)
            }
            .padding(.trailing, 8)
          }
          
          if text.isEmpty {
            Text("Message")
              .font(.body)
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal, 14)
              .allowsHitTesting(false)
          }
        }
        .frame(minHeight: 36, maxHeight: 150)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(.regularMaterial)
            .overlay(
              RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        )
        .frame(width: 300)
      }
      .padding()
    }
  }
  
  return TestView()
}

#Preview("Short Text - 1 Line") {
  struct TestView: View {
    @State private var text = "Hello"
    
    var body: some View {
      VStack {
        Text("Short text - should stay 1 line")
          .font(.caption)
          .foregroundColor(.secondary)
        
        ZStack(alignment: .trailing) {
          TextEditor(text: $text)
            .font(.body)
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
            .padding(.trailing, 40)
            .multilineTextAlignment(.leading)
            .lineLimit(1...7)
            .frame(minHeight: 36, maxHeight: 150)
            .tint(.accentColor)
          
          if !text.isEmpty {
            Button {
              text = ""
            } label: {
              Image(systemName: "arrow.up.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)
            }
            .padding(.trailing, 8)
          }
        }
        .frame(minHeight: 36, maxHeight: 150)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(.regularMaterial)
            .overlay(
              RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        )
        .frame(width: 300)
      }
      .padding()
    }
  }
  
  return TestView()
}

#Preview("Multi-Line - Auto Growth") {
  struct TestView: View {
    @State private var text = "Line 1\nLine 2\nLine 3"
    
    var body: some View {
      VStack {
        Text("Multi-line text - type to test auto growth")
          .font(.caption)
          .foregroundColor(.secondary)
        
        ZStack(alignment: .trailing) {
          TextEditor(text: $text)
            .font(.body)
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
            .padding(.trailing, 40)
            .multilineTextAlignment(.leading)
            .lineLimit(1...7)
            .frame(minHeight: 36, maxHeight: 150)
            .tint(.accentColor)
          
          if !text.isEmpty {
            Button {
              text = ""
            } label: {
              Image(systemName: "arrow.up.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)
            }
            .padding(.trailing, 8)
          }
        }
        .frame(minHeight: 36, maxHeight: 150)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(.regularMaterial)
            .overlay(
              RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        )
        .frame(width: 300)
      }
      .padding()
    }
  }
  
  return TestView()
}

#Preview("Long Text - Max Height") {
  struct TestView: View {
    @State private var text = "This is a very long text that should span multiple lines and eventually reach the maximum height limit of 150 points. After that, the TextEditor should scroll internally instead of growing further. This tests the lineLimit(1...7) modifier. Keep typing to see it stop growing!"
    
    var body: some View {
      VStack {
        Text("Long text - should max at 150pt (7 lines)")
          .font(.caption)
          .foregroundColor(.secondary)
        
        ZStack(alignment: .trailing) {
          TextEditor(text: $text)
            .font(.body)
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
            .padding(.trailing, 40)
            .multilineTextAlignment(.leading)
            .lineLimit(1...7)
            .frame(minHeight: 36, maxHeight: 150)
            .tint(.accentColor)
          
          if !text.isEmpty {
            Button {
              text = ""
            } label: {
              Image(systemName: "arrow.up.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)
            }
            .padding(.trailing, 8)
          }
        }
        .frame(minHeight: 36, maxHeight: 150)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(.regularMaterial)
            .overlay(
              RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        )
        .frame(width: 300)
      }
      .padding()
    }
  }
  
  return TestView()
}

// MARK: - PreferenceKey for Height Measurement

struct HeightPreference: PreferenceKey {
  static var defaultValue: CGFloat = 36
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}
