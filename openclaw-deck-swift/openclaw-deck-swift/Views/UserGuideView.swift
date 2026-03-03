// UserGuideView.swift
// OpenClaw Deck Swift
//
// 用户指南视图 - 用 Safari 打开 GitHub 文档

import SwiftUI

/// 用户指南视图
struct UserGuideView: View {
    @Environment(\.openURL) private var openURL
    
    /// GitHub 文档地址
    let githubUrl = URL(string: "https://github.com/Alex-ai-future/openclaw-deck-swift/blob/main/docs/USER_GUIDE.md")!

    var body: some View {
        List {
            Section {
                Button("Open User Guide") {
                    openURL(githubUrl)
                }
            } header: {
                Label("user_guide".localized, systemImage: "book")
            } footer: {
                Text("Opens in Safari")
            }
        }
        .navigationTitle("user_guide".localized)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    UserGuideView()
}
