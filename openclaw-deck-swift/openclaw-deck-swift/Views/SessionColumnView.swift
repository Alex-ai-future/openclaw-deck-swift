// SessionColumnView.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/24/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import MarkdownUI
import SwiftUI

#if os(macOS)
  import AppKit
#else
  import UIKit
#endif

/// Session 列视图 - 单个聊天会话（只负责展示）
struct SessionColumnView: View {
  @Bindable var session: SessionState
  @Bindable var viewModel: DeckViewModel
  let isSelected: Bool
  let onSelect: () -> Void
  let onDelete: () -> Void

  @State private var showingDeleteAlert = false
  @State private var scrollTrigger = 0  // 用于触发滚动到底部（使用计数而非 toggle）
  @State private var isScrolling = false  // 防止重复滚动

  // 滚动到底部
  private func scrollToBottom() {
    guard !isScrolling else { return }
    isScrolling = true

    withAnimation(.smooth(duration: 0.3)) {
      scrollTrigger = 1
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      scrollTrigger = 0
      isScrolling = false
    }
  }

  // 发送 OK 消息
  private func sendOKMessage() {
    // 设置选中的 Session
    viewModel.globalInputState.selectedSessionId = session.sessionId

    // 设置输入内容为 "OK"
    viewModel.globalInputState.inputText = "OK"

    // 发送消息
    Task {
      await viewModel.globalInputState.sendMessage(
        to: session,
        viewModel: viewModel
      )
    }
  }

  // 发送 /new 消息
  private func sendNewMessage() {
    // 设置选中的 Session
    viewModel.globalInputState.selectedSessionId = session.sessionId

    // 设置输入内容为 "/new"
    viewModel.globalInputState.inputText = "/new"

    // 发送消息
    Task {
      await viewModel.globalInputState.sendMessage(
        to: session,
        viewModel: viewModel
      )
    }
  }

  // 发送输入框消息
  private func sendInputMessage() {
    // 设置选中的 Session
    viewModel.globalInputState.selectedSessionId = session.sessionId

    // 发送消息（使用当前输入框内容）
    Task {
      await viewModel.globalInputState.sendMessage(
        to: session,
        viewModel: viewModel
      )
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      ZStack {
        messageList

        // 底部浮动按钮组
        VStack {
          Spacer()
          HStack(spacing: 16) {
            // 滚动到底部按钮 - 始终显示
            ScrollToBottomButton {
              scrollToBottom()
            }

            // 快速操作按钮组 - 只在选中时显示
            if isSelected {
              HStack(spacing: 16) {
                // /new 按钮 - 点击发送 "/new" 消息
                Button {
                  sendNewMessage()
                } label: {
                  Text("/new")
                    .font(.title3)
                    .foregroundColor(.blue)
                }
                .buttonStyle(.glass)
                .frame(height: 36)

                // OK 按钮 - 点击发送 "OK" 消息
                Button {
                  sendOKMessage()
                } label: {
                  Text("OK")
                    .font(.title3)
                    .foregroundColor(.blue)
                }
                .buttonStyle(.glass)
                .frame(height: 36)

                // 发送按钮 - 点击发送输入框内容
                Button {
                  sendInputMessage()
                } label: {
                  Image(systemName: "arrow.up.circle")
                    .font(.title3)
                    .foregroundColor(.blue)
                }
                .buttonStyle(.glass)
                .frame(width: 36, height: 36)
              }
              .transition(.opacity.combined(with: .scale))
            }
          }
          .padding(12)
        }
      }
      // iPhone 上隐藏顶部状态条（使用 NavigationBar 工具栏）
      // iPad/macOS 保留顶部状态条
      .overlay(alignment: .top) {
        #if os(iOS)
          if UIDevice.current.userInterfaceIdiom != .phone {
            topStatusBar
          }
        #else
          topStatusBar
        #endif
      }

      // 底部状态条 - 选中蓝色，未选中灰色
      Rectangle()
        .fill(isSelected ? Color.blue : Color.gray)
        .frame(height: 3)
    }
    // iPhone 上在 NavigationBar 工具栏中显示 Session 名字
    .toolbar {
      #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
          ToolbarItem(placement: .principal) {
            sessionNameButton
          }
        }
      #endif
    }
    .contentShape(Rectangle())
    .onTapGesture {
      onSelect()
      // 点击整个 Session 视图时消除未读状态
      session.hasUnreadMessage = false
    }
    .onAppear {
      // 进入视图时自动选中当前 session，确保输入框发送到正确的会话
      viewModel.selectSession(session.sessionId)

      // 滚动到最底部（显示最新消息）
      scrollTrigger = 1
    }
    #if os(iOS)
      .safeAreaInset(edge: .bottom, spacing: 0) {
        // 只在 iPhone 上显示输入框（iPad 的 DeckView 已经有输入框）
        if UIDevice.current.userInterfaceIdiom != .pad {
          GlobalInputView(
            state: viewModel.globalInputState as! GlobalInputState
          ) {
            await viewModel.sendCurrentInput()
          }
        }
      }
    #endif
    .deleteSessionAlert(isPresented: $showingDeleteAlert) {
      onDelete()
    }
  }

  // MARK: - Session Name Button (for NavigationBar toolbar)

  private var sessionNameButton: some View {
    // 点击选中，长按弹出菜单
    Menu {
      // 会话详细信息（仅 4 项）
      Section {
        // 消息数量
        Label("\(session.messages.count) messages", systemImage: "message")

        // 最后活动时间
        if let lastActivity = session.lastMessageAt {
          Label("Last: \(formatDate(lastActivity))", systemImage: "clock")
        }

        // 上下文（如果有，限制 100 字符）
        if let context = session.context, !context.isEmpty {
          Label("Context: \(context.prefix(100))", systemImage: "text.alignleft")
        }

        // Session Key
        Label("Key: \(session.sessionKey)", systemImage: "tag")
      }

      Divider()

      // 删除按钮
      Section {
        Button(role: .destructive) {
          showingDeleteAlert = true
        } label: {
          Label("Delete Session", systemImage: "trash")
        }
      }
    } label: {
      // 点击按钮选中 Session
      Button {
        onSelect()
      } label: {
        Text(session.sessionId)
          .font(.body)
          .fontWeight(.medium)
          .lineLimit(1)
          // 工作中橘黄，完成未读绿色，其他蓝色
          .foregroundColor(
            session.isProcessing
              ? Color.orange : session.hasUnreadMessage ? Color.green : Color.blue
          )
      }
    }
  }

  // MARK: - Top Status Bar

  private var topStatusBar: some View {
    HStack {
      // Left: Empty spacer for balance
      Spacer()
        .frame(width: 44, height: 36)

      // Center: Session name glass button
      sessionNameButton
        .buttonStyle(.glass)
        .padding(12)

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
      }
      .onChange(of: session.messages.last?.id) { _, newLastMessageId in
        if let lastId = newLastMessageId {
          withAnimation(.smooth(duration: 0.2)) {
            proxy.scrollTo(lastId, anchor: .bottom)  // 滚动到最后一条消息的底部
          }
        }
      }
      .onChange(of: scrollTrigger) { _, newValue in
        // 只在 trigger=1 时滚动（确保每次位置一致）
        if newValue == 1, let lastId = session.messages.last?.id {
          proxy.scrollTo(lastId, anchor: .bottom)  // 滚动到最后一条消息的底部
        }
      }
    }
    .background(Color.adaptiveBackground)
  }

  // MARK: - Helper Functions

  /// 格式化日期
  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    return formatter.string(from: date)
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
    @State private var showingCopyToast = false
    @State private var copyText = ""

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
            .contextMenu {
              Button {
                copyText = message.text
                UIPasteboard.general.string = message.text
                showingCopyToast = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                  showingCopyToast = false
                }

                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
              } label: {
                Label("Copy", systemImage: "doc.on.doc")
              }
            }

          // Timestamp outside the bubble
          timestamp
            .padding(.horizontal, 4)
        }
        .overlay(alignment: .bottom) {
          if showingCopyToast {
            Text("Copied!")
              .font(.caption)
              .fontWeight(.medium)
              .foregroundColor(.white)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(Color.black.opacity(0.7))
              .cornerRadius(8)
              .transition(.opacity.combined(with: .scale))
              .animation(.easeInOut(duration: 0.2), value: showingCopyToast)
          }
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
        // 使用 MarkdownUI 支持链接点击
        Markdown(message.text)
          .font(.body)
          .foregroundColor(.primary)
          .onOpenURL { url in
            #if os(iOS) || os(visionOS)
              UIApplication.shared.open(url)
            #endif
          }
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
        Markdown(message.text)
          .font(.body)
          .foregroundColor(.primary)
          .textSelection(.enabled)
          .onOpenURL { url in
            #if os(iOS) || os(visionOS)
              UIApplication.shared.open(url)
            #endif
          }
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
    @State private var text =
      "This is a very long text that should span multiple lines and eventually reach the maximum height limit of 150 points. After that, the TextEditor should scroll internally instead of growing further. This tests the lineLimit(1...7) modifier. Keep typing to see it stop growing!"

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

// MARK: - Preview for Processing State Button

#Preview("Processing State Button") {
  struct ProcessingButtonPreview: View {
    @State private var isProcessing = true

    var body: some View {
      VStack(spacing: 20) {
        Text("Processing State Button Preview")
          .font(.headline)

        // 🆕 使用 tint 方法
        Button {
          isProcessing.toggle()
        } label: {
          Text("Welcome")
            .font(.body)
            .fontWeight(.medium)
            .lineLimit(1)
            .padding(12)
        }
        .buttonStyle(.glass)
        // 🆕 使用 tint 改变玻璃按钮背景色
        .tint(isProcessing ? Color.orange : Color.clear)

        Text("Tap to toggle state")
          .font(.caption)
          .foregroundColor(.secondary)

        // 测试不同 tint 颜色
        VStack(spacing: 10) {
          Text("Tint Color Tests")
            .font(.subheadline)
            .fontWeight(.medium)

          // 测试不同颜色
          HStack(spacing: 10) {
            Button(role: .none) {
            } label: {
              Text("Orange")
                .font(.caption)
                .padding(8)
            }
            .buttonStyle(.glass)
            .tint(Color.orange)

            Button(role: .none) {
            } label: {
              Text("Blue")
                .font(.caption)
                .padding(8)
            }
            .buttonStyle(.glass)
            .tint(Color.blue)

            Button(role: .none) {
            } label: {
              Text("Red")
                .font(.caption)
                .padding(8)
            }
            .buttonStyle(.glass)
            .tint(Color.red)
          }

          // 测试不同透明度
          HStack(spacing: 10) {
            Button(role: .none) {
            } label: {
              Text("0.3")
                .font(.caption)
                .padding(8)
            }
            .buttonStyle(.glass)
            .tint(Color.orange.opacity(0.3))

            Button(role: .none) {
            } label: {
              Text("0.5")
                .font(.caption)
                .padding(8)
            }
            .buttonStyle(.glass)
            .tint(Color.orange.opacity(0.5))

            Button(role: .none) {
            } label: {
              Text("0.7")
                .font(.caption)
                .padding(8)
            }
            .buttonStyle(.glass)
            .tint(Color.orange.opacity(0.7))
          }
        }
        .padding()
      }
      .padding()
    }
  }

  return ProcessingButtonPreview()
}
