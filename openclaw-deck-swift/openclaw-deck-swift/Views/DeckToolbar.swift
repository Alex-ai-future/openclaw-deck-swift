// DeckToolbar.swift
// OpenClaw Deck Swift
//
// 共用的工具栏组件 - 用于 iPad 和 iPhone

import SwiftUI

/// Deck 工具栏 - 统一的工具栏布局
struct DeckToolbar: ToolbarContent {
    /// ViewModel（可选，如果提供则使用其 connectionStatus）
    var viewModel: DeckViewModel?

    /// 或者直接提供 connectionStatus（用于 WelcomeView 等没有 ViewModel 的场景）
    var connectionStatus: ConnectionStatus = .disconnected

    // 设置按钮：两种方式选其一
    @Binding var showingSettings: Bool
    var onShowSettings: (() -> Void)?

    // 右侧操作按钮（可选，不提供则不显示）
    var showingNewSessionSheet: Binding<Bool>?
    var showingSortSheet: Binding<Bool>?

    var body: some ToolbarContent {
        // 左边：设置按钮 + 连接状态
        #if os(iOS)
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 8) {
                    Button {
                        if let onShowSettings {
                            onShowSettings()
                        } else {
                            showingSettings = true
                        }
                    } label: {
                        Image(systemName: "gear")
                    }
                    .accessibilityIdentifier("settingsButton")

                    Divider()

                    // 连接状态指示器（爱心形状）
                    ConnectionStatusIcon(
                        status: viewModel?.gatewayClient?.connectionStatus ?? connectionStatus
                    )
                }
            }

        #else
            ToolbarItem(placement: .automatic) {
                HStack(spacing: 8) {
                    Button {
                        if let onShowSettings {
                            onShowSettings()
                        } else {
                            showingSettings = true
                        }
                    } label: {
                        Image(systemName: "gear")
                    }
                    .accessibilityIdentifier("settingsButton")

                    Divider()

                    // 连接状态指示器（爱心形状）
                    ConnectionStatusIcon(
                        status: viewModel?.gatewayClient?.connectionStatus ?? connectionStatus
                    )
                }
            }
        #endif

        // 右边：操作按钮（只在提供 Binding 时显示）
        if let showingNewSessionSheet, let showingSortSheet, let viewModel {
            ToolbarItemGroup(placement: .primaryAction) {
                // 新建 Session 按钮
                Button {
                    showingNewSessionSheet.wrappedValue = true
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
                    showingSortSheet.wrappedValue = true
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .accessibilityHidden(true)
                }
                .accessibilityIdentifier("SortButton")
            }
        }
    }
}
