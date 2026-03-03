// UserGuideView.swift
// OpenClaw Deck Swift
//
// 用户指南视图

import SwiftUI

/// 用户指南视图 - 用 WebView 加载 GitHub 文档
struct UserGuideView: View {
    /// GitHub 文档地址（GitHub 会自动渲染 Markdown）
    let githubUrl = "https://github.com/Alex-ai-future/openclaw-deck-swift/blob/main/docs/USER_GUIDE.md"

    var body: some View {
        WebViewDocumentView(
            title: "user_guide".localized,
            githubUrl: githubUrl
        )
    }
}

#Preview {
    UserGuideView()
}
