// SessionManagementUITests.swift
// OpenClaw Deck Swift
//
// 会话管理 UI 测试 - 合并后的完整流程测试

import XCTest

@MainActor
final class SessionManagementUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        
        app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "YES"
        app.launchArguments.append("--disable-animations")  // 禁用动画
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

    // MARK: - 完整的会话管理测试流程

    /// 测试：会话管理完整功能流程（合并 3 个测试）
    func testSessionManagementFlow() {
        print("💻 开始测试：会话管理完整流程")
        
        // 1. 验证创建会话按钮并测试创建流程
        let newSessionButton = app.buttons["NewSessionButton"].firstMatch
        
        if newSessionButton.waitForExistence(timeout: 5) {
            newSessionButton.tap()
            
            // 使用 waitForExistence 替代 sleep(1)
            let hasCreateButton = app.buttons["创建"].firstMatch.waitForExistence(timeout: 3) ||
                                 app.buttons["Create"].firstMatch.waitForExistence(timeout: 3) ||
                                 app.textFields.firstMatch.waitForExistence(timeout: 3)
            
            XCTAssertTrue(hasCreateButton, "应该显示创建会话弹窗")
            print("  ✅ 创建会话弹窗出现")
            
            // 取消操作
            let cancelButton = app.buttons["取消"].firstMatch
            let cancelENButton = app.buttons["Cancel"].firstMatch
            
            if cancelButton.exists {
                cancelButton.tap()
            } else if cancelENButton.exists {
                cancelENButton.tap()
            }
        } else {
            print("  ℹ️  新建会话按钮未找到")
        }
        
        // 2. 验证排序按钮存在且可点击
        let sortButton = app.buttons["SortButton"].firstMatch
        XCTAssertTrue(sortButton.waitForExistence(timeout: 5), "排序按钮应该存在")
        XCTAssertTrue(sortButton.isEnabled, "排序按钮应该可点击")
        print("  ✅ 排序按钮存在且可用")
        
        // 3. 点击排序显示选项
        sortButton.tap()
        
        // 使用 waitForExistence 替代 sleep(1)
        let hasSortOptions = app.buttons["按时间排序"].firstMatch.waitForExistence(timeout: 3) ||
                            app.buttons["按名称排序"].firstMatch.waitForExistence(timeout: 3) ||
                            app.menuItems.firstMatch.waitForExistence(timeout: 3)
        
        XCTAssertTrue(hasSortOptions, "应该显示排序选项")
        print("  ✅ 排序选项出现")
        
        // 关闭菜单
        sortButton.tap()
        
        print("✅ testSessionManagementFlow 通过")
    }
}
