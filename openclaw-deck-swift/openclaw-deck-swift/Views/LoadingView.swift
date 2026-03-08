// LoadingView.swift
// OpenClaw Deck Swift
//
// 通用加载状态视图 - 支持 iOS 和 macOS

import SwiftUI

/// 通用加载视图组件
struct LoadingView: View {
    let appState: AppState
    let viewModel: DeckViewModel?
    let onShowSettings: (() -> Void)?

    /// 内部初始化（主流程使用）
    init(appState: AppState) {
        self.appState = appState
        self.viewModel = nil
        self.onShowSettings = nil
    }

    /// 带工具栏的初始化（ContentView 使用）
    init(appState: AppState, viewModel: DeckViewModel, onShowSettings: @escaping () -> Void) {
        self.appState = appState
        self.viewModel = viewModel
        self.onShowSettings = onShowSettings
    }

    var stage: LoadingStage? {
        appState.loadingStage
    }

    var progress: Double {
        appState.progress
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 进度指示器
                Group {
                    if case .connected = appState {
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
                Text(stage?.title ?? "Loading...")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.3), value: stage?.title)

                // 进度条（连接中状态显示）
                if case .connecting = appState {
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
                if let subtitle = stage?.subtitle {
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
            .toolbar {
                // 使用统一的 DeckToolbar 组件（简化模式：不传右侧按钮 Binding）
                if let viewModel {
                    DeckToolbar(
                        viewModel: viewModel,
                        showingSettings: .constant(false),
                        onShowSettings: onShowSettings,
                        showingNewSessionSheet: nil,
                        showingSortSheet: nil
                    )
                }
            }
        }
    }
}

#if DEBUG
    #Preview {
        Group {
            LoadingView(appState: .connecting(.connecting, 0.2))
            LoadingView(appState: .connecting(.fetchingSessions, 0.5))
            LoadingView(appState: .connecting(.fetchingMessages, 0.8))
            LoadingView(appState: .connecting(.syncingLocal, 1.0))
        }
    }
#endif
