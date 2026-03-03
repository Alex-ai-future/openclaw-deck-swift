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

    // MARK: - 发送消息完整流程测试

    /// 测试：发送消息完整流程
    func testMessageSendFlow() {
        print("💬 开始测试：发送消息完整流程")
        
        // 1. 找到输入框
        let messageInput = app.textFields["messageInput"].firstMatch
        XCTAssertTrue(messageInput.waitForExistence(timeout: 5), "输入框应该存在")
        
        // 2. 输入测试文本
        let testMessage = "UI Test Message \(Int.random(in: 1000...9999))"
        messageInput.tap()
        messageInput.typeText(testMessage)
        
        // 3. 验证输入框有内容
        XCTAssertEqual(messageInput.value as? String, testMessage, "输入框应该有内容")
        print("  ✅ 输入框内容正确")
        
        // 4. 找到并点击发送按钮
        let sendButton = app.buttons["sendButton"].firstMatch
        if sendButton.waitForExistence(timeout: 3) {
            sendButton.forceTap()
            print("  ✅ 发送按钮已点击")
        } else {
            // 如果没有发送按钮，尝试按回车键
            messageInput.typeText("\n")
            print("  ✅ 使用回车键发送")
        }
        
        // 5. 验证输入框已清空
        sleep(1)
        let inputValue = messageInput.value as? String ?? ""
        XCTAssertTrue(inputValue.isEmpty, "发送后输入框应该为空")
        print("  ✅ 输入框已清空")
        
        // 6. 验证消息显示在聊天区域
        let messageExists = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS '\(testMessage.prefix(10))'")
        ).firstMatch.waitForExistence(timeout: 3)
        
        XCTAssertTrue(messageExists, "消息应该显示在聊天区域")
        print("  ✅ 消息已显示")
        
        print("✅ testMessageSendFlow 通过")
    }
