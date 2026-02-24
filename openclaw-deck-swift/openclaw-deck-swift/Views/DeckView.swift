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
    VStack(spacing: 0) {
      // Top toolbar
      topToolbar

      Divider()

      // Horizontal scrollable session columns
      sessionColumns
    }
    .sheet(isPresented: $showingNewSessionSheet) {
      NewSessionSheet(
        viewModel: viewModel,
        isPresented: $showingNewSessionSheet
      )
    }
  }

  // MARK: - Top Toolbar

  private var topToolbar: some View {
    HStack {
      Text("OpenClaw Deck")
        .font(.headline)
        .padding(.leading)

      Spacer()

      // New Session button
      Button {
        showingNewSessionSheet = true
      } label: {
        Image(systemName: "plus")
      }
      .buttonStyle(.glass)
      .disabled(!viewModel.gatewayConnected)

      // Settings button
      Button {
        showingSettings = true
      } label: {
        Image(systemName: "gear")
      }
      .buttonStyle(.glass)
      .padding(.trailing)
    }
    .padding(.vertical, 8)
    .background(.bar)
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

  @State private var name = ""
  @State private var icon = ""
  @State private var context = ""

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("Name", text: $name)
            .textContentType(.name)

          TextField("Icon (optional)", text: $icon)
            .textContentType(.nickname)

          TextField("Context (optional)", text: $context, axis: .vertical)
        }
      }
      .formStyle(.grouped)
      .navigationTitle("New Session")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            isPresented = false
            resetForm()
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
      .frame(width: 400, height: 450)
    #endif
  }

  private func createSession() {
    _ = viewModel.createSession(
      name: name,
      icon: icon.isEmpty ? nil : icon,
      context: context.isEmpty ? nil : context
    )
    isPresented = false
    resetForm()
  }

  private func resetForm() {
    name = ""
    icon = ""
    context = ""
  }
}

#Preview {
  DeckView(
    viewModel: DeckViewModel(),
    showingSettings: .constant(false),
    showingNewSessionSheet: .constant(false)
  )
}
