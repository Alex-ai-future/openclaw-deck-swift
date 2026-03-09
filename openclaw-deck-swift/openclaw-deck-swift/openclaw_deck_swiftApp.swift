//
//  openclaw_deck_swiftApp.swift
//  openclaw-deck-swift
//
//  Created by Jihui Huang on 2/23/26.
//

import SwiftUI

@main
struct openclaw_deck_swiftApp: App {
    @StateObject private var languageManager = LanguageManager.shared

    #if os(macOS)
        @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #else
        @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    init() {
        // 请求通知权限
        NotificationService.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, languageManager.currentLocale)
            // ✅ locale 改变时 SwiftUI 会自动刷新，无需强制重建视图
        }
    }
}
