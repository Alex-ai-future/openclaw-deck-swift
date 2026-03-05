// XCUIElement+ForceTap.swift
// OpenClaw Deck Swift
//
// XCUIElement 扩展 - 强制点击

import XCTest

extension XCUIElement {
    /// 强制点击（绕过某些辅助功能限制）
    func forceTap() {
        if self.exists {
            // 使用 coordinate 点击元素中心点
            let coordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            coordinate.tap()
        }
    }

    #if os(macOS)
        /// 通过剪贴板设置文本（仅 macOS）
        func setTextViaPasteboard(_ text: String) {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)

            if self.exists {
                self.forceTap()
                // 模拟 Cmd+V 粘贴
                let app = XCUIApplication()
                app.typeKey("v", modifierFlags: .command)
            }
        }
    #endif
}
