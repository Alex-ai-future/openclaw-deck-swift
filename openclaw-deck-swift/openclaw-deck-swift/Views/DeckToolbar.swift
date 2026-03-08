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

    var body: some ToolbarContent {
        // 左边：设置按钮 + 连接状态
        #if os(iOS)
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 8) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                    .accessibilityIdentifier("settingsButton")

                    Divider()

                    // 连接状态指示器（空心圆圈）
                    ConnectionStatusIcon(status: viewModel.gatewayClient?.connectionStatus ?? .disconnected)
                }
            }

        #else
            ToolbarItem(placement: .automatic) {
                HStack(spacing: 8) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                    .accessibilityIdentifier("settingsButton")

                    Divider()

                    // 连接状态指示器（空心圆圈）
                    ConnectionStatusIcon(status: viewModel.gatewayClient?.connectionStatus ?? .disconnected)
                }
            }
        #endif

        // 右边：操作按钮
        ToolbarItemGroup(placement: .primaryAction) {
            // 新建 Session 按钮
            Button {
                showingNewSessionSheet = true
            } label: {
                Image(systemName: "plus")
                    .accessibilityHidden(true)
            }
            .accessibilityIdentifier("NewSessionButton")
            // 移除禁用逻辑，允许任何时候创建会话
            // .disabled(!(viewModel.gatewayClient?.connected ?? false))

            // 同步按钮
            SyncButton(viewModel: viewModel)

            // 排序按钮
            Button {
                showingSortSheet = true
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .accessibilityHidden(true)
            }
            .accessibilityIdentifier("SortButton")
        }
    }
}
