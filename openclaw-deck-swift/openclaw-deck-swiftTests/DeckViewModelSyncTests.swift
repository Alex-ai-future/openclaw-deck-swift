// DeckViewModelSyncTests.swift
// OpenClaw Deck Swift
//
// 同步和冲突处理测试

@testable import openclaw_deck_swift
import XCTest

@MainActor
final class DeckViewModelSyncTests: XCTestCase {
    var mockCloudflare: MockCloudflareKV!
    var mockGateway: MockGatewayClient!
    var mockStorage: MockUserDefaultsStorage!

    override func setUp() async throws {
        try await super.setUp()

        // 清理 UserDefaults
        UserDefaults.standard.removeObject(forKey: "openclaw.deck.gatewayUrl")
        UserDefaults.standard.removeObject(forKey: "openclaw.deck.token")
        UserDefaults.standard.removeObject(forKey: "openclaw.deck.sessionOrder")
        UserDefaults.standard.synchronize()

        // 创建 Mock 对象并设置为 CloudflareKV 的 Mock 实例
        mockCloudflare = MockCloudflareKV()
        CloudflareKV.mockInstance = mockCloudflare // ✅ 使用 mockInstance

        mockGateway = MockGatewayClient()
        mockStorage = MockUserDefaultsStorage()
        mockStorage.isTesting = false // ✅ 允许 Cloudflare 同步

        // 预置本地会话数据，避免创建 Welcome Session
        mockStorage.saveSessionOrder(["existing-session"])
    }

    override func tearDown() async throws {
        // 清除 Mock 实例
        CloudflareKV.mockInstance = nil

        mockCloudflare = nil
        mockGateway = nil
        mockStorage = nil

        // 清理 UserDefaults
        UserDefaults.standard.removeObject(forKey: "openclaw.deck.gatewayUrl")
        UserDefaults.standard.removeObject(forKey: "openclaw.deck.token")
        UserDefaults.standard.removeObject(forKey: "openclaw.deck.sessionOrder")
        UserDefaults.standard.synchronize()

        try await super.tearDown()
    }

    // MARK: - Conflict Detection Tests

    /// 测试同步时检测到冲突
    func testSync_conflictDetected() async {
        // 准备冲突数据
        mockCloudflare.simulateConflict = true
        mockCloudflare.conflictLocalData = SyncData(
            sessions: ["session1"],
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        )
        mockCloudflare.conflictRemoteData = SyncData(
            sessions: ["session1", "session2"],
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        )

        // 创建 ViewModel（使用 Mock Cloudflare）
        let viewModel = DeckViewModel(
            diContainer: MockFactory.createDIContainer(
                storage: mockStorage,
                gatewayClient: mockGateway,
                cloudflareKV: mockCloudflare
            )
        )

        // 初始化（会触发同步）
        await viewModel.initialize(url: "ws://localhost:18789", token: nil)

        // 验证：检测到冲突
        XCTAssertTrue(viewModel.showingSyncConflict, "应该检测到冲突")
        XCTAssertNotNil(viewModel.conflictLocalData, "本地冲突数据不应为空")
        XCTAssertNotNil(viewModel.conflictRemoteData, "云端冲突数据不应为空")
    }

    // MARK: - Conflict Resolution Tests

    /// 测试解决冲突 - 选择本地数据
    func testSync_resolveConflict_chooseLocal() async {
        // 准备冲突
        mockCloudflare.simulateConflict = true
        let localData = SyncData(
            sessions: ["session1", "session2"],
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        )
        let remoteData = SyncData(
            sessions: ["session3"],
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        )
        mockCloudflare.conflictLocalData = localData
        mockCloudflare.conflictRemoteData = remoteData

        // 设置本地存储
        mockStorage.saveSessionOrder(["session1", "session2"])

        let viewModel = DeckViewModel(
            diContainer: MockFactory.createDIContainer(
                storage: mockStorage,
                gatewayClient: mockGateway,
                cloudflareKV: mockCloudflare
            )
        )

        await viewModel.initialize(url: "ws://localhost:18789", token: nil)

        // 验证：有冲突
        XCTAssertTrue(viewModel.showingSyncConflict, "应该有冲突")

        // 用户选择本地数据
        await viewModel.resolveSyncConflict(choice: "local")

        // 等待异步操作完成
        try? await Task.sleep(nanoseconds: 500_000_000)

        // 验证：冲突已解决
        XCTAssertFalse(viewModel.showingSyncConflict, "冲突应该已解决")
        XCTAssertNil(viewModel.conflictLocalData, "本地冲突数据应清空")
        XCTAssertNil(viewModel.conflictRemoteData, "云端冲突数据应清空")

        // 验证：使用本地数据
        XCTAssertEqual(
            viewModel.sessionOrder,
            ["session1", "session2"],
            "应该使用本地会话列表"
        )
    }

    /// 测试解决冲突 - 选择云端数据
    func testSync_resolveConflict_chooseCloud() async {
        // 准备冲突
        mockCloudflare.simulateConflict = true
        let localData = SyncData(
            sessions: ["session1"],
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        )
        let remoteData = SyncData(
            sessions: ["session2", "session3"],
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        )
        mockCloudflare.conflictLocalData = localData
        mockCloudflare.conflictRemoteData = remoteData

        let viewModel = DeckViewModel(
            diContainer: MockFactory.createDIContainer(
                storage: mockStorage,
                gatewayClient: mockGateway,
                cloudflareKV: mockCloudflare
            )
        )

        await viewModel.initialize(url: "ws://localhost:18789", token: nil)

        // 验证：有冲突
        XCTAssertTrue(viewModel.showingSyncConflict, "应该有冲突")

        // 用户选择云端数据
        await viewModel.resolveSyncConflict(choice: "remote")

        // 等待异步操作完成
        try? await Task.sleep(nanoseconds: 500_000_000)

        // 验证：冲突已解决
        XCTAssertFalse(viewModel.showingSyncConflict, "冲突应该已解决")

        // 验证：使用云端数据
        XCTAssertEqual(
            viewModel.sessionOrder,
            ["session2", "session3"],
            "应该使用云端会话列表"
        )
    }

    /// 测试解决冲突 - 取消
    func testSync_resolveConflict_cancel() async {
        // 准备冲突
        mockCloudflare.simulateConflict = true
        mockCloudflare.conflictLocalData = SyncData(
            sessions: ["session1"],
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        )
        mockCloudflare.conflictRemoteData = SyncData(
            sessions: ["session2"],
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        )

        let viewModel = DeckViewModel(
            diContainer: MockFactory.createDIContainer(
                storage: mockStorage,
                gatewayClient: mockGateway,
                cloudflareKV: mockCloudflare
            )
        )

        await viewModel.initialize(url: "ws://localhost:18789", token: nil)

        // 验证：有冲突
        XCTAssertTrue(viewModel.showingSyncConflict, "应该有冲突")

        // 用户取消
        await viewModel.resolveSyncConflict(choice: "cancel")

        // 验证：冲突仍然存在
        XCTAssertTrue(viewModel.showingSyncConflict, "取消后冲突应该仍然存在")
    }

    // MARK: - Reconnect Tests

    /// 测试重新创建 ViewModel 后同步成功（无冲突）
    func testSyncWithReconnect_success() async {
        // 准备无冲突的 Mock 数据
        mockCloudflare.simulateConflict = false
        mockCloudflare.mockData = SyncData(
            sessions: ["session1", "session2"],
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        )

        mockGateway.connected = true

        // 创建新 ViewModel
        let newViewModel = DeckViewModel(
            diContainer: MockFactory.createDIContainer(
                storage: mockStorage,
                gatewayClient: mockGateway,
                cloudflareKV: mockCloudflare
            )
        )

        // 初始化
        await newViewModel.initialize(url: "ws://localhost:18789", token: nil)

        // 验证：没有冲突
        XCTAssertFalse(newViewModel.showingSyncConflict, "不应该有冲突")

        // 验证：会话已加载
        XCTAssertEqual(newViewModel.sessionOrder.count, 2, "应该有 2 个会话")
        XCTAssertEqual(
            newViewModel.sessionOrder,
            ["session1", "session2"],
            "会话顺序应该正确"
        )
    }

    /// 测试重新创建 ViewModel 后同步成功（有冲突后解决）
    func testSyncWithReconnect_conflictThenResolve() async {
        // 第一步：准备冲突
        mockCloudflare.simulateConflict = true
        mockCloudflare.conflictLocalData = SyncData(
            sessions: ["session1"],
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        )
        mockCloudflare.conflictRemoteData = SyncData(
            sessions: ["session2"],
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        )

        // 创建 ViewModel
        let viewModel = DeckViewModel(
            diContainer: MockFactory.createDIContainer(
                storage: mockStorage,
                gatewayClient: mockGateway,
                cloudflareKV: mockCloudflare
            )
        )

        // 初始化 - 会检测到冲突
        await viewModel.initialize(url: "ws://localhost:18789", token: nil)

        // 验证：有冲突
        XCTAssertTrue(viewModel.showingSyncConflict, "应该检测到冲突")

        // 第二步：解决冲突（选择云端）
        await viewModel.resolveSyncConflict(choice: "remote")

        // 等待异步操作完成
        try? await Task.sleep(nanoseconds: 500_000_000)

        // 验证：冲突已解决
        XCTAssertFalse(viewModel.showingSyncConflict, "冲突应该已解决")

        // 验证：使用云端数据
        XCTAssertEqual(
            viewModel.sessionOrder,
            ["session2"],
            "应该使用云端会话列表"
        )
    }

    // MARK: - Edge Cases

    /// 测试空会话冲突
    func testSync_conflict_emptySessions() async {
        // 准备空会话冲突
        mockCloudflare.simulateConflict = true
        mockCloudflare.conflictLocalData = SyncData(
            sessions: [],
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        )
        mockCloudflare.conflictRemoteData = SyncData(
            sessions: [],
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        )

        let viewModel = DeckViewModel(
            diContainer: MockFactory.createDIContainer(
                storage: mockStorage,
                gatewayClient: mockGateway,
                cloudflareKV: mockCloudflare
            )
        )

        await viewModel.initialize(url: "ws://localhost:18789", token: nil)

        // 验证：检测到冲突
        XCTAssertTrue(viewModel.showingSyncConflict, "应该检测到冲突")

        // 验证：冲突信息正确
        XCTAssertEqual(viewModel.conflictInfo?.localCount, 0, "本地会话数应为 0")
        XCTAssertEqual(viewModel.conflictInfo?.remoteCount, 0, "云端会话数应为 0")
    }

    /// 测试相同会话不同顺序的冲突
    func testSync_conflict_sameSessionsDifferentOrder() async {
        // 准备相同会话不同顺序的冲突
        mockCloudflare.simulateConflict = true
        mockCloudflare.conflictLocalData = SyncData(
            sessions: ["session1", "session2", "session3"],
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        )
        mockCloudflare.conflictRemoteData = SyncData(
            sessions: ["session3", "session1", "session2"],
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        )

        let viewModel = DeckViewModel(
            diContainer: MockFactory.createDIContainer(
                storage: mockStorage,
                gatewayClient: mockGateway,
                cloudflareKV: mockCloudflare
            )
        )

        await viewModel.initialize(url: "ws://localhost:18789", token: nil)

        // 验证：检测到冲突
        XCTAssertTrue(viewModel.showingSyncConflict, "应该检测到冲突")

        // 验证：标记为仅顺序不同
        XCTAssertEqual(
            viewModel.conflictInfo?.isOrderOnly,
            true,
            "应该标记为仅顺序不同"
        )
    }
}
