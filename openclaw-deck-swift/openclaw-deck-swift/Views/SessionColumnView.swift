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
    var session: SessionState
    var viewModel: DeckViewModel
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var showingDeleteAlert = false
    @State private var showingNewAlert = false
    @State private var showingSessionDetails = false
    @State private var scrollTargetId: String? // 待滚动的目标消息 ID

    /// 滚动到底部（手动点击按钮）
    private func scrollToBottom() {
        guard let lastId = session.messages.last?.id else { return }
        // 先清空再设置，强制触发 onChange（即使 ID 相同）
        scrollTargetId = nil
        DispatchQueue.main.async {
            scrollTargetId = lastId
        }
    }

    /// 发送 OK 消息
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

    /// 发送 Stop 请求 - 中断当前对话
    private func sendStopMessage() {
        guard let client = viewModel.gatewayClient else {
            // Gateway 未连接，显示错误
            viewModel.stopErrorText = "Gateway 未连接"
            viewModel.showStopError = true
            return
        }

        Task {
            do {
                // 不传 runId，让 Gateway 中止该 session 的所有活跃 run
                // 这样更可靠，因为 runId 可能已经过期或不匹配
                try await client.abortChat(sessionKey: session.sessionKey, runId: nil)
                // 成功后更新状态
                await MainActor.run {
                    session.activeRunId = nil
                    session.status = .idle
                    session.isProcessing = false
                }
            } catch {
                // 失败时显示错误提示
                await MainActor.run {
                    viewModel.stopErrorText = "Stop 失败：\(error.localizedDescription)"
                    viewModel.showStopError = true
                }
            }
        }
    }

    /// 发送 /new 消息（先显示确认弹窗）
    private func sendNewMessage() {
        showingNewAlert = true
    }

    /// 确认发送 /new 消息
    private func confirmSendNewMessage() {
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

    /// 发送输入框消息
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
            // 顶部状态条（iPad + macOS）
            topStatusBar

            // 消息列表和浮动按钮 - 使用 ZStack 但让消息列表可以压缩
            ZStack(alignment: .bottom) {
                // 消息列表 - 使用 maxHeight: .infinity 但不设置 minHeight
                messageList
                    .frame(maxHeight: .infinity)

                // 底部浮动按钮组
                VStack {
                    // 顶部状态条 - iPad 显示对话名字
                    topStatusBar
                    Spacer()

                    HStack(spacing: 16) {
                        // 滚动到底部按钮 - 始终显示
                        ScrollToBottomButton {
                            scrollToBottom()
                        }

                        // 快速操作按钮组
                        // 判断状态
                        let isProcessing = session.activeRunId != nil

                        // Stop 按钮 - 优先级最高，无论是否选中，AI 处理中时都显示
                        if isProcessing {
                            Button {
                                sendStopMessage()
                            } label: {
                                Image(systemName: "stop.circle")
                                    .font(.title2)
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.glass)
                            .frame(height: 40)
                        }
                        // 其他按钮只在选中时显示
                        else if isSelected {
                            // 判断状态
                            let hasInput = !viewModel.globalInputState.inputText.isEmpty

                            // 发送按钮 - 输入框有内容时显示
                            if hasInput {
                                Button {
                                    sendInputMessage()
                                } label: {
                                    Image(systemName: "arrow.up.circle").accessibilityIdentifier("sendButton")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.glass)
                                .frame(height: 40)
                            }
                            // new/OK 按钮 - 输入框为空且 AI 未处理时显示
                            else {
                                Button {
                                    sendNewMessage()
                                } label: {
                                    Text("new".localized)
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.glass)
                                .frame(height: 40)

                                Button {
                                    sendOKMessage()
                                } label: {
                                    Text("ok".localized)
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.glass)
                                .frame(height: 40)
                            }
                        }
                    }
                    .padding(12)
                }
            }
            .frame(maxHeight: .infinity)

            // 底部状态条 - 选中蓝色，未选中灰色
            Rectangle()
                .fill(isSelected ? Color.blue : Color.gray)
                .frame(height: 3)

            // MARK: - 输入框（放在 VStack 内部，键盘弹出时会自动推起）

            #if os(iOS)
                if !DeviceUtils.isIPad {
                    GlobalInputView(
                        state: viewModel.globalInputState as! GlobalInputState
                    ) {
                        await viewModel.sendCurrentInput()
                    }
                }
            #endif
        }
        .accessibilityElement()
        .accessibilityIdentifier("Session-\(session.sessionId)")
        .accessibilityLabel(session.sessionId)
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
            // 延迟执行确保消息已经加载完成，避免滚动到空白位置
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                scrollToBottom()
            }
        }
        // iPhone 上使用 NavigationBar 工具栏显示对话名字
        #if os(iOS)
        .toolbar {
            if UIDevice.current.userInterfaceIdiom == .phone {
                // 中间：对话名字按钮（玻璃按钮，本身是 Menu）
                ToolbarItem(placement: .principal) {
                    sessionNameButton
                }
            }
        }
        #endif
        .deleteSessionAlert(isPresented: $showingDeleteAlert) {
            onDelete()
        }
        .alert("confirm_new_session".localized, isPresented: $showingNewAlert) {
            Button("cancel".localized, role: .cancel) {}
            Button("confirm".localized, role: .destructive) {
                confirmSendNewMessage()
            }
        } message: {
            Text("new_session_confirm_message".localized)
        }
    }

    // MARK: - Session Name Button

    private var sessionNameButton: some View {
        Button {
            showingSessionDetails = true
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
        .buttonStyle(.glass)
        .accessibilityIdentifier("Session-\(session.sessionId)")
        .sheet(isPresented: $showingSessionDetails) {
            SessionDetailView(
                session: session,
                onDelete: {
                    showingDeleteAlert = true
                    showingSessionDetails = false
                }
            )
        }
    }

    // MARK: - Session Menu Content (简化版 - 只保留快捷操作)

    private var sessionMenuContent: some View {
        Group {
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("delete_session".localized, systemImage: "trash.fill")
                }
            }
        }
    }

    // MARK: - Top Status Bar

    private var topStatusBar: some View {
        HStack {
            Spacer()

            // 中间：对话名字按钮（iPad + macOS）
            #if os(iOS)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    sessionNameButton
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
            #elseif os(macOS)
                sessionNameButton
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            #endif

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 2)
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Group {
                    if session.isLoadingMessages {
                        // 消息加载中
                        VStack {
                            ProgressView()
                            Text("正在加载消息历史".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // 显示消息列表
                        VStack(alignment: .leading, spacing: 12) {
                            // Loading indicator
                            if session.isHistoryLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("loading_history".localized)
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
                    }
                }
                .padding()
                .id("messages-container-\(session.messages.count)")
            }
            .onChange(of: session.messages.last?.id) { _, newLastMessageId in
                if let lastId = newLastMessageId {
                    scrollTargetId = lastId
                }
            }
            .onChange(of: scrollTargetId) { _, newTargetId in
                if let lastId = newTargetId {
                    withAnimation(.smooth(duration: 0.2)) {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
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
                cornerRadii: CGSize(width: radius, height: radius)
            )
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
            if message.role != .user, message.role != .assistant {
                EmptyView()
                //      } else if message.text.isEmpty && !shouldShowEmptyMessage {
                //        // 对于 assistant 空消息，只有在 streaming 时显示占位
                //        EmptyView()
            } else {
                messageBody
            }
        }

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
                                UIPasteboard.general.string = message.text

                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            } label: {
                                Label("copy".localized, systemImage: "doc.on.doc")
                            }
                        }

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
            if message.role == .assistant {
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

        private var timestamp: some View {
            Text(formatTimestamp(message.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }

        private var backgroundColor: Color {
            switch message.role {
            case .user:
                Color.blue
            case .assistant:
                Color.adaptiveSecondaryBackground
            default:
                Color.adaptiveSecondaryBackground
            }
        }

        private var cornerMask: UIRectCorner {
            switch message.role {
            case .user:
                [.topLeft, .topRight, .bottomLeft]
            case .assistant:
                [.topLeft, .topRight, .bottomRight]
            default:
                [.topLeft, .topRight, .bottomRight]
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
            if message.role != .user, message.role != .assistant {
                EmptyView()
            } else {
                messageBody
            }
        }

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
            if message.role == .assistant {
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

        private var timestamp: some View {
            Text(formatTimestamp(message.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }

        private var backgroundColor: Color {
            switch message.role {
            case .user:
                Color.blue
            case .assistant:
                Color.adaptiveSecondaryBackground
            default:
                Color.adaptiveSecondaryBackground
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
        )
    )

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
                        Button("increment".localized) {
                            count += 1
                        }
                    }
                }
            }
            ```

            Would you like to know more about any specific SwiftUI feature?
            """,
            timestamp: Date().addingTimeInterval(-240)
        )
    )

    // Round 2 - User asks about state management
    session.messages.append(
        ChatMessage(
            id: "msg-3",
            role: .user,
            text: "How does @State work?",
            timestamp: Date().addingTimeInterval(-120)
        )
    )

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
        )
    )

    // Round 3 - User asks a follow-up
    session.messages.append(
        ChatMessage(
            id: "msg-5",
            role: .user,
            text: "What about @Observable?",
            timestamp: Date().addingTimeInterval(-30)
        )
    )

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
        )
    )

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
        )
    )

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
        )
    )

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
                Text("empty_input_box_should_be_36pt_1_line".localized)
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
                        .lineLimit(1 ... 7)
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
                        Text("message".localized)
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
                Text("short_text_should_stay_1_line".localized)
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
                        .lineLimit(1 ... 7)
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
                Text("multi_line_text_type_to_test_auto_growth".localized)
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
                        .lineLimit(1 ... 7)
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
                Text("long_text_should_max_at_150pt_7_lines".localized)
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
                        .lineLimit(1 ... 7)
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
                Text("processing_state_button_preview".localized)
                    .font(.headline)

                // 🆕 使用 tint 方法
                Button {
                    isProcessing.toggle()
                } label: {
                    Text("welcome".localized)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .padding(12)
                }
                .buttonStyle(.glass)
                // 🆕 使用 tint 改变玻璃按钮背景色
                .tint(isProcessing ? Color.orange : Color.clear)

                Text("tap_to_toggle_state".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // 测试不同 tint 颜色
                VStack(spacing: 10) {
                    Text("tint_color_tests".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    // 测试不同颜色
                    HStack(spacing: 10) {
                        Button(role: .none) {} label: {
                            Text("orange".localized)
                                .font(.caption)
                                .padding(8)
                        }
                        .buttonStyle(.glass)
                        .tint(Color.orange)

                        Button(role: .none) {} label: {
                            Text("blue".localized)
                                .font(.caption)
                                .padding(8)
                        }
                        .buttonStyle(.glass)
                        .tint(Color.blue)

                        Button(role: .none) {} label: {
                            Text("red".localized)
                                .font(.caption)
                                .padding(8)
                        }
                        .buttonStyle(.glass)
                        .tint(Color.red)
                    }

                    // 测试不同透明度
                    HStack(spacing: 10) {
                        Button(role: .none) {} label: {
                            Text("0.3")
                                .font(.caption)
                                .padding(8)
                        }
                        .buttonStyle(.glass)
                        .tint(Color.orange.opacity(0.3))

                        Button(role: .none) {} label: {
                            Text("0.5")
                                .font(.caption)
                                .padding(8)
                        }
                        .buttonStyle(.glass)
                        .tint(Color.orange.opacity(0.5))

                        Button(role: .none) {} label: {
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
