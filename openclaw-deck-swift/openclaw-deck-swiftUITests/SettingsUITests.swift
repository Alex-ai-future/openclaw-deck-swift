// SettingsUITests.swift
// OpenClaw Deck Swift
//
// 设置界面 UI 测试 - 强验证版本

import XCTest

@MainActor
final class SettingsUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()

        app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "YES"
        app.launchArguments.append("--disable-animations")
        continueAfterFailure = false // 失败立即停止
        app.launch()

        // 强制验证：应用必须在 30 秒内加载
        let mainWindow = app.windows.firstMatch
        XCTAssertTrue(
            mainWindow.waitForExistence(timeout: 30),
            "应用必须在 30 秒内加载完成"
        )
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - 设置界面完整流程测试

    /// 测试：设置页面完整功能流程
    ///
    /// 流程：
    /// 1. 打开设置页面
    /// 2. 记录原始配置
    /// 3. 修改配置并点击取消 → 验证未保存
    /// 4. 修改配置并点击保存 → 验证已保存
    func testSettingsCompleteFlow() {
        print("⚙️ 开始测试：设置页面完整流程")

        // ========== 阶段 0：打开设置页面 ==========
        print("\n📍 阶段 0：打开设置页面")

        // 验证设置按钮存在
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(
            settingsButton.waitForExistence(timeout: 5),
            "设置按钮 (settingsButton) 必须在 5 秒内出现"
        )
        print("  ✅ 设置按钮存在")

        // 点击设置按钮
        settingsButton.forceTap()

        // 验证设置弹窗打开
        let settingsSheet = app.sheets.firstMatch
        XCTAssertTrue(
            settingsSheet.waitForExistence(timeout: 5),
            "设置弹窗必须在点击设置按钮后 5 秒内打开"
        )
        print("  ✅ 设置弹窗已打开")

        // ========== 阶段 1：记录并修改配置（第一次） ==========
        print("\n📍 阶段 1：记录原始配置并修改")

        // 获取 Gateway URL 输入框
        let gatewayUrlInput = app.textFields["gatewayUrlInput"]
        XCTAssertTrue(
            gatewayUrlInput.waitForExistence(timeout: 3),
            "Gateway URL 输入框 (gatewayUrlInput) 必须存在"
        )
        print("  ✅ Gateway URL 输入框存在")

        // 获取 Token 输入框
        let tokenInput = app.textFields["tokenInput"]
        XCTAssertTrue(
            tokenInput.waitForExistence(timeout: 3),
            "Token 输入框 (tokenInput) 必须存在"
        )
        print("  ✅ Token 输入框存在")

        // 记录原始值
        let originalUrl = gatewayUrlInput.value as? String ?? ""
        let originalToken = tokenInput.value as? String ?? ""
        print("  📝 原始 URL: \(originalUrl)")
        print("  📝 原始 Token: \(originalToken.isEmpty ? "(空)" : "***")")

        // 修改 Gateway URL（使用粘贴板，避免 typeText 超时）
        let testUrl = "ws://test-host:12345"
        setTextViaPasteboard(gatewayUrlInput, text: testUrl)
        print("  ✏️  修改 URL: \(testUrl)")

        // 修改 Token（使用粘贴板）
        let testToken = "test-token-123"
        setTextViaPasteboard(tokenInput, text: testToken)
        print("  ✏️  修改 Token: \(testToken)")

        // 验证按钮出现（修改后按钮文本应为 "connect" 或 "连接"）
        // 使用灵活的查找方式：查找包含 "connect" 或 "连接" 的按钮
        let connectPredicate = NSPredicate(format: "label CONTAINS 'connect' OR label CONTAINS '连接' OR label CONTAINS 'Connect'")
        let applyButton = app.buttons.matching(connectPredicate).firstMatch
        XCTAssertTrue(
            applyButton.waitForExistence(timeout: 3),
            "修改配置后必须显示 'Connect' 或 '连接' 按钮"
        )
        // 调试打印：显示实际找到的按钮信息
        print("  🔍 连接按钮调试信息：")
        print("     - label: '\(applyButton.label)'")
        print("     - identifier: '\(applyButton.identifier)'")
        print("     - exists: \(applyButton.exists)")
        print("  ✅ 连接按钮已显示")

        // ========== 阶段 2：点击取消并验证不保存 ==========
        print("\n📍 阶段 2：点击取消并验证配置未保存")

        // 点击取消按钮
        let cancelButton = app.buttons["Cancel"].firstMatch.exists ? app.buttons["Cancel"] : app.buttons["取消"]
        XCTAssertTrue(
            cancelButton.waitForExistence(timeout: 3),
            "取消按钮必须存在"
        )
        cancelButton.forceTap()

        // 验证弹窗关闭
        XCTAssertFalse(
            settingsSheet.waitForExistence(timeout: 3),
            "点击取消后设置弹窗必须关闭"
        )
        print("  ✅ 设置弹窗已关闭")

        // 重新打开设置页面
        settingsButton.forceTap()
        XCTAssertTrue(
            settingsSheet.waitForExistence(timeout: 5),
            "重新点击设置按钮后弹窗必须打开"
        )
        print("  ✅ 重新打开设置弹窗")

        // 验证 URL 保持原值
        let currentUrl = gatewayUrlInput.value as? String ?? ""
        XCTAssertEqual(
            currentUrl,
            originalUrl,
            "点击取消后 Gateway URL 应该保持原值\n  期望：\(originalUrl)\n  实际：\(currentUrl)"
        )
        print("  ✅ Gateway URL 保持原值")

        // 验证 Token 保持原值
        let currentToken = tokenInput.value as? String ?? ""
        XCTAssertEqual(
            currentToken,
            originalToken,
            "点击取消后 Token 应该保持原值"
        )
        print("  ✅ Token 保持原值")

        // ========== 阶段 3：修改并保存（第二次修改） ==========
        print("\n📍 阶段 3：修改配置并保存")

        // 清空并输入新 URL（使用粘贴板）
        let newUrl = "ws://new-host:99999"
        setTextViaPasteboard(gatewayUrlInput, text: newUrl)
        print("  ✏️  新 URL: \(newUrl)")

        // 清空并输入新 Token（使用粘贴板）
        let newToken = "new-token-999"
        setTextViaPasteboard(tokenInput, text: newToken)
        print("  ✏️  新 Token: \(newToken)")

        // 点击 Done 按钮保存
        let doneButton = app.buttons.matching(NSPredicate(format: "label == 'Done' OR label == '完成' OR label == 'Connect' OR label == '连接'")).firstMatch
        XCTAssertTrue(
            doneButton.waitForExistence(timeout: 3),
            "完成按钮必须存在"
        )
        doneButton.forceTap()

        // 验证弹窗关闭
        XCTAssertFalse(
            settingsSheet.waitForExistence(timeout: 3),
            "点击完成后设置弹窗必须关闭"
        )
        print("  ✅ 设置弹窗已关闭")

        // ========== 阶段 4：验证保存成功 ==========
        print("\n📍 阶段 4：验证配置已保存")

        // 重新打开设置页面
        settingsButton.forceTap()
        XCTAssertTrue(
            settingsSheet.waitForExistence(timeout: 5),
            "重新打开设置弹窗必须成功"
        )
        print("  ✅ 重新打开设置弹窗")

        // 验证 URL 已保存为新值
        let savedUrl = gatewayUrlInput.value as? String ?? ""
        XCTAssertEqual(
            savedUrl,
            newUrl,
            "Gateway URL 应该已保存为新值\n  期望：\(newUrl)\n  实际：\(savedUrl)"
        )
        print("  ✅ Gateway URL 已保存：\(savedUrl)")

        // 验证 Token 已保存为新值
        let savedToken = tokenInput.value as? String ?? ""
        XCTAssertEqual(
            savedToken,
            newToken,
            "Token 应该已保存为新值\n  期望：\(newToken)\n  实际：\(savedToken)"
        )
        print("  ✅ Token 已保存：\(savedToken)")

        // 关闭设置页面
        cancelButton.forceTap()
        XCTAssertFalse(
            settingsSheet.waitForExistence(timeout: 3),
            "关闭设置弹窗必须成功"
        )
        print("  ✅ 设置页面已关闭")

        print("\n✅ testSettingsCompleteFlow 测试通过")
    }

    // MARK: - 辅助方法

    /// 通过 Pasteboard 设置文本（绕过键盘焦点问题）
    private func setTextViaPasteboard(_ element: XCUIElement, text: String) {
        #if os(macOS)
            // macOS 使用 Cmd+A 全选，然后 Cmd+V 粘贴
            element.tap()
            sleep(1)
            app.typeKey("a", modifierFlags: .command)
            sleep(1)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            app.typeKey("v", modifierFlags: .command)
            sleep(1)
        #else
            // iOS 使用右键菜单粘贴
            UIPasteboard.general.string = text
            element.doubleTap()
            sleep(1)
            app.menuItems.matching(
                NSPredicate(format: "label == 'Paste' OR label == '粘贴'")
            ).firstMatch.tap()
            sleep(1)
        #endif
    }
}
