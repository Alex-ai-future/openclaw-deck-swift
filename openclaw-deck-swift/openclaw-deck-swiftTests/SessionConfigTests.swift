// SessionConfigTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/26.
// Copyright © 2026 OpenClaw. All rights reserved.

import XCTest
@testable import openclaw_deck_swift

final class SessionConfigTests: XCTestCase {

  func testGenerateId_withNormalName() {
    let sessionId = SessionConfig.generateId(from: "Research Agent")
    XCTAssertTrue(sessionId.hasPrefix("research-agent-"))
  }

  func testGenerateId_withSpecialCharacters() {
    let sessionId = SessionConfig.generateId(from: "Test @#$% Agent")
    XCTAssertTrue(sessionId.hasPrefix("test-agent-"))
  }

  func testGenerateId_withEmptyName() {
    let sessionId = SessionConfig.generateId(from: "")
    XCTAssertTrue(sessionId.hasPrefix("session-"))
  }

  func testGenerateId_isUnique() {
    let id1 = SessionConfig.generateId(from: "Test")
    let id2 = SessionConfig.generateId(from: "Test")
    XCTAssertNotEqual(id1, id2)
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
