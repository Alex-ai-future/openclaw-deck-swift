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
  #if os(iOS) || os(visionOS)
    @State private var keyboardOverlapHeight: CGFloat = 0
  #endif

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // Horizontal scrollable session columns
        sessionColumns
      }
      #if os(iOS) || os(visionOS)
        .padding(.bottom, keyboardOverlapHeight)
        .animation(.easeOut(duration: 0.25), value: keyboardOverlapHeight)
        .onAppear {
          setupKeyboardNotifications()
        }
        .onDisappear {
          NotificationCenter.default.removeObserver(self)
        }
      #endif
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

  // MARK: - Keyboard Handling

  #if os(iOS) || os(visionOS)
    private func setupKeyboardNotifications() {
      NotificationCenter.default.addObserver(
        forName: UIResponder.keyboardWillShowNotification,
        object: nil,
        queue: .main
      ) { notification in
        guard
          let keyboardEndFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
            as? CGRect
        else {
          return
        }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first
        else {
          return
        }

        // keyboardFrameEndUserInfoKey 已经是窗口坐标系，直接使用
        // 重叠高度 = 窗口高度 - 键盘顶部 Y 位置 = 键盘高度
        // 除以 6 是因为输入框只需要移动到键盘上方即可，不需要移动整个键盘高度
        let overlapHeight = max(0, (window.bounds.height - keyboardEndFrame.origin.y) / 6)

        withAnimation(.easeOut(duration: 0.25)) {
          self.keyboardOverlapHeight = overlapHeight
        }
      }

      NotificationCenter.default.addObserver(
        forName: UIResponder.keyboardWillHideNotification,
        object: nil,
        queue: .main
      ) { _ in
        withAnimation(.easeOut(duration: 0.25)) {
          self.keyboardOverlapHeight = 0
        }
      }
    }
  #endif
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
