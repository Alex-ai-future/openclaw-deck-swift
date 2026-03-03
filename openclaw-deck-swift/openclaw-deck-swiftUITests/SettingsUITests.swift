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
        print("  ✅ 设置按钮已点击")

        // 2. 验证设置弹窗出现
        let settingsSheet = app.sheets.firstMatch
        XCTAssertTrue(settingsSheet.waitForExistence(timeout: 5), "设置弹窗应该出现")
        print("  ✅ 设置弹窗已出现")

        // 3. 验证 Gateway URL 输入框可编辑
        let urlInput = app.textFields["gatewayUrl"].firstMatch
        XCTAssertTrue(urlInput.exists, "Gateway URL 输入框应该存在")

        // 保存原始值
        let originalUrl = urlInput.value as? String ?? ""

        // 4. 修改 URL（测试输入）
        urlInput.tap()
        urlInput.typeText("test")
        sleep(1)
        print("  ✅ Gateway URL 输入框可编辑")

        // 5. 验证 Token 输入框可编辑
        let tokenInput = app.secureTextFields["token"].firstMatch
        XCTAssertTrue(tokenInput.exists, "Token 输入框应该存在")
        print("  ✅ Token 输入框存在")

        // 6. 点击取消按钮
        let cancelButton = app.buttons["取消"].firstMatch.exists
            ? app.buttons["取消"].firstMatch
            : app.buttons["Cancel"].firstMatch

        if cancelButton.exists {
            cancelButton.forceTap()
            sleep(1)
            print("  ✅ 取消按钮已点击")
        } else {
            // 如果没有取消按钮，按 ESC 键
            app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
            sleep(1)
            print("  ✅ 使用 ESC 键关闭")
        }

        // 7. 验证弹窗关闭
        XCTAssertFalse(settingsSheet.exists, "弹窗应该已关闭")
        print("  ✅ 弹窗已关闭")

        print("✅ testSettingsCompleteFlow 通过")
    }
}
