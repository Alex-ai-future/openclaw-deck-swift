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

            // 收起键盘按钮（仅 iOS 且键盘弹出时显示）
            #if os(iOS) || os(visionOS)
                if isInputFocused {
                    Button {
                        isInputFocused = false
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .font(.title3)
                    }
                    .buttonStyle(.glass)
                    .frame(width: 36, height: 36)
                }
            #endif

            // 输入框
            // 输入框
            TextField("message".localized, text: $state.inputText, axis: .vertical)
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
                .textFieldStyle(.plain)
                .tint(.accentColor)
                .accessibilityIdentifier("messageInput")
                .accessibilityLabel("message".localized)
                .focused($isInputFocused)
                .onChange(of: state.inputText) { _, _ in
                    state.calculateTextHeight()
                }
                .overlay(
                    Group {
                        if state.inputText.isEmpty {
                            Text("message".localized)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 14)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .leading
                )
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
