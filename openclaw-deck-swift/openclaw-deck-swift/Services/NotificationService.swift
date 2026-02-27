// NotificationService.swift
// OpenClaw Deck Swift
//
// 通知服务 - 发送新消息通知

import Foundation
import UserNotifications
import os

private let logger = Logger(subsystem: "com.openclaw.deck", category: "Notification")

class NotificationService {
  static let shared = NotificationService()

  private init() {}

  /// 请求通知权限
  func requestPermission() {
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .sound, .badge]
    ) { granted, error in
      if granted {
        logger.info("✅ 通知权限已授权")
      } else if let error = error {
        logger.error("❌ 通知权限请求失败：\(error.localizedDescription)")
      }
    }
  }

  /// 发送新消息通知
  func sendNewMessageNotification(sessionName: String, messageText: String) {
    // 检查通知权限
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      guard settings.authorizationStatus == .authorized else {
        logger.warning("⚠️ 通知权限未授权，跳过发送")
        return
      }

      // 构建通知内容
      let content = UNMutableNotificationContent()
      content.title = sessionName
      content.body = String(messageText.prefix(200))  // 限制 200 字符
      content.sound = .default

      // 创建通知请求
      let request = UNNotificationRequest(
        identifier: UUID().uuidString,
        content: content,
        trigger: nil  // 立即触发
      )

      // 发送通知
      UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
          logger.error("❌ 通知发送失败：\(error.localizedDescription)")
        } else {
          logger.info("✅ 通知已发送：\(sessionName)")
        }
      }
    }
  }

  /// 检查通知权限状态
  func checkPermission() async -> Bool {
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    return settings.authorizationStatus == .authorized
  }
}
