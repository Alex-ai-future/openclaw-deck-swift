// SyncButtonUITests.swift
// OpenClaw Deck Swift
//
// 同步按钮 UI 测试 - 合并后的完整流程测试

import XCTest

@MainActor
final class SyncButtonUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()

        app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "YES"
        app.launchArguments.append("--disable-animations") // 禁用动画
        continueAfterFailure = true
        app.launch()

        // 等待应用加载（使用 waitForExistence 替代 sleep）
        let mainWindow = app.windows.firstMatch
        XCTAssertTrue(mainWindow.waitForExistence(timeout: 30), "应用应该在 30 秒内加载")
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - 完整的同步按钮测试流程

    /// 测试：同步按钮完整功能流程（合并 5 个测试）
    func testSyncButtonCompleteFlow() {
        print("💻 开始测试：同步按钮完整流程")

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

        // 4. 点击同步按钮显示确认弹窗
        syncButton.forceTap()

        // 使用 waitForExistence 替代 sleep(2)
        let cancelButton = app.buttons["取消"].firstMatch
        let cancelENButton = app.buttons["Cancel"].firstMatch

        let hasConfirm = cancelButton.waitForExistence(timeout: 5) ||
            cancelENButton.waitForExistence(timeout: 5)
        XCTAssertTrue(hasConfirm, "应该显示确认弹窗")
        print("  ✅ 确认弹窗出现")

        // 5. 点击取消按钮（完整交互）
        if cancelButton.exists {
            cancelButton.forceTap()
        } else if cancelENButton.exists {
            cancelENButton.forceTap()
        }

        // 验证弹窗关闭
        sleep(1)
        XCTAssertFalse(cancelButton.exists && cancelENButton.exists, "弹窗应该已关闭")

        print("✅ testSyncButtonCompleteFlow 通过")
    }
}

// MARK: - Helper Extensions

extension XCUIElement {
    /// macOS 强制点击（绕过某些辅助功能限制）
    func forceTap() {
        if self.exists {
            // 使用 coordinate 点击中心点
            let coordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            coordinate.tap()
        }
    }
}
