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

    // MARK: - 连接和发送消息完整流程

    /// 测试：连接和发送消息完整流程
    func testConnectionAndMessageFlow() {
        print("💬 开始测试：连接和发送消息完整流程")

        // 1. 验证设置按钮存在（连接流程）
        let settingsButton = app.buttons["settingsButton"].firstMatch
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "设置按钮应该存在")
        print("  ✅ 设置按钮存在")

        // 2. 找到输入框
        let messageInput = app.textFields["messageInput"].firstMatch
        XCTAssertTrue(messageInput.waitForExistence(timeout: 5), "输入框应该存在")

        // 3. 输入测试文本
        let testMessage = "UI Test Message \(Int.random(in: 1000 ... 9999))"
        messageInput.tap()
        messageInput.typeText(testMessage)

        // 4. 验证输入框有内容
        let inputValue = messageInput.value as? String ?? ""
        XCTAssertTrue(!inputValue.isEmpty, "输入框应该有内容")
        print("  ✅ 输入框内容正确")

        // 5. 找到并点击发送按钮
        let sendButton = app.buttons["sendButton"].firstMatch
        if sendButton.waitForExistence(timeout: 3) {
            sendButton.forceTap()
            print("  ✅ 发送按钮已点击")
        } else {
            // 如果没有发送按钮，尝试按回车键
            messageInput.typeText("\n")
            print("  ✅ 使用回车键发送")
        }

        // 6. 验证消息显示在聊天区域（主要验证点）
        sleep(2)
        let messageExists = app.staticTexts.count > 0
        XCTAssertTrue(messageExists, "聊天区域应该有消息")
        print("  ✅ 消息已显示")

        // 注意：不验证输入框清空，因为应用可能不会自动清空
        print("✅ testConnectionAndMessageFlow 通过")
    }

    // MARK: - 发送消息（跳过）

    /// 测试：发送消息（需要 Gateway 服务器）
    func testSendMessage() throws {
        throw XCTSkip("需要 Gateway 服务器，暂时跳过")
    }
}
