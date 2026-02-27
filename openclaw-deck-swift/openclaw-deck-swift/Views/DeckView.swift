// DeckView.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/24/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import SwiftUI

#if os(macOS)
  import AppKit
#else
  import UIKit
#endif

/// Deck 视图 - 多列布局容器
struct DeckView: View {
  @Bindable var viewModel: DeckViewModel
  @Binding var showingSettings: Bool
  @Binding var showingNewSessionSheet: Bool
  @State private var selectedSessionId: String?

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        sessionColumns
      }
      .safeAreaInset(edge: .bottom, spacing: 0) {
        // 全局输入视图 - 系统自动处理键盘避让
        GlobalInputView(state: viewModel.globalInputState) {
          await viewModel.sendCurrentInput()
        }
      }
      .task {
        // 初始化选中状态：从 ViewModel 读取默认选中的 Session
        if let defaultSessionId = viewModel.globalInputState.selectedSessionId {
          selectedSessionId = defaultSessionId
        }
      }
      .onChange(of: selectedSessionId) { _, newId in
        // Session 切换时通知 ViewModel
        viewModel.selectSession(newId)
      }
      .navigationTitle("OpenClaw Deck")
      .toolbarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem {
          Button {
            showingNewSessionSheet = true
          } label: {
            Image(systemName: "plus")
          }
          .disabled(!viewModel.gatewayConnected)
        }
        ToolbarItem {

          // Settings button
          Button {
            showingSettings = true
          } label: {
            Image(systemName: "gear")
          }
        }

      }
      .sheet(isPresented: $showingNewSessionSheet) {
        NewSessionSheet(
          viewModel: viewModel,
          isPresented: $showingNewSessionSheet
        )
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
                }
              },
              onDelete: {
                viewModel.deleteSession(sessionId: sessionId)
                if selectedSessionId == sessionId {
                  selectedSessionId = nil
                }
              }
            )
            .frame(width: 400)
            .transition(.move(edge: .trailing).combined(with: .opacity))
          }
        }
      }
    }
    .background(Color.adaptiveBackground)
  }
}

// MARK: - New Session Sheet

struct NewSessionSheet: View {
  @Bindable var viewModel: DeckViewModel
  @Binding var isPresented: Bool
  @Environment(\.dismiss) private var dismiss

  @State private var name = "default"
  @FocusState private var isNameFieldFocused: Bool

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("Session Name", text: $name)
            .focused($isNameFieldFocused)
            .textContentType(.name)
            .onSubmit {
              createSession()
            }
        } footer: {
          Text("The session key will be generated automatically.")
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
        }
      }
    }
    #if os(macOS)
      .frame(width: 400, height: 300)
    #endif
    .task {
      isNameFieldFocused = true
    }
  }

  private func createSession() {
    _ = viewModel.createSession(name: name)
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
