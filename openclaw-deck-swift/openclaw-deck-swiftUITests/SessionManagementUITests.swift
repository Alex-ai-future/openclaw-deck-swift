// SessionManagementUITests.swift
// OpenClaw Deck Swift
//
// 会话管理 UI 测试

import XCTest

@MainActor
final class SessionManagementUITests: XCTestCase {
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

    // MARK: - 会话管理基础流程测试

    /// 测试：会话管理基础功能流程
    func testSessionManagementFlow() {
        print("💻 开始测试：会话管理基础流程")

        // 1. 验证创建会话按钮
        let newSessionButton = app.buttons["NewSessionButton"].firstMatch

        if newSessionButton.waitForExistence(timeout: 5) {
            newSessionButton.tap()

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

        print("✅ testSessionManagementFlow 通过")
    }

    // MARK: - 创建会话和排序完整流程测试

    /// 测试：创建会话和排序完整流程
    func testSessionCreateAndSort() {
        print("📋 开始测试：创建会话和排序完整流程")

        // 1. 记录初始会话数量
        let initialSessionCount = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'Session'")
        ).count
        print("  初始会话数：\(initialSessionCount)")

        // 2. 批量创建 3 个会话
        let newSessionButton = app.buttons["NewSessionButton"].firstMatch
        XCTAssertTrue(newSessionButton.waitForExistence(timeout: 5), "新建会话按钮应该存在")

        for i in 1...3 {
            newSessionButton.forceTap()
            sleep(1)

            // 验证创建弹窗出现
            let createSheet = app.sheets.firstMatch
            XCTAssertTrue(createSheet.waitForExistence(timeout: 3), "创建会话弹窗应该出现")

            // 输入会话名称
            let nameInput = app.textFields.firstMatch
            if nameInput.exists {
                let sessionName = "Test Session \(i)"
                nameInput.forceTap()
                sleep(1)
                nameInput.typeText(sessionName)
                print("  ✅ 输入会话名称：\(sessionName)")
            }

            // 点击创建按钮
            let createButton = app.buttons["创建"].firstMatch.exists
                ? app.buttons["创建"].firstMatch
                : app.buttons["Create"].firstMatch

            if createButton.exists {
                createButton.forceTap()
                sleep(2)
            } else {
                app.typeKey(XCUIKeyboardKey.return, modifierFlags: [])
                sleep(2)
            }

            print("  ✅ 会话 \(i) 创建成功")
        }

        // 3. 验证每个会话都出现
        let newSessionCount = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'Session'")
        ).count
        XCTAssertGreaterThanOrEqual(newSessionCount, initialSessionCount + 3, "应该创建 3 个新会话")
        print("  ✅ 会话列表已更新：\(newSessionCount) 个会话")

        // 4. 点击排序按钮
        let sortButton = app.buttons["SortButton"].firstMatch
        XCTAssertTrue(sortButton.waitForExistence(timeout: 5), "排序按钮应该存在")
        sortButton.forceTap()
        sleep(2)
        print("  ✅ 排序按钮已点击")

        // 5. 验证排序视图出现
        let sortSheet = app.sheets.firstMatch
        XCTAssertTrue(sortSheet.waitForExistence(timeout: 5), "排序视图应该出现")

        // 6. 验证拖拽手柄图标存在
        let dragHandles = app.images.matching(
            NSPredicate(format: "identifier == 'line.3.horizontal'")
        )
        XCTAssertGreaterThanOrEqual(dragHandles.count, 1, "应该有拖拽手柄图标")
        print("  ✅ 拖拽手柄图标存在")

        // 7. 验证 Cancel 和 Done 按钮存在
        let cancelButton = app.buttons["cancel"].firstMatch.exists
            ? app.buttons["cancel"].firstMatch
            : app.buttons["Cancel"].firstMatch
        let doneButton = app.buttons["done"].firstMatch.exists
            ? app.buttons["done"].firstMatch
            : app.buttons["Done"].firstMatch

        XCTAssertTrue(cancelButton.exists, "Cancel 按钮应该存在")
        XCTAssertTrue(doneButton.exists, "Done 按钮应该存在")
        print("  ✅ Cancel 和 Done 按钮存在")

        // 8. 点击 Cancel 关闭排序视图
        cancelButton.forceTap()
        sleep(1)
        XCTAssertFalse(sortSheet.exists, "排序视图应该已关闭")
        print("  ✅ 排序视图已关闭")

        // 9. 验证会话列表仍然可用
        let finalSessionCount = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'Session'")
        ).count
        XCTAssertEqual(finalSessionCount, newSessionCount, "会话数量应该不变")
        print("  ✅ 会话列表仍然可用")

        print("✅ testSessionCreateAndSort 通过")
    }

    // MARK: - 删除所有会话测试（必须最后执行）

    /// 测试：删除所有会话
    func testSessionDeleteAll() {
        print("🗑️ 开始测试：删除所有会话")

        // 1. 记录当前会话数量
        var sessionButtons = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'Session'")
        ).allElementsBoundByIndex

        let initialCount = sessionButtons.count
        print("  当前会话数：\(initialCount)")

        // 2. 当会话数量 > 1 时循环删除
        var deleteCount = 0
        while sessionButtons.count > 1 && deleteCount < 10 { // 最多删除 10 次，防止死循环
            // 点击第一个会话的删除按钮
            let deleteButton = sessionButtons[0].buttons["Delete"].firstMatch
            if deleteButton.exists {
                deleteButton.forceTap()
                sleep(1)

                // 验证确认弹窗出现
                let deleteAlert = app.alerts.firstMatch
                if deleteAlert.waitForExistence(timeout: 3) {
                    // 点击确认删除
                    let confirmButton = app.buttons["delete"].firstMatch.exists
                        ? app.buttons["delete"].firstMatch
                        : app.buttons["Delete"].firstMatch

                    if confirmButton.exists {
                        confirmButton.forceTap()
                        sleep(2)
                        deleteCount += 1
                        print("  ✅ 已删除 \(deleteCount) 个会话")
                    }
                }
            }

            // 重新获取会话列表
            sessionButtons = app.buttons.matching(
                NSPredicate(format: "identifier CONTAINS 'Session'")
            ).allElementsBoundByIndex
        }

        // 3. 验证最后剩 1 个 Welcome 会话
        let finalCount = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'Session'")
        ).count

        XCTAssertEqual(finalCount, 1, "应该只剩 1 个 Welcome 会话")
        print("  ✅ 最后剩 \(finalCount) 个会话")

        print("✅ testSessionDeleteAll 通过")
    }
}
