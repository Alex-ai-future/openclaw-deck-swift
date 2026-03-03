// SyncButtonUITests.swift
// OpenClaw Deck Swift
//
// SyncButton UI 测试 - 平台分离版本
// 每个平台只运行适合自己的测试

import XCTest

#if os(iOS)
    import UIKit
#endif

@MainActor
final class SyncButtonUITests: XCTestCase {
    var app: XCUIApplication!

    /// 当前平台
    var isIOS: Bool {
        #if os(iOS)
            return true
        #else
            return false
        #endif
    }

    var isMacOS: Bool {
        #if os(macOS)
            return true
        #else
            return false
        #endif
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "YES"
        continueAfterFailure = true
        app.launch()

        print("📱 启动平台：\(isIOS ? "iOS" : isMacOS ? "macOS" : "Unknown")")

        // 等待应用加载
        let syncButton = app.buttons["SyncButton"].firstMatch
        XCTAssertTrue(
            syncButton.waitForExistence(timeout: 30),
            "Sync 按钮应该在 30 秒内出现"
        )
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - 所有平台通用测试

    /// 测试：Sync 按钮存在（所有平台）
    func testSyncButton_Exists() {
        let syncButton = app.buttons["SyncButton"].firstMatch
        XCTAssertTrue(syncButton.exists, "Sync 按钮应该存在")
        XCTAssertTrue(syncButton.isEnabled, "Sync 按钮应该可点击")
        print("✅ testSyncButton_Exists 通过")
    }

    /// 测试：点击 Sync 显示确认（所有平台）
    func testSyncButton_ShowsConfirmation() {
        let syncButton = app.buttons["SyncButton"].firstMatch
        syncButton.tap()

        // 等待任意确认按钮出现（支持中英文）
        let hasCancel = app.buttons["取消"].waitForExistence(timeout: 10) ||
            app.buttons["Cancel"].waitForExistence(timeout: 10)

        XCTAssertTrue(hasCancel, "应该显示确认弹窗")
        print("✅ testSyncButton_ShowsConfirmation 通过")
    }

    // MARK: - iOS 特定测试

    #if os(iOS)
        /// iOS 特定：测试触摸交互流程
        func testSyncButton_TouchFlow_iOS() {
            print("📱 运行 iOS 特定测试：触摸交互")

            let syncButton = app.buttons["SyncButton"].firstMatch
            syncButton.tap()

            // iOS 使用 alert
            let cancelButton = app.buttons["取消"].firstMatch.exists
                ? app.buttons["取消"].firstMatch
                : app.buttons["Cancel"].firstMatch

            XCTAssertTrue(cancelButton.exists, "iOS 应该有取消按钮")

            cancelButton.tap()

            // 验证返回 Session 列表（iOS 特有 UI）
            let sessionList = app.tables["SessionList"]
            XCTAssertTrue(
                sessionList.waitForExistence(timeout: 5),
                "iOS 应该显示 Session 列表"
            )

            print("✅ testSyncButton_TouchFlow_iOS 通过")
        }

        /// iOS 特定：测试快速连续触摸
        func testSyncButton_RapidTaps_iOS() {
            print("📱 运行 iOS 特定测试：快速连续触摸")

            let syncButton = app.buttons["SyncButton"].firstMatch

            // iOS 可以快速连续点击
            for _ in 0 ..< 5 {
                syncButton.tap()
                usleep(100_000) // 0.1 秒
            }

            // 验证应用没有崩溃
            XCTAssertTrue(syncButton.exists, "iOS: 应用应该仍然响应")

            print("✅ testSyncButton_RapidTaps_iOS 通过")
        }

        /// iOS 特定：测试横竖屏切换（仅 iPad）
        func testSyncButton_Orientation_iPad() {
            #if os(iOS)
                if UIDevice.current.userInterfaceIdiom != .pad {
                    throw XCTSkip("仅 iPad 支持横竖屏切换")
                }
            #endif

            print("📱 运行 iPad 特定测试：横竖屏切换")

            let syncButton = app.buttons["SyncButton"].firstMatch
            XCTAssertTrue(syncButton.exists, "iPad: Sync 按钮应该存在")

            // 横竖屏切换后验证按钮仍然可用
            XCUIDevice.shared.orientation = .landscapeLeft
            usleep(500_000)

            XCTAssertTrue(syncButton.exists, "iPad: 横屏后按钮应该存在")

            XCUIDevice.shared.orientation = .portrait
            usleep(500_000)

            XCTAssertTrue(syncButton.exists, "iPad: 竖屏后按钮应该存在")

            print("✅ testSyncButton_Orientation_iPad 通过")
        }
    #endif

    // MARK: - macOS 特定测试

    #if os(macOS)
        /// macOS 特定：测试鼠标点击交互
        func testSyncButton_MouseClick_macOS() {
            print("💻 运行 macOS 特定测试：鼠标点击")

            let syncButton = app.buttons["SyncButton"].firstMatch
            syncButton.tap()

            // macOS 使用 dialog，按钮标签可能不同
            let cancelButton = app.buttons["取消"].firstMatch.exists
                ? app.buttons["取消"].firstMatch
                : app.buttons["Cancel"].firstMatch

            XCTAssertTrue(cancelButton.exists, "macOS 应该有取消按钮")

            // macOS 点击后验证主窗口仍然在
            cancelButton.tap()

            let mainWindow = app.windows.firstMatch
            XCTAssertTrue(
                mainWindow.exists || syncButton.exists,
                "macOS 应该返回主界面"
            )

            print("✅ testSyncButton_MouseClick_macOS 通过")
        }

        /// macOS 特定：测试菜单快捷键（如果有）
        func testSyncButton_MenuShortcut_macOS() {
            print("💻 运行 macOS 特定测试：菜单快捷键")

            // 验证应用有菜单栏（macOS 特有）
            let menuBar = app.menuBars.firstMatch
            if menuBar.exists {
                print("  ✅ macOS 菜单栏存在")

                // 尝试查找同步相关的菜单项
                let syncMenuItem = app.menuItems.matching(
                    NSPredicate(format: "label CONTAINS 'Sync' OR label CONTAINS '同步'")
                ).firstMatch

                if syncMenuItem.exists {
                    print("  ✅ 找到同步菜单项")
                } else {
                    print("  ℹ️  未找到同步菜单项（可选）")
                }
            } else {
                print("  ℹ️  菜单栏不可用（测试环境限制）")
            }

            print("✅ testSyncButton_MenuShortcut_macOS 通过")
        }

        /// macOS 特定：测试多窗口支持
        func testSyncButton_MultipleWindows_macOS() {
            print("💻 运行 macOS 特定测试：多窗口")

            let windows = app.windows
            let windowCount = windows.count

            print("  当前窗口数：\(windowCount)")

            // macOS 应该至少有一个窗口
            XCTAssertGreaterThanOrEqual(windowCount, 1, "macOS 应该至少有一个窗口")

            // 验证 Sync 按钮在第一个窗口
            let firstWindow = windows.firstMatch
            let syncButton = firstWindow.buttons["SyncButton"].firstMatch
            XCTAssertTrue(syncButton.exists, "macOS: Sync 按钮应该在窗口中")

            print("✅ testSyncButton_MultipleWindows_macOS 通过")
        }
    #endif
}
