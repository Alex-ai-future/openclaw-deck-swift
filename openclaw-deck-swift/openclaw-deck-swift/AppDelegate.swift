// AppDelegate.swift
// OpenClaw Deck Swift
//
// 应用代理 - 处理通知前台显示

import Foundation
import os
import UserNotifications

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

private let logger = Logger(subsystem: "com.openclaw.deck", category: "AppDelegate")

#if os(iOS)

    // MARK: - iOS AppDelegate

    /// iOS 应用代理 - 处理通知相关回调
    class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
        static let shared = AppDelegate()

        override private init() {
            super.init()
            UNUserNotificationCenter.current().delegate = self
        }

        func userNotificationCenter(
            _: UNUserNotificationCenter,
            willPresent notification: UNNotification,
            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
        ) {
            logger.info("🔔 前台收到通知：\(notification.request.identifier)")
            // ✅ iOS: 即使在前台也显示横幅和声音
            completionHandler([.banner, .sound, .badge])
        }

        func userNotificationCenter(
            _: UNUserNotificationCenter,
            didReceive response: UNNotificationResponse,
            withCompletionHandler completionHandler: @escaping () -> Void
        ) {
            logger.info("👆 用户点击了通知：\(response.notification.request.identifier)")
            completionHandler()
        }
    }

#elseif os(macOS)

    // MARK: - macOS AppDelegate

    /// macOS 应用代理 - 处理通知相关回调
    class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
        static let shared = AppDelegate()

        override private init() {
            super.init()
            UNUserNotificationCenter.current().delegate = self
        }

        func userNotificationCenter(
            _: UNUserNotificationCenter,
            willPresent notification: UNNotification,
            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
        ) {
            logger.info("🔔 前台收到通知：\(notification.request.identifier)")
            // ✅ macOS: 在前台时不显示（避免自己打扰自己）
            completionHandler([])
        }

        func userNotificationCenter(
            _: UNUserNotificationCenter,
            didReceive response: UNNotificationResponse,
            withCompletionHandler completionHandler: @escaping () -> Void
        ) {
            logger.info("👆 用户点击了通知：\(response.notification.request.identifier)")
            completionHandler()
        }
    }
#endif
