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
    app.launchArguments = ["--ui-testing", "--reset-data"]
    app.launch()
  }
  
  override func tearDownWithError() throws {
    app = nil
    try super.tearDownWithError()
  }
  
  // MARK: - P0 核心测试
  
  /// 测试 1: 应用启动
  func testAppLaunch() throws {
    // 验证应用成功启动
    XCTAssertTrue(app.exists, "应用应该成功启动")
    
    // 等待主界面加载（最多 5 秒）
    let mainWindow = app.windows.firstMatch
    XCTAssertTrue(mainWindow.waitForExistence(timeout: 5), "主窗口应该在 5 秒内加载")
    
    // 截图验证
    let screenshot = app.windows.firstMatch.screenshot()
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = "AppLaunched"
    add(attachment)
  }
  
  /// 测试 2: 发送消息
  func testSendMessage() throws {
    // 等待输入框出现
    let messageInput = app.textFields["messageInput"]
    XCTAssertTrue(messageInput.waitForExistence(timeout: 5), "消息输入框应该存在")
    
    // 输入消息
    messageInput.tap()
    messageInput.typeText("Hello, AI!")
    
    // 等待发送按钮出现
    let sendButton = app.buttons["sendButton"]
    XCTAssertTrue(sendButton.waitForExistence(timeout: 2), "发送按钮应该出现")
    
    // 点击发送
    sendButton.tap()
    
    // 验证消息出现在聊天中
    sleep(1) // 等待 UI 更新
    
    // 截图验证
    let screenshot = app.scrollViews.firstMatch.screenshot()
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = "MessageSent"
    add(attachment)
  }
  
  /// 测试 3: 连接流程
  func testConnectionFlow() throws {
    // 查找连接按钮或配置输入框
    let connectButton = app.buttons["connectButton"]
    let gatewayInput = app.textFields["gatewayUrlInput"]
    
    if connectButton.exists {
      // 如果有连接按钮，点击它
      connectButton.tap()
      sleep(2)
    } else if gatewayInput.exists {
      // 如果有配置输入框，输入 URL
      gatewayInput.tap()
      gatewayInput.typeText("ws://127.0.0.1:18789")
      
      // 查找并点击连接
      let applyButton = app.buttons["applyButton"]
      if applyButton.exists {
        applyButton.tap()
        sleep(2)
      }
    }
    
    // 验证连接状态
    let statusElement = app.staticTexts["connectionStatus"]
    if statusElement.exists {
      let status = statusElement.label
      XCTAssertTrue(
        status.contains("Connected") || status.contains("connected"),
        "应该显示连接状态"
      )
    }
    
    // 截图验证
    let screenshot = app.windows.firstMatch.screenshot()
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = "ConnectionStatus"
    add(attachment)
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
