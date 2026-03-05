// DeckViewModelExtendedTests.swift
// OpenClaw Deck Swift
//
// DeckViewModel 扩展测试

@testable import openclaw_deck_swift
import XCTest

@MainActor
final class DeckViewModelExtendedTests: XCTestCase {
    var viewModel: DeckViewModel!

    override func setUp() async throws {
        try await super.setUp()

        UserDefaults.standard.removeObject(forKey: "swiftdata.migrated")
        UserDefaults.standard.synchronize()

        viewModel = DeckViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Session Management

    func testCreateMultipleSessions() async {
        let session1 = await viewModel.createSession(name: "Session 1")
        let session2 = await viewModel.createSession(name: "Session 2")

        XCTAssertNotNil(session1)
        XCTAssertNotNil(session2)
        XCTAssertNotEqual(session1?.id, session2?.id)
    }

    func testDeleteNonExistentSession() {
        // 删除不存在的会话不应崩溃
        viewModel.deleteSession(id: "non-existent-id")
    }

    // MARK: - Sync Tests

    func testDownloadFromCloud_noCrash() async {
        // 验证下载方法不会崩溃（即使没有配置）
        await viewModel.downloadFromCloud()
    }

    func testResolveConflict_useLocal() async {
        await viewModel.resolveConflict(choice: .useLocal)
        // 验证不崩溃
    }

    func testResolveConflict_useCloud() async {
        await viewModel.resolveConflict(choice: .useCloud)
        // 验证不崩溃
    }

    func testResolveConflict_merge() async {
        await viewModel.resolveConflict(choice: .merge)
        // 验证不崩溃
    }
}
