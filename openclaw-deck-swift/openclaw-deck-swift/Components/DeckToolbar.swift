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
  
  // 可选的网关 URL 和 Token（用于 SessionListView）
  var gatewayUrl: Binding<String>?
  var token: Binding<String>?
  
  // 可选的回调（用于 SessionListView）
  var onDisconnect: (() -> Void)?
  var onApplyAndReconnect: (() -> Void)?
  var onConnect: (() -> Void)?
  var onResetDeviceIdentity: (() -> Void)?
  var onClose: (() -> Void)?
  
  var body: some ToolbarContent {
    // 左边：设置按钮
    ToolbarItem(placement: .topBarLeading) {
      Button {
        showingSettings = true
      } label: {
        Image(systemName: "gear")
      }
      .accessibilityIdentifier("settingsButton")
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

// MARK: - Alert Helper Methods

extension DeckToolbar {
  /// 处理同步
  @MainActor
  func handleSync() async {
    let result = await viewModel.handleSync()
    
    switch result {
    case .success(let message):
      print("✅ Sync: \(message)")
    case .failure(let error):
      if error.localizedDescription.contains("conflict") {
        print("⚠️ Sync conflict detected")
      } else {
        print("❌ Sync failed: \(error.localizedDescription)")
      }
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
