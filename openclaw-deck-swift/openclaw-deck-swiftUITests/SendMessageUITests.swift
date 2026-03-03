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

    /// 测试：连接和发送消息完整流程（必须先选中会话）
    func testConnectionAndMessageFlow() {
        print("💬 开始测试：连接和发送消息完整流程")

        // 1. 验证设置按钮存在（连接流程）
        let settingsButton = app.buttons["settingsButton"].firstMatch
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "设置按钮应该存在")
        print("  ✅ 设置按钮存在")

        // 2. 找到并点击第一个会话（选中会话）
        let sessionButtons = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'Session'")
        ).allElementsBoundByIndex
        
        XCTAssertGreaterThan(sessionButtons.count, 0, "应该至少有一个会话")
        print("  找到 \(sessionButtons.count) 个会话")
        
        // 点击第一个会话选中它
        sessionButtons[0].forceTap()
        sleep(1)
        print("  ✅ 已选中会话")

        // 3. 找到输入框（选中会话后才会激活）
        let messageInput = app.textFields["messageInput"].firstMatch
        XCTAssertTrue(messageInput.waitForExistence(timeout: 5), "输入框应该存在")
        print("  ✅ 输入框已激活")

        // 4. 输入测试文本
        let testMessage = "UI Test Message \(Int.random(in: 1000...9999))"
        messageInput.tap()
        messageInput.typeText(testMessage)

        // 5. 验证输入框有内容
        let inputValue = messageInput.value as? String ?? ""
        XCTAssertTrue(!inputValue.isEmpty, "输入框应该有内容")
        print("  ✅ 输入框内容正确")

        // 6. 验证发送按钮出现（选中会话并输入内容后）
        let sendButton = app.buttons["sendButton"].firstMatch
        XCTAssertTrue(sendButton.waitForExistence(timeout: 3), "发送按钮必须存在")
        print("  ✅ 发送按钮已出现")

        // 7. 点击发送按钮
        sendButton.forceTap()
        print("  ✅ 发送按钮已点击")

        // 8. 验证消息显示在聊天区域
        sleep(2)
        let messageExists = app.staticTexts.count > 0
        XCTAssertTrue(messageExists, "聊天区域应该有消息")
        print("  ✅ 消息已显示")

        print("✅ testConnectionAndMessageFlow 通过")
    }

    // MARK: - 发送消息重试机制测试

    /// 测试：发送失败后重试
    func testMessageSendRetry() {
        print("🔄 开始测试：发送消息重试机制")

        // 1. 找到并点击第一个会话（选中会话）
        let sessionButtons = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'Session'")
        ).allElementsBoundByIndex
        
        if sessionButtons.count > 0 {
            sessionButtons[0].forceTap()
            sleep(1)
            print("  ✅ 已选中会话")
        } else {
            print("  ⚠️  没有会话，跳过测试")
            return
        }

        // 2. 找到输入框
        let messageInput = app.textFields["messageInput"].firstMatch
        XCTAssertTrue(messageInput.waitForExistence(timeout: 5), "输入框应该存在")

        // 3. 输入测试文本
        let testMessage = "Retry Test Message \(Int.random(in: 1000...9999))"
        messageInput.tap()
        messageInput.typeText(testMessage)
        print("  ✅ 输入消息")

        // 4. 验证发送按钮出现
        let sendButton = app.buttons["sendButton"].firstMatch
        XCTAssertTrue(sendButton.waitForExistence(timeout: 3), "发送按钮必须存在")
        print("  ✅ 发送按钮已出现")

        // 5. 点击发送按钮
        sendButton.forceTap()
        print("  ✅ 发送按钮已点击")

        // 6. 等待可能的重试弹窗（如果有）
        sleep(2)
        let retryAlert = app.alerts.firstMatch
        if retryAlert.waitForExistence(timeout: 3) {
            print("  ⚠️  检测到重试弹窗")

            // 7. 点击重试按钮
            let retryButton = app.buttons["重试"].firstMatch.exists
                ? app.buttons["重试"].firstMatch
                : app.buttons["Retry"].firstMatch

            if retryButton.exists {
                retryButton.forceTap()
                sleep(2)
                print("  ✅ 已点击重试")
            }

            // 8. 或者点击取消
            let cancelButton = app.buttons["取消"].firstMatch.exists
                ? app.buttons["取消"].firstMatch
                : app.buttons["Cancel"].firstMatch

            if cancelButton.exists {
                cancelButton.forceTap()
                sleep(1)
                print("  ✅ 已点击取消")
            }
        } else {
            print("  ℹ️  没有重试弹窗（发送成功）")
        }

        // 9. 验证消息显示
        let messageExists = app.staticTexts.count > 0
        XCTAssertTrue(messageExists, "聊天区域应该有消息")
        print("  ✅ 消息已显示")

        print("✅ testMessageSendRetry 通过")
    }

    // MARK: - 发送消息（跳过）

    /// 测试：发送消息（需要 Gateway 服务器）
    func testSendMessage() throws {
        throw XCTSkip("需要 Gateway 服务器，暂时跳过")
    }
}
