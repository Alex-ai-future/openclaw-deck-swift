// DeviceUtils.swift
// OpenClaw Deck Swift
//
// 设备类型判断工具

import Foundation

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

/// 设备类型枚举
enum DeviceType {
    case iPhone
    case iPad
    case mac
    case unknown
}

/// 设备判断工具
enum DeviceUtils {
    /// 是否为 Mac
    static var isMac: Bool {
        #if os(macOS)
            return true
        #else
            return false
        #endif
    }

    /// 是否为移动设备（iPhone 或 iPad）
    static var isMobile: Bool {
        #if os(iOS)
            return true
        #else
            return false
        #endif
    }
}
