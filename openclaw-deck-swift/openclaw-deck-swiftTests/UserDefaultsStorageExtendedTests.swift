// UserDefaultsStorageExtendedTests.swift
// OpenClaw Deck Swift
//
// UserDefaultsStorage 扩展测试 - 补充现有测试

@testable import openclaw_deck_swift
import XCTest

@MainActor
final class UserDefaultsStorageExtendedTests: XCTestCase {
    var storage: UserDefaultsStorage!

    override func setUp() {
        super.setUp()
        storage = UserDefaultsStorage.shared
        // 清理之前的测试数据
        storage.clearAll()
    }

    override func tearDown() {
        // 清理测试数据
        storage.clearAll()
        storage = nil
        super.tearDown()
    }

    // MARK: - Gateway URL 测试

    func testSaveGatewayUrl_validUrl() {
        // 测试保存有效 URL
        let testUrl = "ws://localhost:8080"
        storage.saveGatewayUrl(testUrl)
        let loaded = storage.loadGatewayUrl()
        XCTAssertEqual(loaded, testUrl, "应该能保存和加载有效的 URL")
    }

    func testSaveGatewayUrl_overwrite() {
        // 测试覆盖已有值
        storage.saveGatewayUrl("ws://old:8080")
        storage.saveGatewayUrl("ws://new:8080")
        let loaded = storage.loadGatewayUrl()
        XCTAssertEqual(loaded, "ws://new:8080", "应该覆盖旧值")
    }

    // MARK: - Token 测试

    func testSaveToken_validToken() {
        // 测试保存有效 token
        let testToken = "test_token_12345"
        storage.saveToken(testToken)
        let loaded = storage.loadToken()
        XCTAssertEqual(loaded, testToken, "应该能保存和加载有效的 token")
    }

    func testSaveToken_overwrite() {
        // 测试覆盖已有值
        storage.saveToken("old_token")
        storage.saveToken("new_token")
        let loaded = storage.loadToken()
        XCTAssertEqual(loaded, "new_token", "应该覆盖旧值")
    }

    func testClearToken() {
        // 测试清除 token
        storage.saveToken("test_token")
        storage.clearToken()
        let loaded = storage.loadToken()
        XCTAssertNil(loaded, "clearToken 后应该返回 nil")
    }

    // MARK: - Sessions 测试

    func testSaveSessions_emptyArray() {
        // 测试保存空数组
        storage.saveSessions([])
        let loaded = storage.loadSessions()
        XCTAssertEqual(loaded.count, 0, "应该能保存和加载空数组")
    }

    func testSaveSessions_singleSession() {
        // 测试保存单个会话
        let session = SessionConfig(
            id: "test_id",
            sessionKey: "agent:main:test_id",
            createdAt: Date(),
            name: "Test Session"
        )
        storage.saveSessions([session])
        let loaded = storage.loadSessions()
        XCTAssertEqual(loaded.count, 1, "应该能保存单个会话")
        XCTAssertEqual(loaded[0].name, "Test Session", "会话名称应该正确")
    }

    func testSaveSessions_multipleSessions() {
        // 测试保存多个会话
        let sessions = [
            SessionConfig(id: "id1", sessionKey: "agent:main:id1", createdAt: Date(), name: "Session 1"),
            SessionConfig(id: "id2", sessionKey: "agent:main:id2", createdAt: Date(), name: "Session 2"),
            SessionConfig(id: "id3", sessionKey: "agent:main:id3", createdAt: Date(), name: "Session 3"),
        ]
        storage.saveSessions(sessions)
        let loaded = storage.loadSessions()
        XCTAssertEqual(loaded.count, 3, "应该能保存多个会话")
    }

    func testSaveSessions_overwrite() {
        // 测试覆盖已有会话
        let oldSessions = [SessionConfig(id: "old", sessionKey: "agent:main:old", createdAt: Date(), name: "Old")]
        let newSessions = [SessionConfig(id: "new", sessionKey: "agent:main:new", createdAt: Date(), name: "New")]

        storage.saveSessions(oldSessions)
        storage.saveSessions(newSessions)

        let loaded = storage.loadSessions()
        XCTAssertEqual(loaded.count, 1, "应该覆盖旧会话")
        XCTAssertEqual(loaded[0].name, "New", "应该是新会话")
    }

    // MARK: - Session Order 测试

    func testSaveSessionOrder_emptyArray() {
        // 测试保存空数组
        storage.saveSessionOrder([])
        let loaded = storage.loadSessionOrder()
        XCTAssertEqual(loaded.count, 0, "应该能保存和加载空数组")
    }

    func testSaveSessionOrder_singleId() {
        // 测试保存单个 ID
        storage.saveSessionOrder(["session_1"])
        let loaded = storage.loadSessionOrder()
        XCTAssertEqual(loaded.count, 1, "应该能保存单个 ID")
        XCTAssertEqual(loaded[0], "session_1", "ID 应该正确")
    }

    func testSaveSessionOrder_multipleIds() {
        // 测试保存多个 ID
        let order = ["session_3", "session_1", "session_2"]
        storage.saveSessionOrder(order)
        let loaded = storage.loadSessionOrder()
        XCTAssertEqual(loaded.count, 3, "应该能保存多个 ID")
        XCTAssertEqual(loaded, order, "顺序应该保持一致")
    }

    func testSaveSessionOrder_overwrite() {
        // 测试覆盖已有顺序
        storage.saveSessionOrder(["old1", "old2"])
        storage.saveSessionOrder(["new1", "new2", "new3"])
        let loaded = storage.loadSessionOrder()
        XCTAssertEqual(loaded.count, 3, "应该覆盖旧顺序")
        XCTAssertEqual(loaded[0], "new1", "应该是新顺序")
    }

    // MARK: - clearAll 测试

    func testClearAll_clearsGatewayUrl() {
        storage.saveGatewayUrl("ws://test:8080")
        storage.clearAll()
        let loaded = storage.loadGatewayUrl()
        XCTAssertNil(loaded, "clearAll 应该清除 Gateway URL")
    }

    func testClearAll_clearsToken() {
        storage.saveToken("test_token")
        storage.clearAll()
        let loaded = storage.loadToken()
        XCTAssertNil(loaded, "clearAll 应该清除 Token")
    }

    func testClearAll_clearsSessions() {
        let sessions = [SessionConfig(id: "id", sessionKey: "agent:main:id", createdAt: Date(), name: "Test")]
        storage.saveSessions(sessions)
        storage.clearAll()
        let loaded = storage.loadSessions()
        XCTAssertEqual(loaded.count, 0, "clearAll 应该清除 Sessions")
    }

    func testClearAll_clearsSessionOrder() {
        storage.saveSessionOrder(["session_1", "session_2"])
        storage.clearAll()
        let loaded = storage.loadSessionOrder()
        XCTAssertEqual(loaded.count, 0, "clearAll 应该清除 Session Order")
    }

    func testClearAll_allAtOnce() {
        // 测试一次性清除所有数据
        storage.saveGatewayUrl("ws://test:8080")
        storage.saveToken("test_token")
        storage.saveSessions([SessionConfig(id: "id", sessionKey: "agent:main:id", createdAt: Date(), name: "Test")])
        storage.saveSessionOrder(["session_1"])

        storage.clearAll()

        XCTAssertNil(storage.loadGatewayUrl(), "应该清除 Gateway URL")
        XCTAssertNil(storage.loadToken(), "应该清除 Token")
        XCTAssertEqual(storage.loadSessions().count, 0, "应该清除 Sessions")
        XCTAssertEqual(storage.loadSessionOrder().count, 0, "应该清除 Session Order")
    }

    // MARK: - 性能测试

    func testSaveLoadGatewayUrl_performance() {
        measure {
            for _ in 0 ..< 100 {
                storage.saveGatewayUrl("ws://test:8080")
                _ = storage.loadGatewayUrl()
            }
        }
    }

    func testSaveLoadToken_performance() {
        measure {
            for _ in 0 ..< 100 {
                storage.saveToken("test_token")
                _ = storage.loadToken()
            }
        }
    }

    func testSaveLoadSessions_performance() {
        let sessions = [
            SessionConfig(id: "id1", sessionKey: "agent:main:id1", createdAt: Date(), name: "Session 1"),
            SessionConfig(id: "id2", sessionKey: "agent:main:id2", createdAt: Date(), name: "Session 2"),
        ]

        measure {
            for _ in 0 ..< 50 {
                storage.saveSessions(sessions)
                _ = storage.loadSessions()
            }
        }
    }

    func testSaveLoadSessionOrder_performance() {
        let order = ["session_1", "session_2", "session_3"]

        measure {
            for _ in 0 ..< 100 {
                storage.saveSessionOrder(order)
                _ = storage.loadSessionOrder()
            }
        }
    }
}
