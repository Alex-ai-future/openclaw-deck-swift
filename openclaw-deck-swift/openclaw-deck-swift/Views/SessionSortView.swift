// SessionSortView.swift
// OpenClaw Deck Swift
//
// Session 排序视图 - 使用 SwiftData @Query + Toggle

import SwiftUI
import SwiftData

struct SessionSortView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: DeckViewModel
    
    /// ✅ 查询所有 Session（包括隐藏的）
    @Query(sort: \SessionState.sortOrder)
    private var allSessions: [SessionState]
    
    @State private var showHiddenSessions: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                // 总开关 Toggle
                Section {
                    Toggle("show_hidden_sessions".localized, isOn: $showHiddenSessions)
                }
                
                // Session 列表
                Section {
                    ForEach(Array(filteredSessions.enumerated()), id: \.element.id) { index, session in
                        SessionSortRowView(
                            session: session,
                            index: index
                        )
                    }
                    .onMove { source, destination in
                        // UI 移动数组，SessionSortRowView 会自动更新 sortOrder
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
    
    private var filteredSessions: [SessionState] {
        if showHiddenSessions {
            return allSessions
        } else {
            return allSessions.filter { !$0.isHidden }
        }
    }
}

// MARK: - Session Sort Row View

struct SessionSortRowView: View {
    let session: SessionState
    let index: Int  // ✅ 当前索引
    
    var body: some View {
        HStack(spacing: 12) {
            // 拖拽手柄
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tertiary)
                .frame(width: 20)
            
            // Session 图标
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Text(session.name.prefix(1).uppercased())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            // Session 信息
            VStack(alignment: .leading, spacing: 2) {
                Text(session.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if session.messageCount > 0 {
                    Text("\(session.messageCount) messages")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.secondary)
                } else {
                    Text("No messages")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            // 隐藏 Toggle
            Toggle(
                "",
                isOn: Binding(
                    get: { !session.isHidden },
                    set: { isVisible in
                        session.isHidden = !isVisible
                        // ✅ 自动保存
                    }
                )
            )
            .labelsHidden()
            .toggleStyle(.switch)
        }
        .padding(.vertical, 2)
        .task {
            // ✅ 监听位置变化，自动更新 sortOrder
            if session.sortOrder != index {
                session.sortOrder = index
                // ✅ 自动保存
            }
        }
        .onChange(of: index) { _, newIndex in
            // ✅ 索引变化时更新
            if session.sortOrder != newIndex {
                session.sortOrder = newIndex
                // ✅ 自动保存
            }
        }
    }
}

#Preview("Session Sort View") {
    SessionSortView(viewModel: DeckViewModel())
}

#Preview("Session Sort View - Dark") {
    SessionSortView(viewModel: DeckViewModel())
        .preferredColorScheme(.dark)
}
