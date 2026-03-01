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

    @State private var markdownContent: String = ""
    @State private var isLoading: Bool = true
    @State private var error: String? = nil

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("加载用户指南...")
                } else if let error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("加载失败")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        MarkdownView(markdownContent)
                    }
                }
            }
            .navigationTitle("user_guide".localized)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadMarkdown()
            }
        }
    }

    private func loadMarkdown() async {
        isLoading = true
        error = nil

        do {
            let (data, response) = try await URLSession.shared.data(from: URL(string: rawUrl)!)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200
            else {
                throw URLError(.badServerResponse)
            }

            if let content = String(data: data, encoding: .utf8) {
                await MainActor.run {
                    markdownContent = content
                    isLoading = false
                }
            } else {
                throw URLError(.cannotDecodeContentData)
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }
}

#Preview {
    UserGuideView()
}
