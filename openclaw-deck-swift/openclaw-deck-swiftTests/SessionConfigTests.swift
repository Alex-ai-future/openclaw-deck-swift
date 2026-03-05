// SessionConfigTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/26.
// Copyright © 2026 OpenClaw. All rights reserved.

@testable import openclaw_deck_swift
import XCTest

final class SessionConfigTests: XCTestCase {
    func testGenerateId_withNormalName() {
        let sessionId = SessionConfig.generateId(from: "Research Agent")
        XCTAssertEqual(sessionId, "research-agent")
    }

    func testGenerateId_withSpecialCharacters() {
        let sessionId = SessionConfig.generateId(from: "Test @#$% Agent")
        XCTAssertEqual(sessionId, "test-agent")
    }

    func testGenerateId_withEmptyName() {
        let sessionId = SessionConfig.generateId(from: "")
        XCTAssertTrue(sessionId.hasPrefix("session-"))
    }

    func testGenerateId_isConsistent() {
        // 相同名字应该生成相同 ID（不再有随机后缀）
        let id1 = SessionConfig.generateId(from: "Test")
        let id2 = SessionConfig.generateId(from: "Test")
        XCTAssertEqual(id1, id2)
    }

    func testIsNameTaken_withExistingSession() {
        // 创建模拟的 sessions 字典
        let sessions: [String: SessionState] = [
            "test-agent": SessionState(sessionId: "test-agent", sessionKey: "agent:main:test-agent", context: nil),
            "work": SessionState(sessionId: "work", sessionKey: "agent:main:work", context: nil),
        ]

        // 测试已存在的名字
        XCTAssertTrue(SessionConfig.isNameTaken(name: "Test Agent", existingSessions: sessions))
        XCTAssertTrue(SessionConfig.isNameTaken(name: "Work", existingSessions: sessions))

        // 测试不存在的名字
        XCTAssertFalse(SessionConfig.isNameTaken(name: "New Session", existingSessions: sessions))
    }

    func testGenerateSessionKey() {
        let sessionKey = SessionConfig.generateSessionKey(sessionId: "test-agent")
        XCTAssertEqual(sessionKey, "agent:main:test-agent")
    }

    func testSessionConfigInitialization() {
        let config = SessionConfig(
            id: "test-id",
            sessionKey: "agent:main:test-id",
            createdAt: Date(),
            name: "Test Session",
            icon: "T",
            context: "Test context"
        )

        XCTAssertEqual(config.id, "test-id")
        XCTAssertEqual(config.sessionKey, "agent:main:test-id")
        XCTAssertEqual(config.name, "Test Session")
        XCTAssertEqual(config.icon, "T")
        XCTAssertEqual(config.context, "Test context")
    }

    func testSessionConfigIsEmpty() {
        let emptyConfig = SessionConfig(
            id: "",
            sessionKey: "",
            createdAt: Date(),
            name: nil,
            icon: nil,
            context: nil
        )
        XCTAssertTrue(emptyConfig.isEmpty)

        let nonEmptyConfig = SessionConfig(
            id: "test",
            sessionKey: "agent:main:test",
            createdAt: Date(),
            name: "Test",
            icon: nil,
            context: nil
        )
        XCTAssertFalse(nonEmptyConfig.isEmpty)
    }
}
