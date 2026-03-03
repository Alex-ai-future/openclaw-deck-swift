// UsageExamplesView.swift
// OpenClaw Deck Swift
//
// 使用样例视图 - 用 WebView 加载 GitHub 文档

import SwiftUI

/// 使用样例视图
struct UsageExamplesView: View {
    /// GitHub 文档地址（GitHub 会自动渲染 Markdown）
    let githubUrl = "https://github.com/Alex-ai-future/openclaw-deck-swift/blob/main/docs/USAGE_EXAMPLES.md"

    var body: some View {
        WebViewDocumentView(
            title: "usage_examples".localized,
            githubUrl: githubUrl
        )
    }
}

#Preview {
    UsageExamplesView()
}
