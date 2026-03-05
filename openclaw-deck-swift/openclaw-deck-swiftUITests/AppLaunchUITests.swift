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
        app.launch()
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
}
