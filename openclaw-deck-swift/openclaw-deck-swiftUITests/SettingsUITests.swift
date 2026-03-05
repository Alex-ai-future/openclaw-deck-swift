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

        // 添加 UI 中断处理器
        addUIInterruptionMonitors()

        app.launch()

        // iOS 真机：点击屏幕以触发中断处理器
        app.tap()

        // 强制验证：应用必须在 30 秒内加载
        let mainWindow = app.windows.firstMatch
        XCTAssertTrue(
            mainWindow.waitForExistence(timeout: 1),
            "应用必须在 30 秒内加载完成"
        )
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - Helper Methods

    /// 添加 UI 中断处理器
    private func addUIInterruptionMonitors() {
        // 处理通知权限弹窗
        addUIInterruptionMonitor(withDescription: "NotificationPermission") { alert -> Bool in
            if alert.label.contains("通知") || alert.label.contains("Notifications") {
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

        // 处理其他通用系统弹窗
        addUIInterruptionMonitor(withDescription: "SystemAlerts") { alert -> Bool in
            if alert.buttons.count > 0 {
                alert.buttons.element(boundBy: 0).tap()
                return true
            }
            return false
        }
    }
}
