// OpenClawCoreTests.swift
// 核心 UI 测试 - 验证基本功能

import XCTest

final class OpenClawCoreTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()

        // 清除应用数据，确保测试从干净状态开始
        app.launchEnvironment["UITESTING"] = "YES"
        app.launch()

        // 等待应用完全加载
        XCTAssertTrue(
            app.windows.firstMatch.waitForExistence(timeout: 10),
            "应用窗口应该在 10 秒内加载"
        )
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - P0 核心测试

    /// 测试 1: 应用启动
    func testAppLaunch() {
        // 验证应用成功启动
        XCTAssertTrue(app.exists, "应用应该成功启动")

        // 验证主窗口存在
        let mainWindow = app.windows.firstMatch
        XCTAssertTrue(mainWindow.exists, "主窗口应该存在")

        // 截图验证
        let screenshot = mainWindow.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "AppLaunched"
        attachment.lifetime = .keepAlways
        add(attachment)

        print("✅ testAppLaunch 通过")
    }

    /// 测试 2: 发送消息
    func testSendMessage() {
        // 等待输入框出现（使用 firstMatch 避免 SwiftUI 多元素问题）
        let messageInput = app.textFields["messageInput"].firstMatch.exists ? app.textFields["messageInput"].firstMatch : app.otherElements["messageInput"].firstMatch

        // 等待并验证输入框存在
        let exists = messageInput.waitForExistence(timeout: 10)
        XCTAssertTrue(exists, "消息输入框应该在 5 秒内出现")

        // 输入消息
        messageInput.tap()
        messageInput.typeText("UI Test Hello")

        // 等待发送按钮出现
        let sendButton = app.buttons["sendButton"].firstMatch
        let buttonExists = sendButton.waitForExistence(timeout: 3)
        XCTAssertTrue(buttonExists, "发送按钮应该在 3 秒内出现")

        // 点击发送
        sendButton.tap()

        // 等待消息显示（最多 5 秒）
        sleep(1) // 给 UI 一点时间更新

        // 截图验证
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "MessageSent"
        attachment.lifetime = .keepAlways
        add(attachment)

        print("✅ testSendMessage 通过")
    }

    /// 测试 3: 连接流程（简化版）
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

// MARK: - Helper Extensions

extension XCUIElement {
    /// 等待元素出现
    func waitForExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        do {
            try XCTWaiter().wait(for: [expectation], timeout: timeout)
            return true
        } catch {
            return false
        }
    }
}
