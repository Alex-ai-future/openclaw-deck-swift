// UsageExamplesView.swift
// OpenClaw Deck Swift
//
// 使用样例视图 - 用 Safari 打开 GitHub 文档

import SwiftUI

/// 使用样例视图
struct UsageExamplesView: View {
    @Environment(\.openURL) private var openURL
    
    /// GitHub 文档地址
    let githubUrl = URL(string: "https://github.com/Alex-ai-future/openclaw-deck-swift/blob/main/docs/USAGE_EXAMPLES.md")!

    var body: some View {
        List {
            Section {
                Button("Open Usage Examples") {
                    openURL(githubUrl)
                }
            } header: {
                Label("usage_examples".localized, systemImage: "list.bullet")
            } footer: {
                Text("Opens in Safari")
            }
        }
        .navigationTitle("usage_examples".localized)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    UsageExamplesView()
}
