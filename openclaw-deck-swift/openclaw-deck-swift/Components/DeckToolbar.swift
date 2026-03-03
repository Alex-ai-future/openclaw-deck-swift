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
        // 左边：设置按钮
        #if os(iOS)
            ToolbarItem(placement: .topBarLeading) {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    // iPad：显示设置按钮 + App 名字
                    HStack(spacing: 16) {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gear")
                        }
                        .accessibilityIdentifier("settingsButton")

                        Text("openclaw_deck".localized)
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
            }

        #else
            ToolbarItem(placement: .automatic) {
                // macOS：显示设置按钮 + App 名字
                HStack(spacing: 16) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                    .accessibilityIdentifier("settingsButton")

                    Text("openclaw_deck".localized)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(width: 160, alignment: .leading)
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
            }
            .disabled(!viewModel.gatewayConnected)

            // 同步按钮
            SyncButton(viewModel: viewModel)

            // 排序按钮
            Button {
                showingSortSheet = true
            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
        }
    }
}
