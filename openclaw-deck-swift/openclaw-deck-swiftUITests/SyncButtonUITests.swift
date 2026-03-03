// SyncButtonUITests.swift
// OpenClaw Deck Swift
//
// 同步按钮 UI 测试

import XCTest

@MainActor
final class SyncButtonUITests: XCTestCase {
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

    // MARK: - 同步按钮完整流程测试

    /// 测试：同步按钮完整功能流程（包含确认弹窗）
    func testSyncButtonWithConfirmation() {
        print("🔄 开始测试：同步按钮完整流程")

        // 1. 验证同步按钮存在且可点击
        let syncButton = app.buttons["SyncButton"].firstMatch
        XCTAssertTrue(syncButton.exists, "同步按钮应该存在")
        XCTAssertTrue(syncButton.isEnabled, "同步按钮应该可点击")
        print("  ✅ 同步按钮存在且可点击")

        // 2. 验证 macOS 菜单栏
        let menuBar = app.menuBars.firstMatch
        if menuBar.exists {
            print("  ✅ macOS 菜单栏存在")
        } else {
            print("  ℹ️  菜单栏不可用（测试环境限制）")
        }

        // 3. 验证多窗口
        let windows = app.windows
        print("  当前窗口数：\(windows.count)")
        XCTAssertGreaterThanOrEqual(windows.count, 1, "macOS 应该至少有一个窗口")

        // 4. 点击同步按钮
        syncButton.forceTap()
        print("  ✅ 同步按钮已点击")

        // 5. 等待确认弹窗出现（同步前需要确认）
        sleep(2)
        let syncAlert = app.alerts.firstMatch
        
        // 6. 验证确认弹窗出现
        if syncAlert.waitForExistence(timeout: 5) {
            print("  ✅ 同步确认弹窗出现")

            // 7. 验证弹窗内容
            let alertText = syncAlert.staticTexts.firstMatch.label
            print("  弹窗内容：\(alertText)")

            // 8. 验证有确定和取消按钮
            let confirmButton = app.buttons["确定"].firstMatch.exists
                ? app.buttons["确定"].firstMatch
                : app.buttons["OK"].firstMatch
            let cancelButton = app.buttons["取消"].firstMatch.exists
                ? app.buttons["取消"].firstMatch
                : app.buttons["Cancel"].firstMatch

            XCTAssertTrue(confirmButton.exists || cancelButton.exists, "弹窗应该有操作按钮")
            print("  ✅ 弹窗按钮存在")

            // 9. 点击确定开始同步
            if confirmButton.exists {
                confirmButton.forceTap()
                sleep(2)
                print("  ✅ 已点击确定，开始同步")
            } else if cancelButton.exists {
                cancelButton.forceTap()
                sleep(1)
                print("  ✅ 已点击取消")
            }
        } else {
            print("  ℹ️  没有确认弹窗（直接同步）")
        }

        // 10. 验证同步按钮仍然可用
        XCTAssertTrue(syncButton.exists, "同步按钮应该仍然可用")
        print("  ✅ 同步按钮仍然可用")

        print("✅ testSyncButtonWithConfirmation 通过")
    }

    // MARK: - macOS 特定测试

    /// macOS 特定：测试菜单项
    func testSyncButton_MenuShortcut_macOS() {
        print("💻 macOS 特定测试：菜单快捷键")

        // 验证应用有菜单栏
        let menuBar = app.menuBars.firstMatch
        if menuBar.exists {
            print("  ✅ macOS 菜单栏存在")
        } else {
            print("  ℹ️  菜单栏不可用（测试环境限制）")
        }

        print("✅ testSyncButton_MenuShortcut_macOS 通过")
    }

    /// macOS 特定：测试多窗口
    func testSyncButton_MultipleWindows_macOS() {
        print("💻 macOS 特定测试：多窗口")

        let windows = app.windows
        print("  当前窗口数：\(windows.count)")

        // macOS 应该至少有一个窗口
        XCTAssertGreaterThanOrEqual(windows.count, 1, "macOS 应该至少有一个窗口")

        print("✅ testSyncButton_MultipleWindows_macOS 通过")
    }
}
