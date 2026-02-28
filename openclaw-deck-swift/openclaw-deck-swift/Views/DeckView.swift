// DeckView.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/24/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import SwiftUI
import os.log

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
  @State private var gatewayUrl: String
  @State private var token: String

  // 内部状态管理
  @State private var showingSortSheet = false
  @State private var showingSyncAlert = false
  @State private var showingConflictAlert = false

  init(
    viewModel: DeckViewModel, showingSettings: Binding<Bool>, showingNewSessionSheet: Binding<Bool>
  ) {
    self.viewModel = viewModel
    self._showingSettings = showingSettings
    self._showingNewSessionSheet = showingNewSessionSheet

    // 从 UserDefaults 加载配置
    let storage = UserDefaultsStorage.shared
    _gatewayUrl = State(initialValue: storage.loadGatewayUrl() ?? "ws://127.0.0.1:18789")
    _token = State(initialValue: storage.loadToken() ?? "")
  }

  var body: some View {
    NavigationStack {
      DeckCommonContainer(
        viewModel: viewModel,
        showingSettings: $showingSettings,
        showingNewSessionSheet: $showingNewSessionSheet
      ) {
        VStack(spacing: 0) {
          sessionColumns
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
          // 全局输入视图 - 系统自动处理键盘避让
          GlobalInputView(state: viewModel.globalInputState as! GlobalInputState) {
            await viewModel.sendCurrentInput()
          }
        }
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
        .task {
          // 初始化选中状态：确保 ViewModel 有选中的 Session
          if viewModel.globalInputState.selectedSessionId == nil,
            let firstSessionId = viewModel.sessionOrder.first
          {
            viewModel.selectSession(firstSessionId)
          }
          selectedSessionId = viewModel.globalInputState.selectedSessionId
        }
        // 关键修复：固定 VStack 宽度为屏幕宽度，避免随 ScrollView 变化
        .frame(maxWidth: .infinity)
        .navigationTitle("OpenClaw Deck")
        .toolbar {
          DeckToolbar(
            viewModel: viewModel,
            showingSettings: $showingSettings,
            showingNewSessionSheet: $showingNewSessionSheet,
            showingSortSheet: $showingSortSheet,
            showingSyncAlert: $showingSyncAlert,
            showingConflictAlert: $showingConflictAlert
          )
        }
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
              isSelected: sessionId == selectedSessionId,
              onSelect: {
                withAnimation {
                  selectedSessionId = sessionId
                  // hasUnreadMessage 在 .onChange 中统一处理
                }
              },
              onDelete: {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                  viewModel.deleteSession(sessionId: sessionId)
                  if selectedSessionId == sessionId {
                    selectedSessionId = nil
                  }
                }
              }
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
    }
    .animation(.spring(response: 0.45, dampingFraction: 0.65), value: viewModel.sessionOrder)
    .background(Color.adaptiveBackground)
  }
}

// MARK: - New Session Sheet

struct NewSessionSheet: View {
  @Bindable var viewModel: DeckViewModel
  @Binding var isPresented: Bool
  @Environment(\.dismiss) private var dismiss

  @State private var name = "default"
  @State private var context = ""
  @FocusState private var isNameFieldFocused: Bool

  var body: some View {
    NavigationStack {
      Form {
        // Session Name
        Section {
          TextField("Session Name", text: $name)
            .focused($isNameFieldFocused)
            .textContentType(.name)
            .onSubmit {
              createSession()
            }
        } footer: {
          Text("A unique identifier for this session.")
        }

        // Notes (Optional)
        Section {
          TextEditor(text: $context)
            .font(.body)
            .frame(minHeight: 80)
            .scrollContentBackground(.hidden)
        } header: {
          Text("Notes (Optional)")
        } footer: {
          Text("Additional context or description for this session.")
        }
      }
      .formStyle(.grouped)
      .navigationTitle("New Session")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Create") {
            createSession()
          }
          .disabled(name.isEmpty)
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
    _ = viewModel.createSession(name: name, context: context.isEmpty ? nil : context)
    dismiss()
  }
}

#Preview {
  DeckView(
    viewModel: DeckViewModel(),
    showingSettings: .constant(false),
    showingNewSessionSheet: .constant(false)
  )
}
