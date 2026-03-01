// GlobalInputView.swift
// OpenClaw Deck Swift
//
// 全局输入视图组件

import SwiftUI
import os.log

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
      ZStack(alignment: .trailing) {
        TextField("Message", text: $state.inputText, axis: .vertical)
          .font(.body)
          .padding(.horizontal, 14)
          .padding(.vertical, 4)
          .padding(.trailing, 40)
          .lineLimit(..., reservesSpace: false)
          .textFieldStyle(.plain)
          .tint(.accentColor)
          .accessibilityIdentifier("messageInput")
          .focused($isInputFocused)
          .onChange(of: state.inputText) { _, _ in
            state.calculateTextHeight()
          }
          .onSubmit {
            // 发送后收起键盘
            if !state.inputText.isEmpty {
              Task {
                await onSend()
                isInputFocused = false
              }
            }
          }

        // 发送按钮
        if !state.inputText.isEmpty {
          Button {
            Task {
              await onSend()
            }
          } label: {
            Image(systemName: "arrow.up.circle.fill")
              .font(.title2)
              .foregroundStyle(.blue)
          }
          .padding(.trailing, 8)
          .transition(.opacity.combined(with: .scale))
          .accessibilityIdentifier("sendButton")
        }

        // 占位文字
        if state.inputText.isEmpty {
          Text("Message")
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
