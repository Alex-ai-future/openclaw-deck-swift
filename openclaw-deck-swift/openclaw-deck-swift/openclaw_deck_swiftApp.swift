//
//  openclaw_deck_swiftApp.swift
//  openclaw-deck-swift
//
//  Created by Jihui Huang on 2/23/26.
//

import SwiftUI
import UserNotifications

@main
struct openclaw_deck_swiftApp: App {
  init() {
    // 🎯 请求通知权限
    requestNotificationPermission()
  }
  
  private func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .sound, .badge]
    ) { granted, error in
      if granted {
        print("✅ 通知权限已授权")
      } else if let error = error {
        print("❌ 通知权限请求失败：\(error.localizedDescription)")
      }
    }
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
