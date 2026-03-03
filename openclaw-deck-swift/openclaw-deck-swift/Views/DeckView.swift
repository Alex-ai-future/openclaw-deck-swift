// DeckView.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/24/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import os.log
import SwiftUI

private let logger = Logger(subsystem: "com.openclaw.deck", category: "DeckView")

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

/// Deck 视图 - 多列布局容器（iPad）
struct DeckView: View {
    @Bindable var viewModel: DeckViewModel
    @Binding var showingSettings: Bool
    @Binding var showingNewSessionSheet: Bool
    @State private var selectedSessionId: String?
    @State private var gatewayUrl: String
    @State private var token: String

    /// 内部状态管理
    @State private var showingSortSheet = false

    init(
        viewModel: DeckViewModel, showingSettings: Binding<Bool>, showingNewSessionSheet: Binding<Bool>
    ) {
        self.viewModel = viewModel
        _showingSettings = showingSettings
        _showingNewSessionSheet = showingNewSessionSheet

        // 从 UserDefaults 加载配置
        let storage = UserDefaultsStorage.shared
        _gatewayUrl = State(initialValue: storage.loadGatewayUrl() ?? "ws://127.0.0.1:18789")
        _token = State(initialValue: storage.loadToken() ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Session 列 - 占据剩余空间
                sessionColumns
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 全局输入视图 - 固定在底部
                GlobalInputView(state: viewModel.globalInputState as! GlobalInputState) {
                    await viewModel.sendCurrentInput()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: selectedSessionId) { _, newId in
                // Session 切换时通知 ViewModel
                viewModel.selectSession(newId)

                // 新选中的 Session 标记为已读
                if let sessionId = newId,
                   let session = viewModel.sessions[sessionId]
                {
                    session.hasUnreadMessage = false
                }
            }
            .task {
                // 初始化选中状态：确保 ViewModel 有选中的 Session
                if viewModel.globalInputState.selectedSessionId == nil,
                   let firstSessionId = viewModel.sessionOrder.first
                {
                    viewModel.selectSession(firstSessionId)
                }
                selectedSessionId = viewModel.globalInputState.selectedSessionId
            }
            .toolbar {
                DeckToolbar(
                    viewModel: viewModel,
                    showingSettings: $showingSettings,
                    showingNewSessionSheet: $showingNewSessionSheet,
                    showingSortSheet: $showingSortSheet
                )
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(
                    gatewayUrl: $gatewayUrl,
                    token: $token,
                    isConnected: $viewModel.gatewayConnected,
                    onDisconnect: {
                        viewModel.disconnect()
                        showingSettings = false
                    },
                    onApplyAndReconnect: {
                        UserDefaultsStorage.shared.saveGatewayUrl(gatewayUrl)
                        UserDefaultsStorage.shared.saveToken(token)
                        Task {
                            await viewModel.initialize(url: gatewayUrl, token: token)
                        }
                        showingSettings = false
                    },
                    onConnect: {
                        UserDefaultsStorage.shared.saveGatewayUrl(gatewayUrl)
                        UserDefaultsStorage.shared.saveToken(token)
                        Task {
                            await viewModel.initialize(url: gatewayUrl, token: token)
                        }
                        showingSettings = false
                    },
                    onResetDeviceIdentity: {
                        viewModel.resetDeviceIdentity()
                        Task {
                            await viewModel.initialize(url: gatewayUrl, token: token)
                        }
                        showingSettings = false
                    },
                    onClose: {
                        showingSettings = false
                    },
                    viewModel: viewModel
                )
            }
            .sheet(isPresented: $showingNewSessionSheet) {
                NewSessionSheet(
                    viewModel: viewModel,
                    isPresented: $showingNewSessionSheet
                )
            }
            .sheet(isPresented: $showingSortSheet) {
                SessionSortView(viewModel: viewModel)
            }
            // 消息发送失败弹窗
            .alert("message_send_failed".localized, isPresented: $viewModel.showMessageSendError) {
                Button("cancel".localized, role: .cancel) {}
                Button("retry".localized) {
                    Task {
                        // 1. 先重连 Gateway
                        await viewModel.reconnect()

                        // 2. 等待连接成功（最多 3 秒）
                        var waitCount = 0
                        while !viewModel.gatewayConnected, waitCount < 30 {
                            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 秒
                            waitCount += 1
                        }

                        // 3. 检查连接状态
                        if viewModel.gatewayConnected {
                            // 连接成功，发送消息
                            await viewModel.sendCurrentInput()
                        } else {
                            // 仍然失败，更新错误提示
                            viewModel.messageSendErrorText = "cannot_reconnect_check_settings".localized
                            viewModel.showMessageSendError = true
                        }
                    }
                }
            } message: {
                Text("gateway_not_connected_message".localized)
            }
            // Stop 失败弹窗
            .alert("stop_failed".localized, isPresented: $viewModel.showStopError) {
                Button("ok".localized, role: .cancel) {}
            } message: {
                Text(String(format: "stop_failed_message".localized, viewModel.stopErrorText))
            }
        }
    }

    // MARK: - Session Columns

    private var sessionColumns: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: 0) {
                // Session columns
                ForEach(viewModel.sessionOrder, id: \.self) { sessionId in
                    if let session = viewModel.sessions[sessionId] {
                        SessionColumnView(
                            session: session,
                            viewModel: viewModel,
                            isSelected: sessionId == selectedSessionId,
                            onSelect: {
                                withAnimation {
                                    selectedSessionId = sessionId
                                    // hasUnreadMessage 在 .onChange 中统一处理
                                }
                            },
                            onDelete: {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                                    Task(priority: .background) {
                                        await viewModel.deleteSession(sessionId: sessionId)
                                        await MainActor.run {
                                            if selectedSessionId == sessionId {
                                                selectedSessionId = nil
                                            }
                                        }
                                    }
                                }
                            }
                        )
                        .frame(width: 400)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.75).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            )
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.spring(response: 0.45, dampingFraction: 0.65), value: viewModel.sessionOrder)
            .background(Color.adaptiveBackground)
        }
    }
}

// MARK: - New Session Sheet

struct NewSessionSheet: View {
    @Bindable var viewModel: DeckViewModel
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var name = "default"
    @State private var context = ""
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                // Session Name
                Section {
                    TextField("session_name".localized, text: $name)
                        .focused($isNameFieldFocused)
                        .textContentType(.name)
                        .onSubmit {
                            createSession()
                        }
                } footer: {
                    Text("a_unique_identifier_for_this_session".localized)
                }

                // Notes (Optional)
                Section {
                    TextEditor(text: $context)
                        .font(.body)
                        .frame(minHeight: 80)
                        .scrollContentBackground(.hidden)
                } header: {
                    Text("notes_optional".localized)
                } footer: {
                    Text("additional_context_or_description_for_this_session".localized)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("new_session".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("create".localized) {
                        createSession()
                    }
                    .disabled(name.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
        #if os(macOS)
        .frame(width: 400, height: 400)
        #endif
        .task {
            isNameFieldFocused = true
        }
    }

    private func createSession() {
        _ = viewModel.createSession(name: name, context: context.isEmpty ? nil : context)
        dismiss()
    }
}

#Preview {
    DeckView(
        viewModel: DeckViewModel(),
        showingSettings: .constant(false),
        showingNewSessionSheet: .constant(false)
    )
}
