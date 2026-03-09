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
                            SessionRowView(
                                session: session,
                                style: .sort,
                                showStatus: false,
                                showLastMessage: false,
                                onRequestDelete: nil
                            )
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
            .environment(\.editMode, .constant(.active))
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

// MARK: - Preview

#Preview("Session Sort View") {
    SessionSortView(viewModel: DeckViewModel())
}

#Preview("Session Sort View - Dark") {
    SessionSortView(viewModel: DeckViewModel())
        .preferredColorScheme(.dark)
}
