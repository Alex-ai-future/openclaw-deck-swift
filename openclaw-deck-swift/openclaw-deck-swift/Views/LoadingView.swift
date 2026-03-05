// LoadingView.swift
// OpenClaw Deck Swift
//
// 通用加载状态视图

import SwiftUI

/// 通用加载视图组件
struct LoadingView: View {
    let stage: LoadingStage
    let progress: Double

    var body: some View {
        VStack(spacing: 24) {
            // 进度指示器
            Group {
                if stage == .ready {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    ProgressView()
                        .scaleEffect(1.5)
                        .transition(.opacity)
                }
            }

            // 主标题
            Text(stage.description)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.3), value: stage.description)

            // 进度条
            if stage != .ready, stage != .idle {
                VStack(spacing: 8) {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 200)
                        .tint(.accentColor)

                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                .transition(.opacity)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.adaptiveBackground)
        .animation(.easeInOut(duration: 0.3), value: stage)
        .animation(.easeInOut(duration: 0.3), value: progress)
    }
}

#if DEBUG
    #Preview {
        Group {
            LoadingView(stage: .initializing, progress: 0.2)
            LoadingView(stage: .loadingSessions, progress: 0.5)
            LoadingView(stage: .connectingToGateway, progress: 0.8)
            LoadingView(stage: .ready, progress: 1.0)
        }
    }
#endif
