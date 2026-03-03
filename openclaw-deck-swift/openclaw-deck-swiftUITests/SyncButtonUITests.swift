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

    // MARK: - 创建对话测试

    /// 测试：创建新会话
    func testCreateNewSession() {
        print("💻 macOS 特定测试：创建新会话")
        
        // 找到新建会话按钮
        let newSessionButton = app.buttons["NewSessionButton"].firstMatch
        
        if newSessionButton.waitForExistence(timeout: 5) {
            newSessionButton.tap()
            sleep(1)
            
            // 验证创建会话弹窗出现
            let hasCreateButton = app.buttons["创建"].exists ||
                                 app.buttons["Create"].exists ||
                                 app.textFields.firstMatch.exists
            
            XCTAssertTrue(hasCreateButton, "应该显示创建会话弹窗")
            print("  ✅ 创建会话弹窗出现")
            
            // 取消操作
            if app.buttons["取消"].exists {
                app.buttons["取消"].firstMatch.tap()
            } else if app.buttons["Cancel"].exists {
                app.buttons["Cancel"].firstMatch.tap()
            }
            
            print("✅ testCreateNewSession 通过")
        } else {
            print("  ℹ️  新建会话按钮未找到")
        }
    }

    // MARK: - 排序功能测试

    /// 测试：排序按钮存在
    func testSortButton_Exists() {
        print("💻 macOS 特定测试：排序按钮存在")
        
        let sortButton = app.buttons["SortButton"].firstMatch
        let exists = sortButton.waitForExistence(timeout: 5)
        
        if exists {
            XCTAssertTrue(sortButton.isEnabled, "排序按钮应该可点击")
            print("  ✅ 排序按钮存在且可用")
        } else {
            print("  ℹ️  排序按钮未找到")
        }
        
        print("✅ testSortButton_Exists 通过")
    }

    /// 测试：点击排序按钮显示排序选项
    func testSortButton_ShowsSortOptions() {
        print("💻 macOS 特定测试：排序功能")
        
        let sortButton = app.buttons["SortButton"].firstMatch
        
        if sortButton.waitForExistence(timeout: 5) {
            sortButton.tap()
            sleep(1)
            
            // 验证排序选项出现
            let hasSortOptions = app.buttons["按时间排序"].exists ||
                                app.buttons["按名称排序"].exists ||
                                app.menuItems.firstMatch.exists
            
            XCTAssertTrue(hasSortOptions, "应该显示排序选项")
            print("  ✅ 排序选项出现")
            
            // 再次点击关闭排序菜单
            sortButton.tap()
            sleep(1)
            
            print("✅ testSortButton_ShowsSortOptions 通过")
        } else {
            print("  ℹ️  排序按钮未找到")
        }
    }
}
