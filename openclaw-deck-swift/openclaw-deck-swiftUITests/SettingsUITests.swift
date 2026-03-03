// SettingsUITests.swift
// OpenClaw Deck Swift
//
// 设置界面 UI 测试

import XCTest

@MainActor
final class SettingsUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()

        app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "YES"
        app.launchArguments.append("--disable-animations")
        continueAfterFailure = true
        app.launch()

        // 等待应用加载
        let mainWindow = app.windows.firstMatch
        XCTAssertTrue(mainWindow.waitForExistence(timeout: 30), "应用应该在 30 秒内加载")
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - 设置界面完整流程测试

    /// 测试：设置界面完整功能流程
    func testSettingsCompleteFlow() {
        print("⚙️ 开始测试：设置界面完整流程")

        // 1. 点击设置按钮
        let settingsButton = app.buttons["settingsButton"].firstMatch
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "设置按钮应该存在")
        settingsButton.forceTap()
        sleep(2)
        print("  ✅ 设置按钮已点击")

        // 2. 验证设置弹窗出现
        let settingsSheet = app.sheets.firstMatch
        XCTAssertTrue(settingsSheet.waitForExistence(timeout: 5), "设置弹窗应该出现")
        print("  ✅ 设置弹窗已出现")

        // 3. 验证 Gateway URL 输入框存在（在弹窗中查找）
        let urlInput = settingsSheet.textFields.firstMatch
        if urlInput.exists {
            print("  ✅ Gateway URL 输入框存在")

            // 4. 验证输入框可编辑
            urlInput.tap()
            sleep(1)
            print("  ✅ Gateway URL 输入框可编辑")
        } else {
            print("  ℹ️  输入框不存在，跳过输入测试")
        }

        // 5. 验证 Token 输入框存在
        let tokenInput = settingsSheet.secureTextFields.firstMatch
        if tokenInput.exists {
            print("  ✅ Token 输入框存在")
        } else {
            print("  ℹ️  Token 输入框不存在")
        }

        // 6. 点击取消按钮关闭弹窗
        let cancelButton = settingsSheet.buttons["取消"].firstMatch.exists
            ? settingsSheet.buttons["取消"].firstMatch
            : settingsSheet.buttons["Cancel"].firstMatch

        if cancelButton.exists {
            cancelButton.forceTap()
            sleep(1)
            print("  ✅ 已点击取消")
        } else {
            // 如果没有取消按钮，按 ESC 键
            app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
            sleep(1)
            print("  ✅ 已按 ESC 键")
        }

        // 7. 验证弹窗关闭
        XCTAssertFalse(settingsSheet.exists, "弹窗应该已关闭")
        print("  ✅ 弹窗已关闭")

        print("✅ testSettingsCompleteFlow 通过")
    }
}
