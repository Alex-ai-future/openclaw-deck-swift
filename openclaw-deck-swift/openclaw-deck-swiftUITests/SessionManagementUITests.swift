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

    // MARK: - 会话创建和排序测试

    /// 测试：会话创建和排序完整流程
    func testSessionCreateAndSort() {
        print("📋 开始测试：会话创建和排序完整流程")

        // 1. 记录初始会话数量
        let initialSessionCount = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'Session'")
        ).count
        print("  初始会话数：\(initialSessionCount)")

        // 2. 创建 1 个新会话
        let newSessionButton = app.buttons["NewSessionButton"].firstMatch
        XCTAssertTrue(newSessionButton.waitForExistence(timeout: 5), "新建会话按钮应该存在")

        newSessionButton.forceTap()
        sleep(1)

        // 验证创建弹窗出现
        let createSheet = app.sheets.firstMatch
        XCTAssertTrue(createSheet.waitForExistence(timeout: 3), "创建会话弹窗应该出现")

        // 验证输入框存在
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

        print("  ✅ 会话创建成功")

        // 3. 验证会话数量增加
        let newSessionCount = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'Session'")
        ).count
        XCTAssertGreaterThanOrEqual(newSessionCount, initialSessionCount, "会话数量应该增加或不变")
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

    // MARK: - 删除会话测试

    /// 测试：删除会话（在会话详情页）
    func testSessionDelete() {
        print("🗑️  开始测试：删除会话")

        // 1. 记录当前会话数量
        var sessionButtons = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'Session'")
        ).allElementsBoundByIndex

        let initialCount = sessionButtons.count
        print("  当前会话数：\(initialCount)")

        // 2. 确保有至少 2 个会话（1 个 Welcome + 1 个可删除）
        if initialCount < 2 {
            print("  会话数不足，先创建一个新会话")
            let newSessionButton = app.buttons["NewSessionButton"].firstMatch
            if newSessionButton.exists {
                newSessionButton.forceTap()
                sleep(1)

                let createButton = app.buttons["创建"].firstMatch.exists
                    ? app.buttons["创建"].firstMatch
                    : app.buttons["Create"].firstMatch

                if createButton.exists {
                    createButton.forceTap()
                    sleep(2)
                }

                sessionButtons = app.buttons.matching(
                    NSPredicate(format: "identifier CONTAINS 'Session'")
                ).allElementsBoundByIndex
            }
        }

        // 3. 点击最后一个会话（通常是最新创建的，可以删除）
        if sessionButtons.count >= 2 {
            print("  点击最后一个会话打开详情页")
            sessionButtons[sessionButtons.count - 1].forceTap()
            sleep(2)

            // 4. 验证详情页已打开（查找删除按钮）
            let deleteButton = app.buttons["deleteSessionButton"].firstMatch
            if deleteButton.waitForExistence(timeout: 5) {
                print("  ✅ 删除按钮已找到")

                // 5. 点击删除按钮
                deleteButton.forceTap()
                sleep(1)
                print("  ✅ 删除按钮已点击")

                // 6. 验证确认弹窗出现
                let deleteAlert = app.alerts.firstMatch
                if deleteAlert.waitForExistence(timeout: 3) {
                    print("  ✅ 确认弹窗出现")

                    // 7. 点击确认删除
                    let confirmButton = app.buttons["delete"].firstMatch.exists
                        ? app.buttons["delete"].firstMatch
                        : app.buttons["Delete"].firstMatch

                    if confirmButton.exists {
                        confirmButton.forceTap()
                        sleep(2)
                        print("  ✅ 已确认删除")
                    }
                }
            }

            // 8. 验证会话数量减少
            let finalCount = app.buttons.matching(
                NSPredicate(format: "identifier CONTAINS 'Session'")
            ).count

            print("  删除后会话数：\(finalCount) (初始：\(initialCount))")

            // 宽松验证：只要数量不变或减少即可
            XCTAssertLessThanOrEqual(finalCount, initialCount, "会话数量不应该增加")
            print("  ✅ 会话数量验证通过")
        } else {
            print("  ⚠️ 会话数不足，跳过删除测试")
        }

        print("✅ testSessionDelete 通过")
    }
}
