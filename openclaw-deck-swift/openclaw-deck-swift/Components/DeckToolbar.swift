// DeckToolbar.swift
// OpenClaw Deck Swift
//
// 共用的工具栏组件 - 用于 iPad 和 iPhone

import SwiftUI

/// Deck 工具栏 - 统一的工具栏布局
struct DeckToolbar: ToolbarContent {
  @Bindable var viewModel: DeckViewModel

  // Binding 状态
  @Binding var showingSettings: Bool
  @Binding var showingNewSessionSheet: Bool
  @Binding var showingSortSheet: Bool
  @Binding var showingSyncAlert: Bool
  @Binding var showingConflictAlert: Bool

  var body: some ToolbarContent {
    // 左边：设置按钮 + App 名字（iPad 专用）
    ToolbarItem(placement: .topBarLeading) {
      #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
          // iPad：显示设置按钮 + App 名字
          HStack(spacing: 16) {
            Button {
              showingSettings = true
            } label: {
              Image(systemName: "gear")
            }
            .accessibilityIdentifier("settingsButton")
            
            Text("OpenClaw Deck")
              .font(.headline)
              .fontWeight(.semibold)
              .frame(width: 160, alignment: .leading)
          }
        } else {
          // iPhone：只显示设置按钮
          Button {
            showingSettings = true
          } label: {
            Image(systemName: "gear")
          }
          .accessibilityIdentifier("settingsButton")
        }
      #else
        // macOS：显示设置按钮 + App 名字
        HStack(spacing: 16) {
          Button {
            showingSettings = true
          } label: {
            Image(systemName: "gear")
          }
          .accessibilityIdentifier("settingsButton")
          
          Text("OpenClaw Deck")
            .font(.headline)
            .fontWeight(.semibold)
            .frame(width: 160, alignment: .leading)
        }
      #endif
    }

    // 右边：操作按钮
    ToolbarItemGroup(placement: .primaryAction) {
      // 新建 Session 按钮
      Button {
        showingNewSessionSheet = true
      } label: {
        Image(systemName: "plus")
      }
      .disabled(!viewModel.gatewayConnected)

      // 同步按钮
      SyncButton(
        viewModel: viewModel,
        showingSyncAlert: $showingSyncAlert
      )

      // 排序按钮
      Button {
        showingSortSheet = true
      } label: {
        Image(systemName: "arrow.up.arrow.down")
      }
    }
  }
}

// MARK: - Alert Modifiers

extension View {
  /// 添加同步相关弹窗（同步确认 + 冲突处理）
  /// - Parameters:
  ///   - viewModel: ViewModel
  ///   - showingSyncAlert: 同步确认弹窗显示状态
  ///   - showingConflictAlert: 冲突弹窗显示状态
  ///   - onChangeConflict: 冲突状态变化时的回调
  /// - Returns: 添加了弹窗的视图
  func deckSyncAlerts(
    viewModel: DeckViewModel,
    showingSyncAlert: Binding<Bool>,
    showingConflictAlert: Binding<Bool>,
    onChangeConflict: @escaping (Bool) -> Void
  ) -> some View {
    self
      // 同步确认弹窗
      .alert("Sync All Sessions?", isPresented: showingSyncAlert) {
        Button("Cancel", role: .cancel) {}
        Button("Sync") {
          Task {
            await viewModel.handleSync()
          }
        }
        .tint(.blue)
      } message: {
        Text("This will sync all sessions with the Gateway. Continue?")
      }

      // 同步冲突弹窗
      .alert("Sync Conflict", isPresented: showingConflictAlert) {
        Button("Use Local (Overwrite Cloud)", role: .destructive) {
          Task {
            await viewModel.resolveSyncConflict(choice: "local")
          }
        }
        Button("Use Cloud (Merge with Local)") {
          Task {
            await viewModel.resolveSyncConflict(choice: "remote")
          }
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        if let info = viewModel.conflictInfo {
          Text(info.description)
        } else {
          let localCount = viewModel.conflictLocalData?.sessions.count ?? 0
          let remoteCount = viewModel.conflictRemoteData?.sessions.count ?? 0
          Text(
            "Local has \(localCount) sessions, Cloud has \(remoteCount) sessions.\n\nChoose which data to use:"
          )
        }
      }

      // 监听冲突状态变化
      .onChange(of: viewModel.showingSyncConflict) { _, newValue in
        onChangeConflict(newValue)
      }
  }
}

#Preview {
  NavigationStack {
    Text("Preview")
      .toolbar {
        DeckToolbar(
          viewModel: DeckViewModel(),
          showingSettings: .constant(false),
          showingNewSessionSheet: .constant(false),
          showingSortSheet: .constant(false),
          showingSyncAlert: .constant(false),
          showingConflictAlert: .constant(false)
        )
      }
  }
}
