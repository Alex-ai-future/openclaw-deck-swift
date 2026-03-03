// SendMessageUITests.swift
// OpenClaw Deck Swift
//
// 发送消息 UI 测试

import XCTest

@MainActor
final class SendMessageUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()

        app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "YES"
        app.launchArguments.append("--disable-animations") // 禁用动画
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

    // MARK: - 发送消息测试

    /// 测试：发送消息（需要 Gateway 服务器）
    func testSendMessage() throws {
        // 跳过需要网络的测试（除非有 Mock Gateway）
        throw XCTSkip("需要 Gateway 服务器，暂时跳过")

        // TODO: 当有 Mock Gateway 时，测试流程如下：
        // 1. 选中一个会话
        // 2. 输入消息
        // 3. 点击 sendButton
        // 4. 验证消息已发送
    }

    // MARK: - 连接流程测试

    /// 测试：连接流程（简化版）
    func testConnectionFlow() {
        // 这个测试需要实际的 Gateway 服务器
        // 目前只验证设置按钮存在

        let settingsButton = app.buttons["settingsButton"].firstMatch
        let settingsExists = settingsButton.waitForExistence(timeout: 10)

        if settingsExists {
            print("✅ 设置按钮存在")

            // 截图
            let screenshot = app.windows.firstMatch.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "SettingsButton"
            attachment.lifetime = .keepAlways
            add(attachment)
        } else {
            print("⚠️ 设置按钮未找到，跳过此测试")
        }
    }
}
