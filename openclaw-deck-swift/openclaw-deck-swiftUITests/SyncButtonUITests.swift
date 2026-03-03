// SyncButtonUITests.swift
// OpenClaw Deck Swift
//
// SyncButton UI 测试 - 测试同步按钮的交互
//
// 平台支持：
// - ✅ iOS: 完全支持
// - ✅ iPadOS: 完全支持
// - ⚠️  macOS: 部分测试可能失败（辅助功能限制）

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

    override func setUpWithError() throws {
        try super.setUpWithError()

        // macOS 平台跳过某些测试（辅助功能限制）
        if currentPlatform == "macOS" {
            print("⚠️  在 macOS 上运行 UI 测试，部分功能可能不可用")
        }

        app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "YES"
        continueAfterFailure = true
        app.launch()

        // 等待主界面加载（iOS/iPadOS 使用 Table，macOS 可能不同）
        var sessionListExists = false

        #if os(iOS) || os(tvOS)
            sessionListExists = app.tables["SessionList"].waitForExistence(timeout: 30)
        #elseif os(macOS)
            // macOS 使用更通用的选择器
            sessionListExists = app.tables.firstMatch.waitForExistence(timeout: 30)
        #endif

        XCTAssertTrue(sessionListExists, "Session 列表应该在 30 秒内加载")
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - 核心测试：完整的同步流程

    /// 测试 1：Sync 按钮完整功能流程
    func testSyncButton_completeFlow() {
        // macOS 平台跳过详细测试
        if currentPlatform == "macOS" {
            print("⚠️  macOS: 跳过 testSyncButton_completeFlow 详细测试")
            // 只验证基本功能
            let syncButton = app.buttons["SyncButton"].firstMatch
            XCTAssertTrue(
                syncButton.waitForExistence(timeout: 5),
                "同步按钮应该存在"
            )
            return
        }

        // iOS/iPadOS 完整测试
        let syncButton = app.buttons["SyncButton"].firstMatch
        XCTAssertTrue(
            syncButton.waitForExistence(timeout: 5),
            "同步按钮应该在 5 秒内出现"
        )
        XCTAssertTrue(syncButton.isEnabled, "同步按钮应该可点击")

        // 点击同步按钮，等待确认弹窗
        syncButton.tap()

        // 使用更通用的方式查找弹窗（支持中英文）
        let cancelPredicate = NSPredicate(format: "label CONTAINS 'Cancel' OR label CONTAINS '取消'")
        let syncPredicate = NSPredicate(format: "label CONTAINS 'Sync' OR label CONTAINS '同步'")

        let cancelButton = app.buttons.matching(cancelPredicate).firstMatch
        let syncButtonInAlert = app.buttons.matching(syncPredicate).firstMatch

        // 等待弹窗按钮出现（10 秒超时）
        let alertAppeared = cancelButton.waitForExistence(timeout: 10)
        XCTAssertTrue(
            alertAppeared,
            "确认弹窗应该在 10 秒内出现"
        )

        // 验证弹窗内容
        XCTAssertTrue(
            cancelButton.exists || app.buttons["取消"].exists,
            "弹窗应该有 Cancel/取消按钮"
        )

        XCTAssertTrue(
            syncButtonInAlert.exists || app.buttons["同步"].exists,
            "弹窗应该有 Sync/同步按钮"
        )

        // 点击 Cancel 取消同步
        if cancelButton.exists {
            cancelButton.tap()
        } else {
            app.buttons["取消"].firstMatch.tap()
        }

        // 验证弹窗消失
        XCTAssertFalse(
            cancelButton.waitForExistence(timeout: 2),
            "弹窗应该在点击 Cancel 后消失"
        )

        // 验证应用还在主界面
        XCTAssertTrue(
            app.tables["SessionList"].exists,
            "取消后应该还在 Session 列表界面"
        )

        // 再次点击同步按钮，验证可以重新打开弹窗
        syncButton.tap()
        XCTAssertTrue(
            cancelButton.waitForExistence(timeout: 5),
            "应该可以重新打开确认弹窗"
        )

        // 点击 Sync 执行同步
        if syncButtonInAlert.exists {
            syncButtonInAlert.tap()
        } else {
            app.buttons["同步"].firstMatch.tap()
        }

        // 验证弹窗消失（同步开始）
        XCTAssertFalse(
            cancelButton.waitForExistence(timeout: 2),
            "弹窗应该在点击 Sync 后消失"
        )

        print("✅ testSyncButton_completeFlow 通过 [\(currentPlatform)]")
    }

    // MARK: - 边缘情况测试

    /// 测试 2：Sync 按钮边缘情况
    func testSyncButton_edgeCases() {
        // macOS 平台简化测试
        if currentPlatform == "macOS" {
            print("⚠️  macOS: 简化 testSyncButton_edgeCases 测试")
            let syncButton = app.buttons["SyncButton"].firstMatch
            XCTAssertTrue(
                syncButton.waitForExistence(timeout: 5),
                "同步按钮应该存在"
            )
            XCTAssertTrue(
                syncButton.isEnabled,
                "同步按钮应该可点击"
            )
            return
        }

        // iOS/iPadOS 完整测试
        let syncButton = app.buttons["SyncButton"].firstMatch

        guard syncButton.waitForExistence(timeout: 5) else {
            XCTFail("同步按钮未找到")
            return
        }

        // 多次快速点击同步按钮
        for i in 0 ..< 3 {
            syncButton.tap()

            // 等待弹窗出现（如果还没出现）
            let cancelPredicate = NSPredicate(format: "label CONTAINS 'Cancel' OR label CONTAINS '取消'")
            let cancelButton = app.buttons.matching(cancelPredicate).firstMatch

            if cancelButton.waitForExistence(timeout: 2) {
                // 取消弹窗
                cancelButton.tap()
                print("  第 \(i + 1) 次点击：弹窗出现并取消")
            }
        }

        // 验证应用没有崩溃
        XCTAssertTrue(
            app.tables["SessionList"].waitForExistence(timeout: 5),
            "应用应该在多次点击后仍然正常运行"
        )

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
        // 验证应用成功启动
        XCTAssertTrue(app.exists, "应用应该成功启动")

        // 验证主窗口存在（macOS 可能无法识别）
        #if os(iOS) || os(tvOS)
            let mainWindow = app.windows.firstMatch
            XCTAssertTrue(mainWindow.exists, "主窗口应该存在")
        #endif

        // 验证同步按钮存在
        let syncButton = app.buttons["SyncButton"].firstMatch
        XCTAssertTrue(
            syncButton.waitForExistence(timeout: 5),
            "同步按钮应该在 5 秒内出现"
        )

        print("✅ testAppLaunchAndSyncButton 通过 [\(currentPlatform)]")
    }
}
