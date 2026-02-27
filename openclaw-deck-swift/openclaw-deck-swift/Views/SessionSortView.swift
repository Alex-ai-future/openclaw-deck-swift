// SessionSortView.swift
// OpenClaw Deck Swift
//
// Session 排序表单视图

import SwiftUI

/// Session 排序视图 - 允许用户拖拽重新排序
struct SessionSortView: View {
  @Environment(\.dismiss) private var dismiss
  @Bindable var viewModel: DeckViewModel

  // 本地副本，用于编辑
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
              HStack {
                // 拖拽手柄图标
                Image(systemName: "line.3.horizontal")
                  .font(.title3)
                  .foregroundColor(.secondary)
                  .padding(.trailing, 8)

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
          .onMove { indices, newOffset in
            sortedOrder.move(fromOffsets: indices, toOffset: newOffset)
          }
        } footer: {
          Text("Drag to reorder")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
#if os(iOS) || os(ipadOS)
      .listStyle(.insetGrouped)
#elseif os(macOS)
      .listStyle(.inset)
#endif
      .navigationTitle("Sort Sessions")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Done") {
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
