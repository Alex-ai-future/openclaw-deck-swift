// SessionRowView.swift
// OpenClaw Deck Swift
//
// 可复用的 Session 行视图组件

import SwiftUI

/// Session 行视图样式
enum SessionRowStyle {
    case list // 聊天列表：大图标 + 状态标签 + 最后消息
    case sort // 排序界面：小图标 + 无状态
}

/// Session 行视图 - 可复用组件
struct SessionRowView: View {
    let session: SessionState
    let style: SessionRowStyle
    let showStatus: Bool
    let showLastMessage: Bool
    let onRequestDelete: (() -> Void)?

    /// 初始化
    init(
        session: SessionState,
        style: SessionRowStyle = .list,
        showStatus: Bool = true,
        showLastMessage: Bool = true,
        onRequestDelete: (() -> Void)? = nil
    ) {
        self.session = session
        self.style = style
        self.showStatus = showStatus
        self.showLastMessage = showLastMessage
        self.onRequestDelete = onRequestDelete
    }

    var body: some View {
        HStack(spacing: 12) {
            // Session 图标
            SessionIcon(session: session, size: iconSize)

            // Session 信息
            VStack(alignment: .leading, spacing: 4) {
                // 标题行（名称 + 消息数 + 状态）
                titleRow

                // 最后消息（第二行，支持 Markdown，根据 showToolMessages 过滤）
                if showLastMessage, let lastMessage = session.getLastVisibleMessage() {
                    LastMessageRow(message: lastMessage)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .applySwipeActions(session: session, onRequestDelete: onRequestDelete)
    }

    // MARK: - Computed Properties

    private var iconSize: CGFloat {
        style == .list ? 44 : 40
    }

    // MARK: - Subviews

    private var titleRow: some View {
        HStack(spacing: 8) {
            // Session 名称
            Text(session.name ?? session.sessionId)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)

            // 状态标签（紧跟名称，仅聊天列表显示）
            if showStatus {
                StatusBadge(session: session)
            }

            Spacer()

            // 消息数量（固定在右边）
            Text("\(session.messageCount)")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Last Message Row

/// 最后消息行视图 - 支持 Markdown 渲染
struct LastMessageRow: View {
    let message: ChatMessage

    var body: some View {
        // 使用 Markdown 渲染（支持 **粗体**、*斜体*、`代码` 等）
        Text(.init(message.text))
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Session Icon

/// Session 图标视图
struct SessionIcon: View {
    let session: SessionState
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: style == .list ? 10 : 8)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.blue.opacity(0.05)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Text((session.name ?? session.sessionId).prefix(1).uppercased())
                .font(.system(size: size == 44 ? 18 : 16, weight: .semibold))
                .foregroundColor(.blue)
        }
    }

    private var style: SessionRowStyle {
        size == 44 ? .list : .sort
    }
}

// MARK: - Status Badge

/// 状态标签视图
struct StatusBadge: View {
    let session: SessionState

    var body: some View {
        if session.status == .thinking || session.status == .streaming {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)
                Text("processing_status".localized)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.orange)
            }
        } else if session.hasUnreadMessage {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                Text("new_status".localized)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - Swipe Actions

extension View {
    /// 应用滑动手势
    func applySwipeActions(session: SessionState, onRequestDelete: (() -> Void)?) -> some View {
        self
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                if session.hasUnreadMessage {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            session.hasUnreadMessage = false
                        }
                    } label: {
                        Label("Read", systemImage: "checkmark.circle")
                    }
                    .tint(.green)
                } else {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            session.hasUnreadMessage = true
                        }
                    } label: {
                        Label("Unread", systemImage: "circle")
                    }
                    .tint(.orange)
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                if let onDelete = onRequestDelete {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
    }
}

// MARK: - Preview

#Preview("List Style") {
    SessionRowView(
        session: SessionState(sessionId: "main", sessionKey: "agent:main:test"),
        style: .list,
        showStatus: true,
        showLastMessage: true
    )
    .padding()
}

#Preview("Sort Style") {
    SessionRowView(
        session: SessionState(sessionId: "main", sessionKey: "agent:main:test"),
        style: .sort,
        showStatus: false,
        showLastMessage: false
    )
    .padding()
}
