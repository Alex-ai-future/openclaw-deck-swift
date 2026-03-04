// SessionSortView.swift
// OpenClaw Deck Swift
//
// Session 排序表单视图 - 简洁现代设计

import SwiftUI

/// Session 排序视图 - 允许用户拖拽重新排序
struct SessionSortView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: DeckViewModel

    /// 本地副本，用于编辑
    @State private var sortedOrder: [String]

    init(viewModel: DeckViewModel) {
        self.viewModel = viewModel
        _sortedOrder = State(initialValue: viewModel.sessionOrder)
    }

    var body: some View {
        NavigationStack {
            List {
                // Session 列表
                Section {
                    ForEach(sortedOrder, id: \.self) { sessionId in
                        if let session = viewModel.sessions[sessionId] {
                            SessionSortRow(session: session)
                                .padding(.vertical, 2)
                        }
                    }
                    .onMove { indices, newOffset in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            sortedOrder.move(fromOffsets: indices, toOffset: newOffset)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("sort_sessions".localized)
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("cancel".localized) {
                            dismiss()
                        }
                        .foregroundColor(.secondary)
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("done".localized) {
                            applySortOrder()
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
        }
        #if os(macOS)
        .frame(width: 400, height: 500)
        #endif
    }

    private func applySortOrder() {
        viewModel.sessionOrder = sortedOrder
        viewModel.saveSessionsToStorage()
    }
}

// MARK: - Session Sort Row

/// 排序行视图 - 简洁设计
struct SessionSortRow: View {
    let session: SessionState

    var body: some View {
        HStack(spacing: 12) {
            // 拖拽手柄 - subtle
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tertiary)
                .frame(width: 20)

            // Session 图标
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)

                Text(session.sessionId.prefix(1).uppercased())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
            }

            // Session 信息
            VStack(alignment: .leading, spacing: 2) {
                Text(session.sessionId)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if session.messageCount > 0 {
                    Text("\(session.messageCount) messages")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                } else {
                    Text("No messages")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }

            Spacer()
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview("Session Sort View") {
    SessionSortView(viewModel: DeckViewModel())
}

#Preview("Session Sort View - Dark") {
    SessionSortView(viewModel: DeckViewModel())
        .preferredColorScheme(.dark)
}
