// ConnectionStatusIcon.swift
// OpenClaw Deck Swift
//
// 连接状态图标组件 - 爱心形状，颜色随状态变化

import SwiftUI

/// 连接状态图标 - 爱心形状，带脉搏动画
struct ConnectionStatusIcon: View {
    let status: ConnectionStatus
    @State private var isAnimating = false

    var shouldAnimate: Bool {
        status == .connected
    }

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(status.color)
            .scaleEffect(isAnimating && shouldAnimate ? 1.2 : 1.0)
            .animation(
                Animation
                    .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .accessibilityLabel(status.rawValue)
            .task {
                isAnimating = true
            }
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
