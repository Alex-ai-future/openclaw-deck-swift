// LoadingView.swift
// OpenClaw Deck Swift
//
// 加载状态视图 - 显示详细的加载进度和阶段

import SwiftUI

struct LoadingView: View {
    let stage: LoadingStage
    let progress: Double

    var body: some View {
        VStack(spacing: 24) {
            // 进度指示器
            Group {
                if stage == .idle {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                } else {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }

            // 状态文本
            Text(stage.description)
                .font(.headline)
                .foregroundColor(.primary)

            // 进度条（如果有进度）
            if stage != .idle, stage != .connecting {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 200)
                    .tint(.accentColor)

                Text("intprogress_100".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 提示信息
            switch stage {
            case .fetchingSessions:
                Text("从_cloudflare_kv_获取会话数据".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            case .fetchingMessages:
                Text("从_gateway_获取消息历史".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            case .syncingLocal:
                Text("保存到本地存储".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            default:
                EmptyView()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.adaptiveBackground)
    }
}

#Preview {
    LoadingView(stage: .fetchingSessions, progress: 0.5)
}
