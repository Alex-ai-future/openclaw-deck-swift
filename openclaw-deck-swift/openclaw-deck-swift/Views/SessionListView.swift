// SessionListView.swift
// OpenClaw Deck Swift
//
// Session 列表视图 - 使用 SwiftData @Query

import SwiftUI
import SwiftData

struct SessionListView: View {
    @Bindable var viewModel: DeckViewModel
    
    /// ✅ 一行代码绑定 DB，自动按 sortOrder 排序
    @Query(sort: \SessionState.sortOrder)
    private var sessions: [SessionState]
    
    @State private var navigationPath = NavigationPath()
    @State private var showingSettings = false
    @State private var showingNewSessionSheet = false
    @State private var showingSortSheet = false
    @State private var showingDeleteAlert = false
    @State private var deleteSessionId: String?
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                ForEach(sessions.filter { !$0.isHidden }) { session in
                    NavigationLink(value: session) {
                        SessionRowView(
                            session: session,
                            onRequestDelete: {
                                deleteSessionId = session.id
                                showingDeleteAlert = true
                            }
                        )
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("openclaw_deck".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                DeckToolbar(
                    viewModel: viewModel,
                    showingSettings: $showingSettings,
                    showingNewSessionSheet: $showingNewSessionSheet,
                    showingSortSheet: $showingSortSheet
                )
            }
            .navigationDestination(for: SessionState.self) { session in
                SessionColumnView(
                    session: session,
                    viewModel: viewModel,
                    isSelected: true
                )
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    session.hasUnreadMessage = false
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(isConnected: .constant(false), viewModel: viewModel)
            }
            .sheet(isPresented: $showingNewSessionSheet) {
                NewSessionSheet(viewModel: viewModel, isPresented: $showingNewSessionSheet)
            }
            .sheet(isPresented: $showingSortSheet) {
                SessionSortView(viewModel: viewModel)
            }
            .deleteSessionAlert(isPresented: $showingDeleteAlert) {
                if let sessionId = deleteSessionId {
                    viewModel.deleteSession(id: sessionId)
                    deleteSessionId = nil
                }
            }
        }
    }
}

// MARK: - Session Row View

struct SessionRowView: View {
    let session: SessionState
    var onRequestDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Session 图标
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.blue.opacity(0.05)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Text(session.name.prefix(1).uppercased())
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            // Session 信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if session.hasUnreadMessage {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                    }
                }
                
                if let lastMessage = session.messages.last {
                    Text(lastMessage.text)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("No messages yet")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onRequestDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    SessionListView(viewModel: DeckViewModel())
}
