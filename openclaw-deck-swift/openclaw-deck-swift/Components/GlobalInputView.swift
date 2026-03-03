// GlobalInputView.swift
// OpenClaw Deck Swift
//
// 全局输入视图组件

import os.log
import SwiftUI

private let logger = Logger(subsystem: "com.openclaw.deck", category: "GlobalInputView")

/// 全局输入视图
struct GlobalInputView: View {
    @Bindable var state: GlobalInputState
    let onSend: () async -> Void
    @FocusState private var isInputFocused: Bool

    var body: some View {
        HStack(spacing: 16) {
            // 语音按钮
            DictationButton(text: $state.inputText, speechRecognizer: state.speechRecognizer)
                .frame(width: 36, height: 36)

            // 输入框
            ZStack(alignment: .trailing) {
                TextField("message".localized, text: $state.inputText, axis: .vertical)
                    .font(.body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .textFieldStyle(.plain)
                    .tint(.accentColor)
                    .submitLabel(.done)
                    .accessibilityIdentifier("messageInput")
                    .focused($isInputFocused)
                    .onChange(of: state.inputText) { _, _ in
                        state.calculateTextHeight()
                    }
                    .onSubmit {
                        // 有内容时发送
                        if !state.inputText.isEmpty {
                            Task {
                                await onSend()
                            }
                        }
                        // 总是收起键盘
                        isInputFocused = false
                    }

                // 占位文字
                if state.inputText.isEmpty {
                    Text("message".localized)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: state.textHeight)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            state.inputWidth = geometry.size.width
                        }
                        .onChange(of: geometry.size.width) { _, newWidth in
                            state.inputWidth = newWidth
                        }
                }
            )
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .padding(.top, 8)
    }
}

#Preview {
    GlobalInputView(state: GlobalInputState()) {
        print("Send message")
    }
    .padding()
}
