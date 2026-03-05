// SyncButton.swift
// OpenClaw Deck Swift
//
// 共用的同步按钮组件

import SwiftUI

/// 同步按钮 - 用于 iPad 和 iPhone
struct SyncButton: View {
    @Bindable var viewModel: DeckViewModel

    var body: some View {
        Button {
            // TODO: 实现同步逻辑
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .accessibilityIdentifier("SyncButton")
    }
}

#Preview {
    SyncButton(viewModel: DeckViewModel())
}
