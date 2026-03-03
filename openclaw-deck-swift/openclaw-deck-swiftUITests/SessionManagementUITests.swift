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

    /// 测试：创建多个会话和拖动排序
    func testSessionCreateAndSort() {
        print("📋 开始测试：创建多个会话和拖动排序")

        // 1. 记录初始会话数量和顺序
        var sessionButtons = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'Session'")
        ).allElementsBoundByIndex
        
        let initialCount = sessionButtons.count
        print("  初始会话数：\(initialCount)")

        // 2. 创建 3 个会话（使用默认名称，macOS 限制）
        for i in 1...3 {
            print("  创建第 \(i) 个会话")
            
            // 点击新建会话
            let newSessionButton = app.buttons["NewSessionButton"].firstMatch
            XCTAssertTrue(newSessionButton.exists, "新建会话按钮应该存在")
            newSessionButton.forceTap()
            sleep(1)

            // 验证创建弹窗出现
            let createSheet = app.sheets.firstMatch
            XCTAssertTrue(createSheet.waitForExistence(timeout: 3), "创建会话弹窗应该出现")

            // 验证输入框存在且可以获取焦点（macOS 限制，不实际输入）
            let nameInput = app.textFields.firstMatch
            XCTAssertTrue(nameInput.waitForExistence(timeout: 3), "名称输入框应该存在")
            nameInput.forceTap()
            sleep(1)
            XCTAssertTrue(nameInput.hasFocus, "输入框应该可以获取焦点")
            print("  ✅ 输入框可以获取焦点")

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

        // 3. 验证会话数量增加
        sessionButtons = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'Session'")
        ).allElementsBoundByIndex
        
        let newCount = sessionButtons.count
        XCTAssertEqual(newCount, initialCount + 3, "应该创建 3 个新会话")
        print("  ✅ 会话列表已更新：\(newCount) 个会话")

        // 4. 点击排序按钮
        let sortButton = app.buttons["SortButton"].firstMatch
        XCTAssertTrue(sortButton.waitForExistence(timeout: 5), "排序按钮应该存在")
        sortButton.forceTap()
        sleep(2)
        print("  ✅ 排序按钮已点击")

        // 5. 验证排序视图出现
        let sortSheet = app.sheets.firstMatch
        XCTAssertTrue(sortSheet.waitForExistence(timeout: 5), "排序视图应该出现")
        print("  ✅ 排序视图已出现")

        // 6. 验证拖拽手柄图标存在
        let dragHandles = app.images.matching(
            NSPredicate(format: "identifier == 'line.3.horizontal'")
        )
        XCTAssertGreaterThanOrEqual(dragHandles.count, 3, "应该有至少 3 个拖拽手柄")
        print("  ✅ 拖拽手柄图标存在")

        // 7. 记录排序前顺序
        let beforeSortOrder = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'Session'")
        ).allElementsBoundByIndex.map { $0.identifier }
        print("  排序前顺序：\(beforeSortOrder)")

        // 8. 拖动第一个会话到最后
        sessionButtons = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'Session'")
        ).allElementsBoundByIndex
        
        if sessionButtons.count >= 2 {
            let firstSession = sessionButtons.first!
            let lastSession = sessionButtons.last!
            
            let firstCoord = firstSession.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let lastCoord = lastSession.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            
            firstCoord.press(forDuration: 0.5, thenDragTo: lastCoord)
            sleep(2)
            print("  ✅ 已拖动第一个会话到最后")
        }

        // 9. 验证顺序已改变
        let afterDragOrder = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'Session'")
        ).allElementsBoundByIndex.map { $0.identifier }
        print("  拖动后顺序：\(afterDragOrder)")
        
        XCTAssertNotEqual(beforeSortOrder, afterDragOrder, "顺序应该已改变")
        print("  ✅ 顺序已改变")

        // 10. 点击 Done 保存
        let doneButton = app.buttons["done"].firstMatch.exists
            ? app.buttons["done"].firstMatch
            : app.buttons["Done"].firstMatch
        
        XCTAssertTrue(doneButton.exists, "Done 按钮应该存在")
        doneButton.forceTap()
        sleep(2)
        print("  ✅ 已点击 Done 保存")

        // 11. 验证排序视图已关闭
        XCTAssertFalse(sortSheet.exists, "排序视图应该已关闭")
        print("  ✅ 排序视图已关闭")

        print("✅ testSessionCreateAndSort 通过")
    }

    // MARK: - 删除所有会话测试

    /// 测试：逐个删除所有会话
    func testDeleteAllSessions() {
        print("🗑️  开始测试：逐个删除所有会话")

        // 1. 记录当前会话数量
        var sessionButtons = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'Session'")
        ).allElementsBoundByIndex

        let initialCount = sessionButtons.count
        print("  当前会话数：\(initialCount)")

        // 2. 确保有至少 2 个会话
        if initialCount < 2 {
            print("  会话数不足，先创建 3 个新会话")
            let newSessionButton = app.buttons["NewSessionButton"].firstMatch
            for _ in 1...3 {
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
                }
            }
            
            sessionButtons = app.buttons.matching(
                NSPredicate(format: "identifier CONTAINS 'Session'")
            ).allElementsBoundByIndex
        }

        // 3. 逐个删除所有会话（保留 Welcome 会话）
        var deleteCount = 0
        while sessionButtons.count > 1 && deleteCount < 10 {
            print("  删除第 \(deleteCount + 1) 个会话（剩余：\(sessionButtons.count)）")
            
            // 点击最后一个会话（最新创建的）
            let lastSession = sessionButtons[sessionButtons.count - 1]
            lastSession.forceTap()
            sleep(2)

            // 找到删除按钮
            let deleteButton = app.buttons["deleteSessionButton"].firstMatch
            if deleteButton.waitForExistence(timeout: 5) {
                deleteButton.forceTap()
                sleep(1)

                // 验证确认弹窗
                let deleteAlert = app.alerts.firstMatch
                if deleteAlert.waitForExistence(timeout: 3) {
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

        // 4. 验证最后只剩 1 个 Welcome 会话
        let finalCount = sessionButtons.count
        XCTAssertEqual(finalCount, 1, "应该只剩 1 个 Welcome 会话")
        print("  ✅ 最后剩 \(finalCount) 个会话")

        print("✅ testDeleteAllSessions 通过")
    }
}
