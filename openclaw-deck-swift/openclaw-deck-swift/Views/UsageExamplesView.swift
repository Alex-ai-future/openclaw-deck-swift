// UsageExamplesView.swift
// OpenClaw Deck Swift
//
// 使用样例视图

import SwiftUI

/// 使用样例视图
struct UsageExamplesView: View {
    /// GitHub raw 文档地址
    let rawUrl = "https://raw.githubusercontent.com/Alex-ai-future/openclaw-deck-swift/main/docs/USAGE_EXAMPLES.md"

    var body: some View {
        MarkdownDocumentView(
            title: "usage_examples".localized,
            rawUrl: rawUrl
        )
    }
}

#Preview {
    UsageExamplesView()
}
