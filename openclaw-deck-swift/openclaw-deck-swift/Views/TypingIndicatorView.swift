// TypingIndicatorView.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang.
// Copyright © 2026 OpenClaw. All rights reserved.

import SwiftUI

#if os(iOS) || os(visionOS)
  import UIKit
#else
  import AppKit
#endif

/// iMessage 风格的正在输入指示器
struct TypingIndicatorView: View {
  var body: some View {
    HStack {
      Spacer()
      
      VStack(alignment: .leading, spacing: 8) {
        // 三个跳动的点
        HStack(spacing: 4) {
          ForEach(0..<3, id: \.self) { index in
            Circle()
              .fill(Color.secondary)
              .frame(width: 6, height: 6)
              .animation(
                .easeInOut(duration: 0.6)
                  .repeatForever(autoreverses: true)
                  .delay(Double(index) * 0.15),
                value: index
              )
          }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.adaptiveSecondaryBackground)
        .cornerRadius(18)
        
        Text("正在输入...")
          .font(.caption2)
          .foregroundColor(.secondary)
          .padding(.leading, 4)
      }
      
      Spacer()
    }
  }
}

// MARK: - Preview

#Preview {
  VStack {
    Spacer()
    TypingIndicatorView()
    Spacer()
  }
  .padding()
}
