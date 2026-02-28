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
    self.alert("Delete Session?", isPresented: isPresented) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {
        onConfirm()
      }
    } message: {
      Text(
        "This will remove the session from the deck. Messages are stored in Gateway and can be reloaded."
      )
    }
  }
}
