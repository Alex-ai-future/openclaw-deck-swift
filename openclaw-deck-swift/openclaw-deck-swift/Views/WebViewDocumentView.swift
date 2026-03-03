// WebViewDocumentView.swift
// OpenClaw Deck Swift
//
// 用 WebView 加载 GitHub 文档

import SwiftUI
import WebKit

/// 用 WebView 加载 GitHub 文档视图
struct WebViewDocumentView: View {
    /// 文档标题
    let title: String
    /// GitHub 文档 URL（会自动渲染 Markdown）
    let githubUrl: String

    var body: some View {
        NavigationStack {
            WebViewRepresentable(url: URL(string: githubUrl)!)
                .navigationTitle(title)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
        }
    }
}

/// WebView 的 Representable
struct WebViewRepresentable: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

#if os(macOS)
/// macOS 版本 - 用 NSViewRepresentable
struct WebViewRepresentable: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
#endif

#Preview {
    WebViewDocumentView(
        title: "Preview",
        githubUrl: "https://github.com/Alex-ai-future/openclaw-deck-swift/blob/main/docs/USER_GUIDE.md"
    )
}
