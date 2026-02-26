// ScrollToBottomButton.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang.
// Copyright © 2026 OpenClaw. All rights reserved.

import SwiftUI

/// 滚动到底部按钮 - 点击后自动滚动到最新消息
struct ScrollToBottomButton: View {
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      Image(systemName: "arrow.down.circle")
        .font(.title3)
        .foregroundColor(.blue)
    }
    .buttonStyle(.glass)
    .frame(width: 36, height: 36)
    .contentShape(Rectangle())
  }
}

// MARK: - Preview

#Preview {
  HStack {
    Spacer()
    ScrollToBottomButton {
      print("Scroll to bottom tapped")
    }
  }
  .padding()
}
