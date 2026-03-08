// ConnectionStatusIcon.swift
// OpenClaw Deck Swift
//
// 连接状态图标组件 - 爱心形状，颜色随状态变化

import SwiftUI

/// 连接状态图标 - 爱心形状，带脉搏动画
struct ConnectionStatusIcon: View {
    let status: ConnectionStatus

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(status.color)
            .symbolEffect(
                .pulse,
                options: .repeating,
                value: status == .connected
            )
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
