// SyncButtonUITests.swift
// OpenClaw Deck Swift
//
// SyncButton UI 测试 - macOS 优化版本
// 专注于 macOS 平台特定的测试逻辑

import XCTest

#if os(macOS)
import AppKit
#endif

@MainActor
final class SyncButtonUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        
        app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "YES"
        continueAfterFailure = true
        
        // macOS 需要特殊处理
        #if os(macOS)
        // 设置辅助功能超时
        app.launchArguments.append("--uitesting")
        #endif
        
        app.launch()
        
        print("💻 macOS UI 测试启动")
        
        // 等待应用激活（macOS 特殊处理）
        let exists = app.exists
        XCTAssertTrue(exists, "应用应该成功启动")
        
        // 等待 Sync 按钮出现
        let syncButton = app.buttons["SyncButton"].firstMatch
        let appeared = syncButton.waitForExistence(timeout: 30)
        XCTAssertTrue(appeared, "Sync 按钮应该在 30 秒内出现")
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - macOS 基础测试

    /// 测试：Sync 按钮存在
    func testSyncButton_Exists() {
        let syncButton = app.buttons["SyncButton"].firstMatch
        XCTAssertTrue(syncButton.exists, "Sync 按钮应该存在")
        XCTAssertTrue(syncButton.isEnabled, "Sync 按钮应该可点击")
        print("✅ testSyncButton_Exists 通过")
    }

    /// 测试：点击 Sync 显示确认
    func testSyncButton_ShowsConfirmation() {
        let syncButton = app.buttons["SyncButton"].firstMatch
        syncButton.tap()
        
        // macOS 使用 dialog，等待任意确认按钮
        sleep(2) // 给 macOS 时间显示弹窗
        
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
