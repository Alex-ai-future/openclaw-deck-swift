// ConnectionStatusIcon.swift
// OpenClaw Deck Swift
//
// 连接状态图标组件 - 空心圆圈，颜色随状态变化

import SwiftUI

/// 连接状态图标 - 统一的空心圆圈样式
struct ConnectionStatusIcon: View {
    let status: ConnectionStatus

    var body: some View {
        Image(systemName: "circle")
            .foregroundColor(status.color)
            .accessibilityLabel(status.rawValue)
    }
}

#Preview {
    VStack(spacing: 16) {
        ConnectionStatusIcon(status: .connected)
        ConnectionStatusIcon(status: .reconnecting)
        ConnectionStatusIcon(status: .disconnected)
    }
    .padding()
}
