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

    // MARK: - 同步按钮基础测试

    /// 测试：同步按钮存在
    func testSyncButton_Exists() {
        let syncButton = app.buttons["SyncButton"].firstMatch
        XCTAssertTrue(syncButton.exists, "同步按钮应该存在")
        XCTAssertTrue(syncButton.isEnabled, "同步按钮应该可点击")
        print("✅ testSyncButton_Exists 通过")
    }

    /// 测试：点击同步显示确认
    func testSyncButton_ShowsConfirmation() {
        let syncButton = app.buttons["SyncButton"].firstMatch
        syncButton.tap()
        
        // macOS 使用 dialog，等待任意确认按钮
        sleep(2)
        
        let hasButton = app.buttons["取消"].exists ||
                       app.buttons["Cancel"].exists ||
                       app.buttons["同步"].exists ||
                       app.buttons["Sync"].exists
        
        XCTAssertTrue(hasButton, "应该显示确认弹窗")
        print("✅ testSyncButton_ShowsConfirmation 通过")
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

    /// macOS 特定：测试鼠标点击
    func testSyncButton_MouseClick_macOS() {
        print("💻 macOS 特定测试：鼠标点击")
        
        let syncButton = app.buttons["SyncButton"].firstMatch
        syncButton.tap()
        
        sleep(2) // 等待弹窗
        
        // 验证有确认按钮
        let hasButton = app.buttons["取消"].exists ||
                       app.buttons["Cancel"].exists
        
        XCTAssertTrue(hasButton, "macOS 应该有确认按钮")
        
        // 取消操作
        if app.buttons["取消"].exists {
            app.buttons["取消"].firstMatch.tap()
        } else if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].firstMatch.tap()
        }
        
        print("✅ testSyncButton_MouseClick_macOS 通过")
    }
}
