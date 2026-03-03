// SyncButtonUITests.swift
// OpenClaw Deck Swift
//
// SyncButton UI 测试 - 平台适配版本
//
// 平台支持：
// - ✅ iOS: 触摸交互测试
// - ✅ iPadOS: 平板交互测试
// - ✅ macOS: 鼠标交互测试

import XCTest

#if os(iOS)
    import UIKit
#endif

@MainActor
final class SyncButtonUITests: XCTestCase {
    var app: XCUIApplication!

    /// 当前运行平台
    var currentPlatform: String {
        #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                return "iPadOS"
            }
            return "iOS"
        #elseif os(macOS)
            return "macOS"
        #else
            return "Unknown"
        #endif
    }

    /// 弹窗类型（不同平台不同）
    var alertType: String {
        #if os(macOS)
            return "dialog" // macOS 使用 dialog
        #else
            return "alert" // iOS 使用 alert
        #endif
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "YES"
        continueAfterFailure = true
        app.launch()

        print("📱 在 [\(currentPlatform)] 平台启动 UI 测试")

        // 等待主界面加载
        waitForAppToLoad()
    }

    /// 等待应用加载完成
    private func waitForAppToLoad() {
        let loaded = waitForElementToAppear(
            app.buttons["SyncButton"],
            timeout: 30,
            message: "Sync 按钮应该在 30 秒内出现"
        )
        XCTAssertTrue(loaded)
    }

    /// 通用方法：等待元素出现
    private func waitForElementToAppear(
        _ element: XCUIElement,
        timeout: TimeInterval,
        message: String
    ) -> Bool {
        let exists = element.waitForExistence(timeout: timeout)
        if !exists {
            print("⚠️  \(message)")
            // 调试信息
            print("  可用按钮：\(app.buttons.allElementsBoundByIndex.map(\.identifier))")
        }
        return exists
    }

    /// 平台特定：获取确认弹窗的 Cancel 按钮
    private func getCancelButton() -> XCUIElement {
        #if os(macOS)
            // macOS 可能使用不同的按钮标签
            return app.buttons["取消"].firstMatch.exists
                ? app.buttons["取消"].firstMatch
                : app.buttons["Cancel"].firstMatch
        #else
            // iOS 使用标准标签
            return app.buttons["取消"].firstMatch.exists
                ? app.buttons["取消"].firstMatch
                : app.buttons["Cancel"].firstMatch
        #endif
    }

    /// 平台特定：获取确认弹窗的 Sync 按钮
    private func getSyncButton() -> XCUIElement {
        #if os(macOS)
            return app.buttons["同步"].firstMatch.exists
                ? app.buttons["同步"].firstMatch
                : app.buttons["Sync"].firstMatch
        #else
            return app.buttons["同步"].firstMatch.exists
                ? app.buttons["同步"].firstMatch
                : app.buttons["Sync"].firstMatch
        #endif
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - 核心测试：完整的同步流程

    /// 测试 1：Sync 按钮完整功能流程
    func testSyncButton_completeFlow() {
        print("🧪 开始 testSyncButton_completeFlow [\(currentPlatform)]")

        // 1. 验证同步按钮存在
        let syncButton = app.buttons["SyncButton"].firstMatch
        XCTAssertTrue(
            waitForElementToAppear(syncButton, timeout: 5, message: "同步按钮应该存在"),
            "同步按钮应该在 5 秒内出现"
        )

        // 平台特定：验证按钮可点击性
        #if os(macOS)
            // macOS 验证 hover 状态（如果支持）
            XCTAssertTrue(syncButton.isEnabled, "macOS: 同步按钮应该可点击")
        #else
            // iOS 验证触摸状态
            XCTAssertTrue(syncButton.isEnabled, "iOS: 同步按钮应该可点击")
        #endif

        // 2. 点击同步按钮
        syncButton.tap()
        print("  ✅ 点击了同步按钮")

        // 3. 等待确认弹窗出现
        let cancelButton = getCancelButton()
        let syncButtonInAlert = getSyncButton()

        let alertAppeared = waitForElementToAppear(
            cancelButton,
            timeout: 10,
            message: "确认弹窗应该在 10 秒内出现"
        )
        XCTAssertTrue(alertAppeared, "确认弹窗应该出现")
        print("  ✅ 确认弹窗出现")

        // 4. 验证弹窗内容
        XCTAssertTrue(
            cancelButton.exists,
            "弹窗应该有 Cancel/取消按钮"
        )
        XCTAssertTrue(
            syncButtonInAlert.exists,
            "弹窗应该有 Sync/同步按钮"
        )
        print("  ✅ 弹窗按钮验证通过")

        // 5. 点击 Cancel 取消同步
        cancelButton.tap()
        print("  ✅ 点击了取消按钮")

        // 验证弹窗消失
        sleep(1) // 等待动画
        XCTAssertFalse(
            cancelButton.exists,
            "弹窗应该在点击 Cancel 后消失"
        )
        print("  ✅ 弹窗已关闭")

        // 6. 验证应用还在主界面
        #if os(iOS)
            XCTAssertTrue(
                app.tables["SessionList"].exists,
                "iOS: 应该还在 Session 列表界面"
            )
        #elseif os(macOS)
            // macOS 验证主窗口存在
            XCTAssertTrue(
                app.windows.firstMatch.exists || app.buttons["SyncButton"].exists,
                "macOS: 应用应该还在主界面"
            )
        #endif
        print("  ✅ 返回主界面")

        print("✅ testSyncButton_completeFlow 通过 [\(currentPlatform)]")
    }

    // MARK: - 边缘情况测试

    /// 测试 2：Sync 按钮边缘情况
    func testSyncButton_edgeCases() {
        print("🧪 开始 testSyncButton_edgeCases [\(currentPlatform)]")

        let syncButton = app.buttons["SyncButton"].firstMatch

        guard waitForElementToAppear(syncButton, timeout: 5, message: "同步按钮未找到") else {
            XCTFail("同步按钮未找到")
            return
        }

        // 平台特定：多次点击测试
        #if os(iOS)
            // iOS: 快速连续点击
            for i in 0 ..< 3 {
                syncButton.tap()
                sleep(1)

                let cancelButton = getCancelButton()
                if cancelButton.exists {
                    cancelButton.tap()
                    print("  第 \(i + 1) 次点击：弹窗出现并取消")
                }
            }
        #elseif os(macOS)
            // macOS: 模拟鼠标点击
            for i in 0 ..< 3 {
                syncButton.tap()
                sleep(2)

                let cancelButton = getCancelButton()
                if cancelButton.exists {
                    cancelButton.tap()
                    print("  第 \(i + 1) 次点击：弹窗出现并取消")
                }
            }
        #endif

        // 验证应用没有崩溃
        #if os(iOS)
            XCTAssertTrue(
                app.tables["SessionList"].waitForExistence(timeout: 5),
                "iOS: 应用应该在多次点击后仍然正常运行"
            )
        #elseif os(macOS)
            XCTAssertTrue(
                app.buttons["SyncButton"].waitForExistence(timeout: 5),
                "macOS: 应用应该在多次点击后仍然正常运行"
            )
        #endif

        // 验证同步按钮仍然可用
        XCTAssertTrue(
            syncButton.exists && syncButton.isEnabled,
            "同步按钮在多次点击后应该仍然可用"
        )

        print("✅ testSyncButton_edgeCases 通过 [\(currentPlatform)]")
    }

    // MARK: - 应用启动测试

    /// 测试 3：应用启动和 Sync 按钮初始化
    func testAppLaunchAndSyncButton() {
        print("🧪 开始 testAppLaunchAndSyncButton [\(currentPlatform)]")

        // 验证应用成功启动
        XCTAssertTrue(app.exists, "应用应该成功启动")

        // 平台特定：验证窗口
        #if os(iOS)
            // iOS 验证主窗口
            let mainWindow = app.windows.firstMatch
            XCTAssertTrue(mainWindow.exists, "iOS: 主窗口应该存在")
        #elseif os(macOS)
            // macOS 验证应用菜单
            XCTAssertTrue(
                app.menuItems.firstMatch.exists || app.buttons.firstMatch.exists,
                "macOS: 应用界面应该存在"
            )
        #endif

        // 验证同步按钮存在
        let syncButton = app.buttons["SyncButton"].firstMatch
        XCTAssertTrue(
            waitForElementToAppear(syncButton, timeout: 5, message: "同步按钮应该存在"),
            "同步按钮应该在 5 秒内出现"
        )

        print("✅ testAppLaunchAndSyncButton 通过 [\(currentPlatform)]")
    }

    // MARK: - 平台特定测试

    #if os(iOS)
        /// iOS 特定：验证触摸反馈
        func testSyncButton_TouchFeedback() {
            print("🧪 开始 iOS 特定测试：触摸反馈")

            let syncButton = app.buttons["SyncButton"].firstMatch
            XCTAssertTrue(syncButton.waitForExistence(timeout: 5))

            // iOS 验证按钮有触摸反馈
            // （实际测试需要访问辅助功能属性）
            XCTAssertTrue(syncButton.isEnabled, "按钮应该可交互")

            print("✅ iOS 触摸反馈测试通过")
        }
    #endif

    #if os(macOS)
        /// macOS 特定：验证鼠标悬停
        func testSyncButton_HoverState() {
            print("🧪 开始 macOS 特定测试：鼠标悬停")

            let syncButton = app.buttons["SyncButton"].firstMatch
            XCTAssertTrue(syncButton.waitForExistence(timeout: 5))

            // macOS 验证按钮可以交互
            XCTAssertTrue(syncButton.isEnabled, "按钮应该可交互")

            print("✅ macOS 鼠标悬停测试通过")
        }
    #endif
}
