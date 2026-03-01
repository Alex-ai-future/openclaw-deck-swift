// GlobalInputState.swift
// OpenClaw Deck Swift
//
// 全局输入状态 - 唯一实例，管理所有输入相关逻辑

import SwiftUI

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

// MARK: - Protocol

/// GlobalInputState 协议 - 用于依赖注入和测试
protocol GlobalInputStateProtocol {
    var inputText: String { get set }
    var textHeight: CGFloat { get set }
    var selectedSessionId: String? { get set }
    var inputWidth: CGFloat { get set }

    func calculateTextHeight()
    func clearInput()
    func sendMessage(to session: SessionState, viewModel: DeckViewModel) async
}

// MARK: - Implementation

/// 全局输入状态 - 管理所有输入相关状态
@Observable
class GlobalInputState: GlobalInputStateProtocol {
    /// 当前输入文本（全局唯一）
    var inputText: String = ""

    /// 输入框高度
    var textHeight: CGFloat = 36

    /// 语音识别器（全局唯一）
    let speechRecognizer = SpeechRecognizer()

    /// 当前选中的 Session ID
    var selectedSessionId: String?

    /// 是否正在处理输入（避免重复发送）
    private var isSending = false

    /// 输入框实际宽度（用于计算高度）
    var inputWidth: CGFloat = 300

    init() {}

    /// 计算文本高度
    func calculateTextHeight() {
        let text = inputText.isEmpty ? " " : inputText
        let actualInputWidth = max(100, inputWidth - 14 - 40 - 14)

        #if os(macOS)
            let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
            let textStorage = NSTextStorage(string: text)
            let layoutManager = NSLayoutManager()
            let textContainer = NSTextContainer(
                containerSize: CGSize(width: actualInputWidth, height: .greatestFiniteMagnitude)
            )
            layoutManager.addTextContainer(textContainer)
            textStorage.addLayoutManager(layoutManager)
            let rect = layoutManager.usedRect(for: textContainer)
            let height = max(36.0, rect.height + 8)
        #else
            let font = UIFont.preferredFont(forTextStyle: .body)
            let rect = text.boundingRect(
                with: CGSize(width: actualInputWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil
            )
            let height = max(36.0, rect.height + 8)
        #endif

        DispatchQueue.main.async {
            let heightDiff = abs(height - self.textHeight)
            if heightDiff > 5 || self.textHeight == 36 {
                withAnimation(.easeOut(duration: 0.05)) {
                    self.textHeight = height
                }
            } else {
                self.textHeight = height
            }
        }
    }

    /// 清空输入
    func clearInput() {
        inputText = ""
        textHeight = 36
    }

    /// 发送消息
    func sendMessage(to session: SessionState, viewModel: DeckViewModel) async {
        guard !inputText.isEmpty, !isSending else { return }

        isSending = true
        let text = inputText

        // 停止语音识别
        if speechRecognizer.isListening {
            speechRecognizer.stopListening()
        }

        // 清空输入
        clearInput()

        // 调用 Session 的发送接口
        await viewModel.sendMessage(sessionId: session.sessionId, text: text)

        isSending = false
    }
}
