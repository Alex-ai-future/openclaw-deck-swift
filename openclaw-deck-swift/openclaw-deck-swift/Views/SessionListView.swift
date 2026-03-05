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
