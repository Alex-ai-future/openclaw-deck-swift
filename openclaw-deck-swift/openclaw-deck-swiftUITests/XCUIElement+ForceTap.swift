// XCUIElement+ForceTap.swift
// OpenClaw Deck Swift
//
// XCUIElement 扩展 - macOS 强制点击

import XCTest

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

extension XCUIElement {
    /// macOS 强制点击（绕过某些辅助功能限制）
    func forceTap() {
        if self.exists {
            // 使用 coordinate 点击元素中心点
            let coordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            coordinate.tap()
        }
    }

    /// 通过剪贴板设置文本（用于解决某些输入框无法直接输入的问题）
    func setTextViaPasteboard(_ text: String) {
        #if os(macOS)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
        #else
            let pasteboard = UIPasteboard.general
            pasteboard.string = text
        #endif

        if self.exists {
            self.forceTap()
            // 模拟 Cmd+V 粘贴
            let app = XCUIApplication()
            app.typeKey("v", modifierFlags: .command)
        }
    }
}
