// UserGuideView.swift
// OpenClaw Deck Swift
//
// 用户指南视图 - 使用 MarkdownView 渲染纯净文档

import MarkdownView
import SwiftUI

/// 用户指南视图
struct UserGuideView: View {
    /// GitHub raw 文档地址（直接获取 Markdown 内容）
    let rawUrl =
        "https://raw.githubusercontent.com/Alex-ai-future/openclaw-deck-swift/main/docs/USER_GUIDE.md"

    var body: some View {
        NavigationStack {
            MarkdownView(url: URL(string: rawUrl)!)
                .navigationTitle("user_guide".localized)
                .navigationBarTitleDisplayMode(.inline)
                .markdownTheme(.default)
        }
    }
}

#Preview {
    UserGuideView()
}
