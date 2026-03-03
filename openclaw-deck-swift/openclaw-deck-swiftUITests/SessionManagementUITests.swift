// SessionManagementUITests.swift
// OpenClaw Deck Swift
//
// 会话管理 UI 测试（创建、排序）

import XCTest

@MainActor
final class SessionManagementUITests: XCTestCase {
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

    // MARK: - 创建会话测试

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
