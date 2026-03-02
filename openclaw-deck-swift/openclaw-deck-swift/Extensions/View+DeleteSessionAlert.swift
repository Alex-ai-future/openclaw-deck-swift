// View+DeleteSessionAlert.swift
// OpenClaw Deck Swift
//
// 删除 Session 确认弹窗的共用扩展

import SwiftUI

extension View {
    /// 添加删除 Session 确认弹窗
    /// - Parameters:
    ///   - isPresented: 控制弹窗显示的状态
    ///   - onConfirm: 用户确认删除后的回调
    func deleteSessionAlert(isPresented: Binding<Bool>, onConfirm: @escaping () -> Void) -> some View {
        alert("Delete Session?", isPresented: isPresented) {
            Button("cancel".localized, role: .cancel) {}
            Button("delete".localized, role: .destructive) {
                onConfirm()
            }
        } message: {
            Text("this_will_remove_the_session_from_the_deck_messages_are_stored_in_gateway_and_can_be_reloaded".localized)
        }
    }
}
