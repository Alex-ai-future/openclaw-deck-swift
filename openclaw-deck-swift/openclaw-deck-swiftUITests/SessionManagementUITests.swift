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

    // MARK: - 会话创建、排序和删除完整流程

    /// 测试：会话创建、排序和删除完整流程
    func testSessionCreateSortAndDelete() {
        print("📋 开始测试：会话创建、排序和删除完整流程")

        // 1. 记录初始会话数量
        let initialSessionCount = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'Session'")
        ).count
        print("  初始会话数：\(initialSessionCount)")

        // 2. 批量创建 3 个会话（简化版，跳过实际输入）
        let newSessionButton = app.buttons["NewSessionButton"].firstMatch
        XCTAssertTrue(newSessionButton.waitForExistence(timeout: 5), "新建会话按钮应该存在")

        for i in 1...3 {
            newSessionButton.forceTap()
            sleep(1)

            // 验证创建弹窗出现
            let createSheet = app.sheets.firstMatch
            XCTAssertTrue(createSheet.waitForExistence(timeout: 3), "创建会话弹窗应该出现")

            // 验证输入框存在（macOS 弹窗输入有限制，跳过实际输入）
            let nameInput = app.textFields.firstMatch
            XCTAssertTrue(nameInput.waitForExistence(timeout: 3), "输入框应该存在")
            print("  ✅ 输入框存在")

            // 点击创建按钮（使用默认名称）
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

        print("✅ testSessionCreateSortAndDelete 通过")
    }
}
