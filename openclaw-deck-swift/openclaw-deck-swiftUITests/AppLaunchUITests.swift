// AppLaunchUITests.swift
// OpenClaw Deck Swift
//
// 应用启动 UI 测试

import XCTest

@MainActor
final class AppLaunchUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()

        app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "YES"
        app.launchArguments.append("--disable-animations")
        continueAfterFailure = true
        
        // 添加 UI 中断处理器：自动处理系统权限弹窗
        addUIInterruptionMonitors()
        
        app.launch()
        
        // iOS 真机：点击屏幕以触发中断处理器
        app.tap()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - 应用启动和性能测试

    /// 测试：应用启动和性能
    func testAppLaunchAndPerformance() {
        // 1. 验证应用成功启动
        XCTAssertTrue(app.exists, "应用应该成功启动")

        // 2. 验证主窗口存在
        let mainWindow = app.windows.firstMatch
        XCTAssertTrue(mainWindow.exists, "主窗口应该存在")

        // 3. 截图验证
        let screenshot = mainWindow.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "AppLaunched"
        attachment.lifetime = .keepAlways
        add(attachment)

        print("✅ 应用启动验证通过")

        // 4. 测量启动性能
        self.measure {
            _ = XCUIApplication()
        }

        print("✅ testAppLaunchAndPerformance 通过")
    }

    // MARK: - Helper Methods

    /// 添加 UI 中断处理器
    private func addUIInterruptionMonitors() {
        // 处理通知权限弹窗
        addUIInterruptionMonitor(withDescription: "NotificationPermission") { alert -> Bool in
            if alert.label.contains("通知") || alert.label.contains("Notifications") {
                // 点击"允许"按钮
                let allowButton = alert.buttons.element(boundBy: 0)
                if allowButton.exists {
                    allowButton.tap()
                    return true
                }
            }
            return false
        }

        // 处理本地网络访问权限弹窗
        addUIInterruptionMonitor(withDescription: "LocalNetworkAccess") { alert -> Bool in
            if alert.label.contains("本地网络") || alert.label.contains("Local Network") {
                let allowButton = alert.buttons.element(boundBy: 0)
                if allowButton.exists {
                    allowButton.tap()
                    return true
                }
            }
            return false
        }

        // 处理语音识别权限弹窗
        addUIInterruptionMonitor(withDescription: "SpeechRecognition") { alert -> Bool in
            if alert.label.contains("语音识别") || alert.label.contains("Speech Recognition") {
                let allowButton = alert.buttons.element(boundBy: 0)
                if allowButton.exists {
                    allowButton.tap()
                    return true
                }
            }
            return false
        }

        // 处理其他通用系统弹窗
        addUIInterruptionMonitor(withDescription: "SystemAlerts") { alert -> Bool in
            // 自动点击第一个按钮（通常是"允许"或"好"）
            if alert.buttons.count > 0 {
                alert.buttons.element(boundBy: 0).tap()
                return true
            }
            return false
        }
    }
}
