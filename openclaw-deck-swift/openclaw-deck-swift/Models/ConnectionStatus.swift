// ConnectionStatus.swift
// OpenClaw Deck Swift
//
// 网络连接状态枚举 - 用于 Gateway 客户端连接状态显示

import SwiftUI

/// 网络连接状态枚举
enum ConnectionStatus: String {
    case connected // 已连接（绿色）
    case reconnecting // 重连中（橙黄色）
    case disconnected // 未连接/断开（红色）

    /// 状态对应的颜色
    var color: Color {
        switch self {
        case .connected:
            .green
        case .reconnecting:
            .orange
        case .disconnected:
            .red
        }
    }

    /// 状态对应的图标
    var iconName: String {
        switch self {
        case .connected:
            "checkmark.circle.fill"
        case .reconnecting:
            "arrow.clockwise"
        case .disconnected:
            "xmark.circle.fill"
        }
    }
}
