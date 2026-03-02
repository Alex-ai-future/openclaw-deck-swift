// SessionSortView.swift
// OpenClaw Deck Swift
//
// Session 排序视图 - 按字典顺序显示

import SwiftUI

/// Session 排序视图 - 按字典顺序自动排序
struct SessionSortView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: DeckViewModel

    /// 按字典顺序排序的 Session 列表
    private var alphaSortedOrder: [String] {
        viewModel.sortedSessionIds
    }

    var body: some View {
        NavigationStack {
            List {
                // Session 列表
                Section {
                    ForEach(alphaSortedOrder, id: \.self) { sessionId in
                        if let session = viewModel.sessions[sessionId] {
                            HStack {
                                // Session 名称
                                Text(session.sessionId)
                                    .lineLimit(1)

                                Spacer()

                                // 消息数量徽章
                                if session.messageCount > 0 {
                                    Text("\(session.messageCount)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.secondary.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } footer: {
                    Text("sessions_are_sorted_alphabetically_by_name".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(.plain)
            .navigationTitle("sort_sessions".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("done".localized) {
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
}

// MARK: - Preview

#Preview("Session Sort View") {
    SessionSortView(viewModel: DeckViewModel())
}
