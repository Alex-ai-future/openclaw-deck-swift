// UserDefaultsStorageTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/26.
// Copyright © 2026 OpenClaw. All rights reserved.

import XCTest

@testable import openclaw_deck_swift

@MainActor
final class UserDefaultsStorageTests: XCTestCase {

  var storage: MockUserDefaultsStorage!

  override func setUp() async throws {
    try await super.setUp()
    // 使用 Mock 存储，完全隔离测试
    storage = MockUserDefaultsStorage()
  }

  override func tearDown() async throws {
    storage = nil
    try await super.tearDown()
  }

  // MARK: - Gateway URL Tests

  func testSaveGatewayUrl() {
    let url = "ws://localhost:8080"
    storage.saveGatewayUrl(url)

    let savedUrl = storage.loadGatewayUrl()
    XCTAssertEqual(savedUrl, url)
  }

  func testLoadGatewayUrl_whenNotSet() {
    let url = storage.loadGatewayUrl()
    XCTAssertNil(url)
  }

  func testSaveGatewayUrl_overwritesPrevious() {
    storage.saveGatewayUrl("ws://localhost:8080")
    storage.saveGatewayUrl("ws://localhost:9090")

    let savedUrl = storage.loadGatewayUrl()
    XCTAssertEqual(savedUrl, "ws://localhost:9090")
  }

  // MARK: - Token Tests

  func testSaveToken() {
    let token = "test-token-123"
    storage.saveToken(token)

    let savedToken = storage.loadToken()
    XCTAssertEqual(savedToken, token)
  }

  func testLoadToken_whenNotSet() {
    let token = storage.loadToken()
    XCTAssertNil(token)
  }

  func testSaveToken_overwritesPrevious() {
    storage.saveToken("token-1")
    storage.saveToken("token-2")

    let savedToken = storage.loadToken()
    XCTAssertEqual(savedToken, "token-2")
  }

  // MARK: - Session Tests

  func testSaveAndLoadSessions() {
    let sessions = [
      SessionConfig(
        id: "session-1",
        sessionKey: "agent:main:session-1",
        createdAt: Date(),
        name: "Session 1",
        icon: "S1",
        context: "Test session 1"
      ),
      SessionConfig(
        id: "session-2",
        sessionKey: "agent:main:session-2",
        createdAt: Date(),
        name: "Session 2",
        icon: "S2",
        context: "Test session 2"
      ),
    ]

    storage.saveSessions(sessions)

    let loadedSessions = storage.loadSessions()
    XCTAssertEqual(loadedSessions.count, 2)
    XCTAssertEqual(loadedSessions[0].id, "session-1")
    XCTAssertEqual(loadedSessions[1].id, "session-2")
  }

  func testLoadSessions_whenNotSet() {
    let sessions = storage.loadSessions()
    XCTAssertEqual(sessions.count, 0)
  }

  func testSaveEmptySessions() {
    storage.saveSessions([])

    let loadedSessions = storage.loadSessions()
    XCTAssertTrue(loadedSessions.isEmpty)
  }

  // MARK: - Session Order Tests

  func testSaveAndLoadSessionOrder() {
    let order = ["session-2", "session-1", "session-3"]
    storage.saveSessionOrder(order)

    let loadedOrder = storage.loadSessionOrder()
    XCTAssertEqual(loadedOrder, order)
  }

  func testLoadSessionOrder_whenNotSet() {
    let order = storage.loadSessionOrder()
    XCTAssertTrue(order.isEmpty)
  }

  // MARK: - Integration Tests

  func testFullConfigurationPersistence() {
    // Save configuration
    storage.saveGatewayUrl("ws://localhost:8080")
    storage.saveToken("my-token")

    let sessions = [
      SessionConfig(
        id: "test-session",
        sessionKey: "agent:main:test-session",
        createdAt: Date(),
        name: "Test",
        icon: "T",
        context: "Test context"
      )
    ]
    storage.saveSessions(sessions)
    storage.saveSessionOrder(["test-session"])

    // Verify all data
    XCTAssertEqual(storage.loadGatewayUrl(), "ws://localhost:8080")
    XCTAssertEqual(storage.loadToken(), "my-token")

    let loadedSessions = storage.loadSessions()
    XCTAssertEqual(loadedSessions.count, 1)
    XCTAssertEqual(loadedSessions[0].id, "test-session")

    XCTAssertEqual(storage.loadSessionOrder(), ["test-session"])
  }

  func testClearAllData() {
    // Save some data
    storage.saveGatewayUrl("ws://localhost:8080")
    storage.saveToken("token")
    storage.saveSessions([
      SessionConfig(
        id: "test",
        sessionKey: "agent:main:test",
        createdAt: Date(),
        name: "Test",
        icon: nil,
        context: nil
      )
    ])
    storage.saveSessionOrder(["test"])

    // Clear using mock's clear method
    storage.clear()

    // Verify all cleared
    XCTAssertNil(storage.loadGatewayUrl())
    XCTAssertNil(storage.loadToken())
    XCTAssertEqual(storage.loadSessions().count, 0)
    XCTAssertEqual(storage.loadSessionOrder().count, 0)
  }
}
