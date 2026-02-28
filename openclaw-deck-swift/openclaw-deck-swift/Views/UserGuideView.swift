// UserGuideView.swift
// OpenClaw Deck Swift
//
// 用户指南视图 - 使用 WebView 加载 GitHub 文档

import SwiftUI

#if os(iOS)
  import WebKit
#endif

/// 用户指南视图
struct UserGuideView: View {
  // GitHub 文档地址（使用 GitHub 渲染页面，不是 raw 链接）
  let githubUrl =
    "https://github.com/Alex-ai-future/openclaw-deck-swift/blob/main/docs/USER_GUIDE.md"

  var body: some View {
    NavigationStack {
      #if os(iOS)
        WebView(url: URL(string: githubUrl)!)
          .navigationTitle("用户指南")
          .navigationBarTitleDisplayMode(.inline)
      #else
        Text("用户指南 (macOS 即将推出)")
          .navigationTitle("用户指南")
      #endif
    }
  }
}

#if os(iOS)
  // MARK: - WebView

  /// WebView 包装器 - 将 WKWebView 包装成 SwiftUI 视图
  struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
      let webView = WKWebView()
      webView.allowsBackForwardNavigationGestures = true
      return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
      let request = URLRequest(url: url)
      uiView.load(request)
    }
  }
#endif

#Preview {
  UserGuideView()
}
