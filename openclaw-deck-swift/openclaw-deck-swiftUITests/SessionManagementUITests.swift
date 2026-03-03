// SessionManagementUITests.swift
// OpenClaw Deck Swift
//
// 会话管理 UI 测试 - 强验证版本

import XCTest

@MainActor
final class SessionManagementUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()

        app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "YES"
        app.launchArguments.append("--disable-animations")
        continueAfterFailure = false // 失败立即停止
        app.launch()

        print("🚀 应用已启动，等待加载...")

        // 强制验证：应用必须在 30 秒内加载
        let mainWindow = app.windows.firstMatch
        XCTAssertTrue(
            mainWindow.waitForExistence(timeout: 30),
            "应用必须在 30 秒内加载完成"
        )
        print("✅ 主窗口已加载")

        // 等待 2 秒让界面完全渲染
        sleep(2)

        // 检查当前界面状态
        let newSessionButton = app.buttons["NewSessionButton"]
        let settingsButton = app.buttons["settingsButton"]

        if newSessionButton.exists {
            print("✅ 主界面已加载（看到新建会话按钮）")
        } else if settingsButton.exists {
            print("⚠️  可能显示的是欢迎界面，尝试点击设置按钮")
        } else {
            print("⚠️  未检测到主界面按钮，截图诊断...")
            let screenshot = mainWindow.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "诊断截图_启动后"
            add(attachment)
        }
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - 完整会话生命周期测试

    /// 测试：完整会话生命周期
    ///
    /// 流程：
    /// 0. 清理现有会话
    /// 1. 创建三个会话
    /// 2. 每个会话发送消息（触发连接失败）
    /// 3. 记录当前顺序
    /// 4. 排序 - 完全反转
    /// 5. 删除所有新建会话
    func testCompleteSessionLifecycle() {
        print("📋 开始测试：完整会话生命周期")

        // ========== 阶段 0：检查现有会话 ==========
        print("\n📍 阶段 0：检查现有会话")

        let initialSessions = getSessionButtons()
        print("  📊 初始会话数量：\(initialSessions.count)")

        // 测试模式下可能没有预置会话，这是正常的
        // 如果有会话，清理到只剩 0 个
        if initialSessions.count > 0 {
            print("  🗑️  清理 \(initialSessions.count) 个现有会话...")
            while getSessionButtons().count > 0 {
                deleteFirstSession()
            }
            print("  ✅ 清理完成")
        } else {
            print("  ℹ️  没有现有会话（测试模式正常）")
        }

        // ========== 阶段 1：创建三个会话 ==========
        print("\n📍 阶段 1：创建三个会话")

        let sessionNames = [
            ("测试会话 1", "这是第一个测试会话"),
            ("测试会话 2", "这是第二个测试会话"),
            ("测试会话 3", "这是第三个测试会话"),
        ]

        for (index, sessionData) in sessionNames.enumerated() {
            print("  ➕ 创建会话 \(index + 1)/3: \(sessionData.0)")
            createSession(name: sessionData.0, note: sessionData.1)
        }

        // 验证创建了 3 个新会话
        let sessionButtonsAfterCreate = getSessionButtons()
        XCTAssertGreaterThanOrEqual(
            sessionButtonsAfterCreate.count,
            3,
            "创建后应该至少有 3 个会话"
        )
        print("  ✅ 会话创建成功，共 \(sessionButtonsAfterCreate.count) 个会话")

        // ========== 阶段 2：每个会话发送消息（触发连接失败） ==========
        print("\n📍 阶段 2：每个会话发送消息（测试模式会触发连接失败）")

        for index in 0 ..< 3 {
            print("  💬 会话 \(index + 1)/3: 发送测试消息")
            sendMessageToSession(at: index, message: "测试消息 \(index + 1)")
        }

        print("  ✅ 所有会话消息发送完成（连接失败已取消）")

        // ========== 阶段 3：记录当前顺序 ==========
        print("\n📍 阶段 3：记录当前会话顺序")

        let sessionsBeforeSort = getSessionButtons()
        let orderBeforeSort = sessionsBeforeSort.map(\.label)
        print("  📝 原始顺序：\(orderBeforeSort)")

        XCTAssertGreaterThanOrEqual(
            sessionsBeforeSort.count,
            3,
            "排序前应该至少有 3 个会话"
        )

        // ========== 阶段 4：排序 - 完全反转 ==========
        print("\n📍 阶段 4：排序 - 完全反转会话顺序")

        // 点击排序按钮
        let sortButton = app.buttons["SortButton"]
        XCTAssertTrue(
            sortButton.waitForExistence(timeout: 5),
            "排序按钮 (SortButton) 必须存在"
        )
        sortButton.forceTap()
        print("  ✅ 排序按钮已点击")

        // 验证排序弹窗打开
        let sortSheet = app.sheets.firstMatch
        XCTAssertTrue(
            sortSheet.waitForExistence(timeout: 5),
            "排序弹窗必须打开"
        )
        print("  ✅ 排序弹窗已打开")

        // 验证有拖拽手柄
        let dragHandles = app.images.matching(
            NSPredicate(format: "identifier == 'line.3.horizontal'")
        )
        XCTAssertGreaterThanOrEqual(
            dragHandles.count,
            1,
            "排序弹窗中应该有拖拽手柄"
        )
        print("  ✅ 拖拽手柄存在")

        // 反转顺序：将最后一个移到最前面
        reverseSessionOrder()

        // 点击完成按钮
        let doneButton = app.buttons["Done"].firstMatch.exists ? app.buttons["Done"] : app.buttons["完成"]
        XCTAssertTrue(
            doneButton.waitForExistence(timeout: 3),
            "完成按钮必须存在"
        )
        doneButton.forceTap()

        // 验证弹窗关闭
        XCTAssertFalse(
            sortSheet.waitForExistence(timeout: 3),
            "点击完成后排序弹窗必须关闭"
        )
        print("  ✅ 排序完成")

        // 验证顺序已反转
        let sessionsAfterSort = getSessionButtons()
        let orderAfterSort = sessionsAfterSort.map(\.label)
        print("  📝 排序后顺序：\(orderAfterSort)")

        // 验证第一个和最后一个会话已交换
        if orderBeforeSort.count >= 2 {
            XCTAssertEqual(
                orderAfterSort[0],
                orderBeforeSort[orderBeforeSort.count - 1],
                "排序后第一个会话应该是原来的最后一个"
            )
        }
        print("  ✅ 会话顺序已反转")

        // ========== 阶段 5：删除所有新建会话 ==========
        print("\n📍 阶段 5：删除所有新建会话")

        // 删除到只剩 1 个会话
        while true {
            let sessionButtons = getSessionButtons()

            if sessionButtons.count <= 1 {
                print("  ✅ 删除完成，剩余 \(sessionButtons.count) 个会话（系统保留）")
                break
            }

            print("  🗑️  删除会话：\(sessionButtons[0].label)")
            deleteFirstSession()
        }

        // 最终验证（测试模式可能是 0 个）
        let finalSessionCount = getSessionButtons().count
        XCTAssertLessThanOrEqual(
            finalSessionCount,
            1,
            "最终应该最多剩 1 个系统保留会话"
        )
        print("  ✅ 删除完成，剩余 \(finalSessionCount) 个会话")

        print("\n✅ testCompleteSessionLifecycle 测试通过")
    }

    // MARK: - 辅助方法

    /// 获取所有会话按钮
    private func getSessionButtons() -> [XCUIElement] {
        // 排除 NewSessionButton 和 SortButton，查找所有包含 Session 的元素（不限于 Button）
        let predicate = NSPredicate(
            format: "identifier CONTAINS 'Session' AND identifier != 'NewSessionButton' AND identifier != 'SortButton'"
        )
        return app.descendants(matching: .any)
            .matching(predicate)
            .allElementsBoundByIndex
    }

    /// 创建会话
    private func createSession(name: String, note: String) {
        // 点击新建会话按钮
        let newSessionButton = app.buttons["NewSessionButton"]
        XCTAssertTrue(
            newSessionButton.waitForExistence(timeout: 5),
            "新建会话按钮 (NewSessionButton) 必须存在"
        )
        newSessionButton.forceTap()

        // 验证弹窗打开
        let createSheet = app.sheets.firstMatch
        XCTAssertTrue(
            createSheet.waitForExistence(timeout: 3),
            "新建会话弹窗必须打开"
        )

        // 在名称输入框输入
        let nameInput = app.textFields.firstMatch
        XCTAssertTrue(
            nameInput.waitForExistence(timeout: 3),
            "会话名称输入框必须存在"
        )
        nameInput.tap()
        nameInput.typeText(name)

        // 在备注输入框输入
        let noteInput = app.textViews.firstMatch
        if noteInput.exists {
            noteInput.tap()
            noteInput.typeText(note)
        }

        // 点击创建按钮
        let createButton = app.buttons["Create"].firstMatch.exists ? app.buttons["Create"] : app.buttons["创建"]
        XCTAssertTrue(
            createButton.waitForExistence(timeout: 3),
            "创建按钮必须存在"
        )
        createButton.forceTap()

        // 验证弹窗关闭
        XCTAssertFalse(
            createSheet.waitForExistence(timeout: 3),
            "创建后会话弹窗必须关闭"
        )

        // 验证会话出现在列表中
        let sessionButtons = getSessionButtons()
        XCTAssertGreaterThan(
            sessionButtons.count,
            0,
            "创建后会话列表不能为空"
        )
    }

    /// 发送消息到指定会话
    private func sendMessageToSession(at index: Int, message: String) {
        let sessionButtons = getSessionButtons()
        XCTAssertGreaterThan(
            sessionButtons.count,
            index,
            "会话索引 \(index) 超出范围"
        )

        // 点击选中会话
        sessionButtons[index].forceTap()

        // 在消息输入框输入
        let messageInput = app.textFields["messageInput"]
        XCTAssertTrue(
            messageInput.waitForExistence(timeout: 3),
            "消息输入框 (messageInput) 必须存在"
        )
        messageInput.tap()
        messageInput.typeText(message)

        // 点击发送按钮
        let sendButton = app.buttons["sendButton"]
        if sendButton.exists {
            sendButton.forceTap()

            // 验证连接失败弹窗出现（测试模式）
            let alert = app.alerts.firstMatch
            XCTAssertTrue(
                alert.waitForExistence(timeout: 5),
                "测试模式下发送消息应该触发连接失败弹窗"
            )

            // 点击取消
            let cancelButton = app.buttons["Cancel"].firstMatch.exists ? app.buttons["Cancel"] : app.buttons["取消"]
            XCTAssertTrue(
                cancelButton.waitForExistence(timeout: 3),
                "取消按钮必须存在"
            )
            cancelButton.forceTap()

            // 验证弹窗关闭
            XCTAssertFalse(
                alert.waitForExistence(timeout: 3),
                "取消后弹窗必须关闭"
            )
        }
    }

    /// 反转会话顺序（通过拖拽）
    private func reverseSessionOrder() {
        let sessions = getSessionButtons()
        guard sessions.count >= 2 else { return }

        // 简单策略：将最后一个会话拖到最前面
        let lastSession = sessions[sessions.count - 1]
        let firstSession = sessions[0]

        // 找到拖拽手柄
        let dragHandles = app.images.matching(
            NSPredicate(format: "identifier == 'line.3.horizontal'")
        ).allElementsBoundByIndex

        if dragHandles.count >= sessions.count {
            let lastHandle = dragHandles[dragHandles.count - 1]
            let firstHandle = dragHandles[0]

            lastHandle.press(forDuration: 0.5, thenDragTo: firstHandle)
            sleep(1)
        }
    }

    /// 删除第一个会话
    private func deleteFirstSession() {
        let sessionButtons = getSessionButtons()
        guard !sessionButtons.isEmpty else {
            print("  ⚠️  没有会话可删除")
            return
        }

        let sessionName = sessionButtons[0].label
        print("  🗑️  准备删除会话：\(sessionName)")

        // 第一步：点击会话区域（选中会话）
        sessionButtons[0].forceTap()
        print("  ✅ 已选中会话")

        // 等待选中效果
        sleep(1)

        // 第二步：点击 sessionNameButton（打开详情）
        // 调试：打印当前所有按钮
        print("  🔍 当前界面所有按钮：")
        let allButtons = app.buttons.allElementsBoundByIndex
        for (i, button) in allButtons.enumerated() {
            if button.exists {
                print("    [\(i)] identifier=\(button.identifier), label=\(button.label)")
            }
        }

        // 查找顶部的 sessionNameButton
        let nameButton = app.buttons["Session-\(sessionName)"].firstMatch
        XCTAssertTrue(
            nameButton.waitForExistence(timeout: 5),
            "会话名称按钮 (Session-\(sessionName)) 必须在 5 秒内出现"
        )
        nameButton.forceTap()
        print("  ✅ 已点击会话名称按钮")

        // 等待详情页加载
        sleep(1)

        // 第三步：查找删除按钮（可能在底部，需要滚动）
        let deleteButton = app.buttons["deleteSessionButton"]

        // 尝试滚动查找
        if !deleteButton.exists {
            print("  ⚠️  删除按钮未显示，尝试滚动...")
            app.swipeUp(velocity: .slow)
            sleep(1)
        }

        // 验证删除按钮存在
        XCTAssertTrue(
            deleteButton.waitForExistence(timeout: 5),
            "删除按钮 (deleteSessionButton) 必须在 5 秒内出现"
        )
        print("  ✅ 删除按钮已找到")

        // 点击删除按钮
        deleteButton.forceTap()
        print("  ✅ 已点击删除按钮")

        // 确认删除弹窗
        let alert = app.alerts.firstMatch
        XCTAssertTrue(
            alert.waitForExistence(timeout: 3),
            "删除确认弹窗必须出现"
        )
        print("  ✅ 删除确认弹窗已显示")

        let confirmButton = app.buttons["Delete"].firstMatch.exists ? app.buttons["Delete"] : app.buttons["删除"]
        XCTAssertTrue(
            confirmButton.waitForExistence(timeout: 3),
            "删除确认按钮必须存在"
        )
        confirmButton.forceTap()
        print("  ✅ 已确认删除")

        // 验证弹窗关闭
        XCTAssertFalse(
            alert.waitForExistence(timeout: 3),
            "删除后弹窗必须关闭"
        )
        print("  ✅ 删除弹窗已关闭")

        // 等待返回列表
        sleep(1)
    }
}
