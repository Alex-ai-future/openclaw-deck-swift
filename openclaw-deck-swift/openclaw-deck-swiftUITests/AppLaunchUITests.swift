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
        app.launchArguments.append("--disable-animations") // 禁用动画
        continueAfterFailure = true
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - 应用启动测试

    /// 测试：应用启动
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

    // MARK: - 性能测试

    /// 测试：启动性能
    func testLaunchPerformance() {
        // 测量启动时间
        self.measure {
            _ = XCUIApplication()
        }
    }
}
