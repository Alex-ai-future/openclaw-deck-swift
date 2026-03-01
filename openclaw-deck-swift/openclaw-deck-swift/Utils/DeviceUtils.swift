// DeviceUtils.swift
// OpenClaw Deck Swift
//
// 设备类型判断工具

import Foundation

#if os(iOS)
    import UIKit
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
    /// 当前设备类型
    static var currentType: DeviceType {
        #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                return .iPad
            } else {
                return .iPhone
            }
        #elseif os(macOS)
            return .mac
        #else
            return .unknown
        #endif
    }

    /// 是否为 iPad
    static var isIPad: Bool {
        currentType == .iPad
    }

    /// 是否为 iPhone
    static var isIPhone: Bool {
        currentType == .iPhone
    }

    /// 是否为 Mac
    static var isMac: Bool {
        currentType == .mac
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
