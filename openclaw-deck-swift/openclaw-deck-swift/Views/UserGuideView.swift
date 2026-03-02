// UserGuideView.swift
// OpenClaw Deck Swift
//
// 用户指南视图

import SwiftUI

/// 用户指南视图
struct UserGuideView: View {
    /// GitHub raw 文档地址
    let rawUrl = "https://raw.githubusercontent.com/Alex-ai-future/openclaw-deck-swift/main/docs/USER_GUIDE.md"

    var body: some View {
        MarkdownDocumentView(
            title: "user_guide".localized,
            rawUrl: rawUrl
        )
    }
}

#Preview {
    UserGuideView()
}
