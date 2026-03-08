// ScrollToBottomButton.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang.
// Copyright © 2026 OpenClaw. All rights reserved.

import os.log
import SwiftUI

private let logger = Logger(subsystem: "com.openclaw.deck", category: "ScrollToBottomButton")

/// 滚动到底部按钮 - 点击后自动滚动到最新消息
struct ScrollToBottomButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.down.message")
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundColor(.blue)
        }
        .buttonStyle(.glass)
        .frame(width: 40, height: 40)
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
