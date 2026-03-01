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

    init() {
        // 请求通知权限
        NotificationService.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, languageManager.currentLocale)
                .id(languageManager.updateID) // 语言改变时强制刷新
        }
    }
}
