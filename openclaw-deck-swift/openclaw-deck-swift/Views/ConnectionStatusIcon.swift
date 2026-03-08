// ConnectionStatusIcon.swift
// OpenClaw Deck Swift
//
// 连接状态图标组件 - 爱心形状，颜色随状态变化

import SwiftUI

/// 连接状态图标 - 爱心形状
struct ConnectionStatusIcon: View {
    let status: ConnectionStatus

    var body: some View {
        Image(systemName: "heart")
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
