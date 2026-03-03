// SyncButton.swift
// OpenClaw Deck Swift
//
// 共用的同步按钮组件

import SwiftUI

/// 同步按钮 - 用于 iPad 和 iPhone
struct SyncButton: View {
    @Bindable var viewModel: DeckViewModel
    
    /// 是否在 UI 测试模式
    private var isUITesting: Bool {
        ProcessInfo.processInfo.environment["UITESTING"] == "YES"
    }

    var body: some View {
        Button {
            // 只显示同步确认弹窗，不开始同步
            // 用户点"确定"后才会调用 handleSync()
            viewModel.isSyncing = true
        } label: {
            Image(systemName: "arrow.clockwise")
                .rotationEffect(.degrees(viewModel.isSyncing ? 360 : 0))
                .animation(
                    isUITesting ? .none :  // 测试模式禁用动画
                    (viewModel.isSyncing
                        ? .linear(duration: 1).repeatForever(autoreverses: false)
                        : .default),
                    value: viewModel.isSyncing
                )
        }
        .disabled(!viewModel.gatewayConnected || viewModel.isSyncing)
        .accessibilityIdentifier("SyncButton")
    }
}

#Preview {
    SyncButton(viewModel: DeckViewModel())
}
