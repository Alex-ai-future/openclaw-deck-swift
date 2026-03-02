// MarkdownDocumentView.swift
// OpenClaw Deck Swift
//
// 通用 Markdown 文档加载组件

import MarkdownUI
import SwiftUI

/// 通用 Markdown 文档视图
struct MarkdownDocumentView: View {
    /// 文档标题
    let title: String
    /// GitHub raw 文档地址
    let rawUrl: String

    @State private var markdownContent: String = ""
    @State private var isLoading: Bool = true
    @State private var error: String? = nil

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("loading_document".localized)
                } else if let error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("failed_to_load_document".localized)
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        Markdown(markdownContent)
                            .padding(.horizontal, 24) // 调小边距
                    }
                }
            }
            .navigationTitle(title)
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
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
    MarkdownDocumentView(
        title: "Preview",
        rawUrl: "https://raw.githubusercontent.com/Alex-ai-future/openclaw-deck-swift/main/docs/USER_GUIDE.md"
    )
}
