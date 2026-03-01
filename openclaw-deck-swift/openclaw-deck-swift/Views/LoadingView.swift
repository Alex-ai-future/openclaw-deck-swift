// LoadingView.swift
// OpenClaw Deck Swift
//
// 通用加载状态视图 - 支持 iOS 和 macOS

import SwiftUI

/// 通用加载视图组件
public struct LoadingView: View {
    public let stage: LoadingStage
    public let progress: Double

    public init(stage: LoadingStage, progress: Double) {
        self.stage = stage
        self.progress = progress
    }

    public var body: some View {
        VStack(spacing: 24) {
            // 进度指示器
            Group {
                if stage == .idle {
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
            Text(stage.title)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.3), value: stage.title)

            // 进度条（非 idle 状态都显示）
            if stage != .idle {
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

            // 副标题（详细说明）
            if let subtitle = stage.subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
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
            LoadingView(stage: .connecting, progress: 0.2)
            LoadingView(stage: .fetchingSessions, progress: 0.5)
            LoadingView(stage: .fetchingMessages, progress: 0.8)
            LoadingView(stage: .syncingLocal, progress: 1.0)
        }
    }
#endif
