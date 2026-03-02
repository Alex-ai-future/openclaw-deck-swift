// SyncButtonUITests.swift
// OpenClaw Deck Swift
//
// SyncButton UI 测试 - 测试同步按钮的交互

import XCTest

// MARK: - 测试用例

@MainActor
final class SyncButtonUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // 启动应用
        app = XCUIApplication()

        // 添加测试模式标记（用于依赖注入检测）
        app.launchArguments = ["--ui-testing"]

        // 继续失败（一个测试失败后继续执行）
        continueAfterFailure = true

        // 启动应用
        app.launch()

        // 等待主界面加载（增加超时时间）
        let sessionListExists = app.tables["SessionList"].waitForExistence(timeout: 30)
        if !sessionListExists {
            // 尝试查找其他可能的标识
            print("SessionList not found, available tables:")
            print(app.tables.allElementsBoundByIndex.map(\.identifier))
        }
        XCTAssertTrue(sessionListExists, "Session 列表应该在 30 秒内加载")
    }

    override func tearDownWithError() throws {
        // 终止应用
        app.terminate()
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - 基础测试

    /// 测试 1: 应用启动
    func testAppLaunch() {
        // 验证应用成功启动
        XCTAssertTrue(app.exists, "应用应该成功启动")

        // 验证主窗口存在
        let mainWindow = app.windows.firstMatch
        XCTAssertTrue(mainWindow.exists, "主窗口应该存在")

        print("✅ testAppLaunch 通过")
    }

    /// 测试 2: Sync 按钮存在
    func testSyncButton_exists() {
        // 找到同步按钮
        let syncButton = app.buttons["SyncButton"]

        // 验证按钮存在
        XCTAssertTrue(
            syncButton.waitForExistence(timeout: 5),
            "同步按钮应该在 5 秒内出现"
        )

        print("✅ testSyncButton_exists 通过")
    }

    // MARK: - 同步交互测试

    /// 测试 3: 点击 Sync 按钮显示确认弹窗
    func testSyncButton_showsConfirmation() {
        // 找到同步按钮
        let syncButton = app.buttons["SyncButton"]

        // 等待按钮出现
        guard syncButton.waitForExistence(timeout: 5) else {
            XCTFail("同步按钮未找到")
            return
        }

        // 点击同步按钮
        syncButton.tap()

        // 等待确认弹窗出现
        let syncAlert = app.alerts["Sync All Sessions?"]
        XCTAssertTrue(
            syncAlert.waitForExistence(timeout: 3),
            "同步确认弹窗应该在 3 秒内出现"
        )

        // 验证弹窗标题
        XCTAssertEqual(
            syncAlert.label,
            "Sync All Sessions?",
            "弹窗标题应该是 'Sync All Sessions?'"
        )

        // 验证弹窗消息
        let alertMessage = syncAlert.staticTexts.element(boundBy: 0)
        XCTAssertTrue(
            alertMessage.exists,
            "弹窗应该有消息文本"
        )

        // 验证有两个按钮（Cancel 和 Sync）
        let cancelButton = syncAlert.buttons["Cancel"]
        let syncButtonInAlert = syncAlert.buttons["Sync"]

        XCTAssertTrue(cancelButton.exists, "应该有 Cancel 按钮")
        XCTAssertTrue(syncButtonInAlert.exists, "应该有 Sync 按钮")

        print("✅ testSyncButton_showsConfirmation 通过")
    }

    /// 测试 4: 点击 Cancel 取消同步
    func testSyncButton_cancelDoesNotSync() {
        // 找到同步按钮
        let syncButton = app.buttons["SyncButton"]

        guard syncButton.waitForExistence(timeout: 5) else {
            XCTFail("同步按钮未找到")
            return
        }

        // 点击同步按钮
        syncButton.tap()

        // 等待确认弹窗
        let syncAlert = app.alerts["Sync All Sessions?"]
        guard syncAlert.waitForExistence(timeout: 3) else {
            XCTFail("确认弹窗未出现")
            return
        }

        // 点击 Cancel
        syncAlert.buttons["Cancel"].tap()

        // 验证弹窗消失
        XCTAssertFalse(
            syncAlert.waitForExistence(timeout: 2),
            "弹窗应该在点击 Cancel 后消失"
        )

        // 验证应用还在主界面
        XCTAssertTrue(
            app.tables["SessionList"].exists,
            "应该还在 Session 列表界面"
        )

        print("✅ testSyncButton_cancelDoesNotSync 通过")
    }

    /// 测试 5: 点击 Sync 执行同步
    func testSyncButton_confirmStartsSync() {
        // 找到同步按钮
        let syncButton = app.buttons["SyncButton"]

        guard syncButton.waitForExistence(timeout: 5) else {
            XCTFail("同步按钮未找到")
            return
        }

        // 点击同步按钮
        syncButton.tap()

        // 等待确认弹窗
        let syncAlert = app.alerts["Sync All Sessions?"]
        guard syncAlert.waitForExistence(timeout: 3) else {
            XCTFail("确认弹窗未出现")
            return
        }

        // 点击 Sync 确认
        syncAlert.buttons["Sync"].tap()

        // 验证弹窗消失
        XCTAssertFalse(
            syncAlert.waitForExistence(timeout: 2),
            "弹窗应该在点击 Sync 后消失"
        )

        // 注意：实际同步可能需要网络，这里只验证弹窗关闭
        // 如果需要验证同步结果，需要配置测试用的 Gateway

        print("✅ testSyncButton_confirmStartsSync 通过")
    }

    // MARK: - 多次点击测试

    /// 测试 6: 多次点击 Sync 按钮不会崩溃
    func testSyncButton_multipleClicks() {
        // 找到同步按钮
        let syncButton = app.buttons["SyncButton"]

        guard syncButton.waitForExistence(timeout: 5) else {
            XCTFail("同步按钮未找到")
            return
        }

        // 多次点击
        for i in 0 ..< 3 {
            syncButton.tap()

            // 等待弹窗
            let syncAlert = app.alerts["Sync All Sessions?"]
            if syncAlert.waitForExistence(timeout: 2) {
                // 取消
                syncAlert.buttons["Cancel"].tap()
                print("  第 \(i + 1) 次点击：弹窗出现并取消")
            }
        }

        // 验证应用没有崩溃
        XCTAssertTrue(
            app.tables["SessionList"].exists,
            "应用应该在多次点击后仍然正常运行"
        )

        print("✅ testSyncButton_multipleClicks 通过")
    }

    // MARK: - 辅助方法

    /// 等待并验证弹窗
    private func waitForAlert(title: String, timeout: TimeInterval = 3) -> XCUIElement {
        let alert = app.alerts[title]
        let exists = alert.waitForExistence(timeout: timeout)

        if !exists {
            XCTFail("弹窗 '\(title)' 未在 \(timeout) 秒内出现")
        }

        return alert
    }

    /// 截图验证
    private func takeScreenshot(name: String) {
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

// MARK: - 性能测试

final class SyncButtonPerformanceTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
        try super.tearDownWithError()
    }

    /// 性能测试：Sync 按钮响应时间
    func testSyncButton_responseTime() {
        let syncButton = app.buttons["SyncButton"]

        guard syncButton.waitForExistence(timeout: 5) else {
            XCTFail("同步按钮未找到")
            return
        }

        // 测量点击到弹窗出现的时间
        self.measure {
            syncButton.tap()
            let alert = app.alerts["Sync All Sessions?"]
            _ = alert.waitForExistence(timeout: 2)

            // 取消弹窗
            alert.buttons["Cancel"].tap()
        }
    }
}
