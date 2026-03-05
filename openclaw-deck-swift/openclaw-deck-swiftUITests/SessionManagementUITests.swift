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

        // 添加 UI 中断处理器
        addUIInterruptionMonitors()

        app.launch()
        app.activate() // ✅ 显式激活应用到前台

        // iOS 真机：点击屏幕以触发中断处理器
        app.tap()

        print("🚀 应用已启动，等待加载...")

        // 强制验证：应用必须在 30 秒内加载
        let mainWindow = app.windows.firstMatch
        XCTAssertTrue(
            mainWindow.waitForExistence(timeout: 1),
            "应用必须在 30 秒内加载完成"
        )
        print("✅ 主窗口已加载")

        // 等待 2 秒让界面完全渲染
        sleep(1)

        // 检查当前界面状态
        let newSessionButton = app.buttons["NewSessionButton"].firstMatch
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

    // MARK: - Helper Methods

    /// 添加 UI 中断处理器
    private func addUIInterruptionMonitors() {
        // 处理通知权限弹窗
        addUIInterruptionMonitor(withDescription: "NotificationPermission") { alert -> Bool in
            if alert.label.contains("通知") || alert.label.contains("Notifications") {
                let allowButton = alert.buttons.element(boundBy: 0)
                if allowButton.exists {
                    allowButton.tap()
                    return true
                }
            }
            return false
        }

        // 处理本地网络访问权限弹窗
        addUIInterruptionMonitor(withDescription: "LocalNetworkAccess") { alert -> Bool in
            if alert.label.contains("本地网络") || alert.label.contains("Local Network") {
                let allowButton = alert.buttons.element(boundBy: 0)
                if allowButton.exists {
                    allowButton.tap()
                    return true
                }
            }
            return false
        }

        // 处理其他通用系统弹窗
        addUIInterruptionMonitor(withDescription: "SystemAlerts") { alert -> Bool in
            if alert.buttons.count > 0 {
                alert.buttons.element(boundBy: 0).tap()
                return true
            }
            return false
        }
    }

    // MARK: - 完整会话生命周期测试

    /// 测试：完整会话生命周期
    func testCompleteSessionLifecycle() {
        print("📋 开始测试：完整会话生命周期")

        // ========== 阶段 0：检查现有会话 ==========
        print("\n📍 阶段 0：检查现有会话")

        let initialSessions = getSessionButtons()
        print("  📊 初始会话数量：\(initialSessions.count)")

        // 测试模式下可能没有预置会话，这是正常的
        // 如果有会话，清理到只剩 1 个（保留 main 会话）
        if initialSessions.count > 1 {
            print("  🗑️  清理现有会话，保留 main 会话...")
            // 只删除到剩 1 个会话（main 会话）
            while getSessionButtons().count > 1 {
                deleteFirstSession()
            }
            print("  ✅ 清理完成，剩余 1 个会话（main）")
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

        // ========== 阶段 3：记录当前会话顺序 ==========
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
        let sortButton = app.buttons["SortButton"].firstMatch
        XCTAssertTrue(
            sortButton.waitForExistence(timeout: 1),
            "排序按钮 (SortButton) 必须存在"
        )
        sortButton.forceTap()
        print("  ✅ 排序按钮已点击")

        // 验证排序弹窗打开
        let sortSheet = app.sheets.firstMatch
        XCTAssertTrue(
            sortSheet.waitForExistence(timeout: 1),
            "排序弹窗必须打开"
        )
        print("  ✅ 排序弹窗已打开")

        // 注意：不验证拖拽手柄（SwiftUI 系统渲染，无法设置 accessibility identifier）
        // 测试重点放在排序功能本身（拖拽、顺序反转）

        // 反转顺序：将最后一个移到最前面（只有多个会话时才执行）
        if sessionsBeforeSort.count > 1 {
            reverseSessionOrder()

            // 点击完成按钮
            let doneButton =
                app.buttons["Done"].firstMatch.exists ? app.buttons["Done"] : app.buttons["完成"]
            XCTAssertTrue(
                doneButton.waitForExistence(timeout: 1),
                "完成按钮必须存在"
            )
            doneButton.forceTap()

            // 验证弹窗关闭
            XCTAssertFalse(
                sortSheet.waitForExistence(timeout: 1),
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
        } else {
            print("  ⚠️  只有 1 个会话，跳过排序操作")
            // 直接点击完成按钮关闭弹窗
            let doneButton =
                app.buttons["Done"].firstMatch.exists ? app.buttons["Done"] : app.buttons["完成"]
            XCTAssertTrue(
                doneButton.waitForExistence(timeout: 1),
                "完成按钮必须存在"
            )
            doneButton.forceTap()
            print("  ✅ 已关闭排序弹窗")
        }

        // ========== 阶段 5：删除所有新建会话 ==========
        print("\n📍 阶段 5：删除所有新建会话")

        // 先记录初始数量，只删除固定次数（避免无限循环）
        let sessionButtons = getSessionButtons()
        let initialCount = sessionButtons.count

        if initialCount > 1 {
            // 只删除 (initialCount - 1) 次，保留 1 个
            let deleteCount = initialCount - 1
            for i in 0 ..< deleteCount {
                print("  🗑️  删除会话 \(i + 1)/\(deleteCount)")
                deleteFirstSession()
                sleep(1) // 等待 UI 更新
            }
            print("  ✅ 删除完成，剩余 1 个会话（main）")
        } else {
            print("  ⚠️  只有 \(initialCount) 个会话，跳过删除")
        }
        let finalSessionCount = getSessionButtons().count
        print("  ✅ 删除完成，剩余 \(finalSessionCount) 个会话（main）")

        print("\n✅ testCompleteSessionLifecycle 测试通过")
    }

    // MARK: - 辅助方法

    /// 通过 Pasteboard 设置文本（绕过键盘焦点问题）
    private func setTextViaPasteboard(_ element: XCUIElement, text: String) {
        #if os(macOS)
            // macOS 使用 Cmd+A 全选，然后 Cmd+V 粘贴
            element.tap()
            sleep(1)
            app.typeKey("a", modifierFlags: .command)
            sleep(1)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            app.typeKey("v", modifierFlags: .command)
            sleep(1)
        #else
            // iOS 使用右键菜单粘贴
            UIPasteboard.general.string = text
            element.doubleTap()
            sleep(1)
            app.menuItems.matching(
                NSPredicate(format: "label == 'Paste' OR label == '粘贴'")
            ).firstMatch.tap()
            sleep(1)
        #endif
    }

    /// 获取所有会话按钮
    private func getSessionButtons() -> [XCUIElement] {
        // 排除 NewSessionButton 和 SortButton，查找所有包含 Session 的元素（不限于 Button）
        let predicate = NSPredicate(
            format:
            "identifier CONTAINS 'SessionView' AND identifier != 'NewSessionButton' AND identifier != 'SortButton'"
        )
        return app.descendants(matching: .any)
            .matching(predicate)
            .allElementsBoundByIndex
    }

    /// 创建会话
    private func createSession(name: String, note: String) {
        // 点击新建会话按钮
        let newSessionButton = app.buttons["NewSessionButton"].firstMatch
        XCTAssertTrue(
            newSessionButton.waitForExistence(timeout: 1),
            "新建会话按钮 (NewSessionButton) 必须存在"
        )
        newSessionButton.forceTap()

        // 验证弹窗打开（增加等待时间，iPadOS 可能较慢）
        sleep(2) // 等待弹窗动画

        // 尝试多种弹窗类型（iPadOS 可能是 Dialog 或 Sheet）
        let createSheet = app.sheets.firstMatch
        let createDialog = app.dialogs.firstMatch

        if createSheet.exists {
            print("  ✅ 新建会话弹窗已打开（Sheet）")
        } else if createDialog.exists {
            print("  ✅ 新建会话弹窗已打开（Dialog）")
        } else {
            // 截图诊断
            print("  ⚠️  弹窗未打开，截图诊断...")
            let screenshot = app.windows.firstMatch.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "创建会话弹窗诊断"
            attachment.lifetime = .keepAlways
            add(attachment)

            // 打印所有可用元素
            print("  🔍 当前所有 Sheets: \(app.sheets.allElementsBoundByIndex.count)")
            print("  🔍 当前所有 Dialogs: \(app.dialogs.allElementsBoundByIndex.count)")
            print("  🔍 当前所有 Alerts: \(app.alerts.allElementsBoundByIndex.count)")
        }

        XCTAssertTrue(
            createSheet.waitForExistence(timeout: 3) || createDialog.waitForExistence(timeout: 3),
            "新建会话弹窗必须打开（Sheet 或 Dialog）"
        )

        // 在名称输入框输入
        let nameInput = app.textFields.firstMatch
        XCTAssertTrue(
            nameInput.waitForExistence(timeout: 1),
            "会话名称输入框必须存在"
        )
        setTextViaPasteboard(nameInput, text: name)

        // 在备注输入框输入
        let noteInput = app.textViews.firstMatch
        if noteInput.exists {
            setTextViaPasteboard(noteInput, text: note)
        }

        // 点击创建按钮
        let createButton =
            app.buttons["Create"].firstMatch.exists ? app.buttons["Create"] : app.buttons["创建"]
        XCTAssertTrue(
            createButton.waitForExistence(timeout: 1),
            "创建按钮必须存在"
        )
        createButton.forceTap()

        // 验证弹窗关闭
        XCTAssertFalse(
            createSheet.waitForExistence(timeout: 1),
            "创建后会话弹窗必须关闭"
        )

        // 等待 UI 完全更新（会话列表刷新）
        sleep(1)

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
        sleep(1)

        // 在消息输入框输入
        let messageInput = app.textFields["messageInput"]
        XCTAssertTrue(
            messageInput.waitForExistence(timeout: 1),
            "消息输入框 (messageInput) 必须存在"
        )

        // 点击输入框并等待获得焦点
        messageInput.tap()
        sleep(1) // 增加等待时间

        // 调试打印
        print("  🔍 消息输入框：label='\(messageInput.label)', identifier='\(messageInput.identifier)'")
        setTextViaPasteboard(messageInput, text: message)

        // 点击发送按钮
        let sendButton = app.buttons["sendButton"]
        if sendButton.exists {
            sendButton.forceTap()

            // 等待并关闭连接错误弹窗
            sleep(1)
            let alert = app.alerts.firstMatch
            if alert.waitForExistence(timeout: 1) {
                // 弹窗只有一个"确定"按钮
                let okButton = app.buttons["ok"].firstMatch.exists ?
                    app.buttons["ok"] : app.buttons["确定"]
                if okButton.exists {
                    okButton.forceTap()
                    sleep(1)
                    print("  ✅ 连接错误弹窗已关闭")
                }
            }
            print("  ✅ 消息发送流程完成")
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

        // 从 identifier 中提取 sessionId (去掉 "SessionView-" 前缀)
        let sessionId = sessionButtons[0].identifier.replacingOccurrences(
            of: "SessionView-", with: ""
        )
        print("  🗑️  准备删除会话：\(sessionId)")

        // 第一步：点击会话区域（选中会话）
        sessionButtons[0].forceTap()
        print("  ✅ 已选中会话")

        // 第二步：点击 sessionNameButton（打开详情）
        print("  ✅ 已点击会话名称按钮")

        // 等待详情页加载（给更多时间）
        sleep(1)

        // 调试 1：打印所有按钮
        print("  🔍 当前界面所有按钮：")
        let allButtons = app.buttons.allElementsBoundByIndex

        print("  🔍 所有包含 Session 的元素：")
        let sessionPredicate = NSPredicate(format: "identifier CONTAINS 'Session'")
        let sessionElements = app.descendants(matching: .any).matching(sessionPredicate)
            .allElementsBoundByIndex

        let nameButton = app.buttons["Session-\(sessionId)"].firstMatch
        XCTAssertTrue(
            nameButton.waitForExistence(timeout: 1),
            "会话名称按钮 (Session-\(sessionId)) 必须在 5 秒内出现"
        )
        nameButton.forceTap()

        // 第三步：查找删除按钮
        let deleteButton = app.buttons["deleteSessionButton"]

        // 验证删除按钮存在
        XCTAssertTrue(
            deleteButton.waitForExistence(timeout: 1),
            "删除按钮 (deleteSessionButton) 必须在 5 秒内出现"
        )
        print("  ✅ 删除按钮已找到")

        // 点击删除按钮
        deleteButton.tap()
        print("  ✅ 已点击删除按钮")

        // 等待弹窗出现（给更多时间）
        sleep(1)

        // 确认删除弹窗（macOS 上使用 dialogs 或 sheets）
        // 先尝试 sheets，再尝试 dialogs，最后尝试 alerts
        var dialog: XCUIElement
        var dialogType = ""

        // 调试：打印所有 dialogs 和 sheets
        print("  🔍 查找弹窗...")
        print("  🔍 Dialogs 数量：\(app.dialogs.allElementsBoundByIndex.count)")
        print("  🔍 Sheets 数量：\(app.sheets.allElementsBoundByIndex.count)")
        print("  🔍 Alerts 数量：\(app.alerts.allElementsBoundByIndex.count)")

        // 打印所有 dialogs 的按钮
        for (i, dialogElem) in app.dialogs.allElementsBoundByIndex.enumerated() {
            print(
                "  🔍 Dialog [\(i)]: identifier=\(dialogElem.identifier), label=\(dialogElem.label)"
            )
            for (j, btn) in dialogElem.buttons.allElementsBoundByIndex.enumerated() {
                print("    Button [\(j)]: identifier=\(btn.identifier), label=\(btn.label)")
            }
        }

        // 打印所有 sheets 的按钮
        for (i, sheetElem) in app.sheets.allElementsBoundByIndex.enumerated() {
            print("  🔍 Sheet [\(i)]: identifier=\(sheetElem.identifier), label=\(sheetElem.label)")
            for (j, btn) in sheetElem.buttons.allElementsBoundByIndex.enumerated() {
                print("    Button [\(j)]: identifier=\(btn.identifier), label=\(btn.label)")
            }
        }

        if app.sheets.firstMatch.exists {
            dialog = app.sheets.firstMatch
            dialogType = "Sheet"
        } else if app.dialogs.firstMatch.exists {
            dialog = app.dialogs.firstMatch
            dialogType = "Dialog"
        } else {
            dialog = app.alerts.firstMatch
            dialogType = "Alert"
        }

        XCTAssertTrue(
            dialog.waitForExistence(timeout: 1),
            "删除确认弹窗 (\(dialogType)) 必须出现"
        )
        print("  ✅ 删除确认弹窗已显示 (类型：\(dialogType))")

        // 查找删除确认按钮（使用 identifier 和 label）
        // macOS 上 SwiftUI alert 的按钮 identifier 是 action-button-1 (Delete) 和 action-button-2 (Cancel)
        let confirmDeleteButton = dialog.buttons["action-button-1"].firstMatch
        XCTAssertTrue(
            confirmDeleteButton.waitForExistence(timeout: 1),
            "删除确认按钮 (action-button-1) 必须存在"
        )
        print("  ✅ 删除确认按钮已找到：identifier=action-button-1, label=Delete")
        confirmDeleteButton.forceTap()
        print("  ✅ 已点击删除确认按钮")

        // 等待弹窗关闭（给动画时间）
        sleep(1)
        print("  ✅ 删除完成")
    }
}
