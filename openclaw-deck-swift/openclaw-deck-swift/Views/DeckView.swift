// DeckView.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/24/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import os.log
import SwiftUI

private let logger = Logger(subsystem: "com.openclaw.deck", category: "DeckView")

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

/// Deck 视图 - 多列布局容器（iPad）
struct DeckView: View {
    @Bindable var viewModel: DeckViewModel
    @Binding var showingSettings: Bool
    @Binding var showingNewSessionSheet: Bool
    @State private var selectedSessionId: String?

    /// 内部状态管理
    @State private var showingSortSheet = false

    init(
        viewModel: DeckViewModel, showingSettings: Binding<Bool>,
        showingNewSessionSheet: Binding<Bool>
    ) {
        self.viewModel = viewModel
        _showingSettings = showingSettings
        _showingNewSessionSheet = showingNewSessionSheet
    }

    var body: some View {
        NavigationStack {
            // Session 列 - 占据剩余空间
            sessionColumns
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: selectedSessionId) { _, newId in
                    // Session 切换时通知 ViewModel
                    viewModel.selectSession(newId)

                    // 新选中的 Session 标记为已读
                    if let sessionId = newId,
                       let session = viewModel.sessions[sessionId]
                    {
                        session.hasUnreadMessage = false
                    }
                }
                .onChange(of: viewModel.globalInputState.selectedSessionId) { _, newId in
                    // ViewModel 的选中状态变化时，同步到本地 State
                    selectedSessionId = newId
                }
                .task {
                    // 初始化选中状态：确保 ViewModel 有选中的 Session
                    if viewModel.globalInputState.selectedSessionId == nil,
                       let firstSessionId = viewModel.sessionOrder.first
                    {
                        viewModel.selectSession(firstSessionId)
                    }
                    selectedSessionId = viewModel.globalInputState.selectedSessionId
                }
                .toolbar {
                    DeckToolbar(
                        viewModel: viewModel,
                        showingSettings: $showingSettings,
                        showingNewSessionSheet: $showingNewSessionSheet,
                        showingSortSheet: $showingSortSheet
                    )
                }
                // 注意：showingSettings 和 showingNewSessionSheet 由 ContentView 统一管理
                // 这里只管理 showingSortSheet
                .sheet(isPresented: $showingSortSheet) {
                    SessionSortView(viewModel: viewModel)
                }
        }
    }

    // MARK: - Session Columns

    private var sessionColumns: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: 0) {
                // Session columns
                ForEach(viewModel.sessionOrder, id: \.self) { sessionId in
                    if let session = viewModel.sessions[sessionId] {
                        SessionColumnView(
                            session: session,
                            viewModel: viewModel,
                            isSelected: sessionId == selectedSessionId
                        )
                        .frame(width: 400)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.75).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            )
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(
                .spring(response: 0.45, dampingFraction: 0.65), value: viewModel.sessionOrder
            )
            .background(Color.adaptiveBackground)
        }
    }
}

// MARK: - New Session Sheet

struct NewSessionSheet: View {
    @Bindable var viewModel: DeckViewModel
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var name = "default"
    @State private var context = ""
    @State private var isNameTaken = false
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                // Session Name
                Section {
                    TextField("session_name".localized, text: $name)
                        .focused($isNameFieldFocused)
                        .textContentType(.name)
                        .onChange(of: name) { _, newValue in
                            isNameTaken = viewModel.isSessionNameTaken(name: newValue)
                        }
                        .onSubmit {
                            createSession()
                        }
                    if isNameTaken, !name.isEmpty {
                        Text("session_name_taken".localized)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                } footer: {
                    Text("a_unique_identifier_for_this_session".localized)
                }

                // Notes (Optional)
                Section {
                    TextEditor(text: $context)
                        .font(.body)
                        .frame(minHeight: 80)
                        .scrollContentBackground(.hidden)
                } header: {
                    Text("notes_optional".localized)
                } footer: {
                    Text("additional_context_or_description_for_this_session".localized)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("new_session".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized) {
                        // 同时使用 dismiss 和 binding 确保关闭（iOS 26 修复）
                        isPresented = false
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("create".localized) {
                        createSession()
                    }
                    .disabled(name.isEmpty || isNameTaken)
                    .fontWeight(.semibold)
                }
            }
        }
        #if os(macOS)
        .frame(width: 400, height: 400)
        #endif
        .task {
            isNameFieldFocused = true
        }
    }

    private func createSession() {
        // 直接关闭弹窗（同步）
        isPresented = false
        // 创建会话
        _ = viewModel.createSession(name: name, context: context.isEmpty ? nil : context)
    }
}

#Preview {
    DeckView(
        viewModel: DeckViewModel(),
        showingSettings: .constant(false),
        showingNewSessionSheet: .constant(false)
    )
}
