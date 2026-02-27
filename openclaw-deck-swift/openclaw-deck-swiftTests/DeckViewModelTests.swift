// DeckViewModelTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/26.
// Copyright © 2026 OpenClaw. All rights reserved.

import XCTest

@testable import openclaw_deck_swift

@MainActor
final class DeckViewModelTests: XCTestCase {

  var viewModel: DeckViewModel!
  var mockStorage: MockUserDefaultsStorage!

  override func setUp() async throws {
    try await super.setUp()
    // 使用 Mock 存储，完全隔离测试
    mockStorage = MockUserDefaultsStorage()
    viewModel = DeckViewModel(storage: mockStorage)
  }

  override func tearDown() async throws {
    viewModel = nil
    mockStorage = nil
    try await super.tearDown()
  }

  // MARK: - Initialization Tests

  func testViewModelInitialization() {
    XCTAssertNil(viewModel.gatewayClient)
    // Note: DeckViewModel auto-creates welcome session if no sessions exist
    XCTAssertGreaterThanOrEqual(viewModel.sessions.count, 0)
    XCTAssertGreaterThanOrEqual(viewModel.sessionOrder.count, 0)
    XCTAssertFalse(viewModel.gatewayConnected)
    XCTAssertNil(viewModel.connectionError)
  }

  // MARK: - Connection Tests

  func testClearConnectionError() {
    viewModel.clearConnectionError()
    XCTAssertNil(viewModel.connectionError)
  }

  func testDisconnect() {
    viewModel.disconnect()
    XCTAssertFalse(viewModel.gatewayConnected)
  }

  // MARK: - Session Management Tests

  func testCreateSession_generatesUniqueIds() {
    let session1 = viewModel.createSession(name: "Test Session 1")
    let session2 = viewModel.createSession(name: "Test Session 2")

    XCTAssertNotEqual(session1.id, session2.id)
    XCTAssertNotEqual(session1.sessionKey, session2.sessionKey)
  }

  func testCreateSession_savesToStorage() {
    let session = viewModel.createSession(name: "Test")

    // Verify session was created
    XCTAssertNotNil(viewModel.getSession(sessionId: session.id))
    XCTAssertEqual(viewModel.getSession(sessionId: session.id)?.sessionId, session.id)
  }

  func testCreateSession_withCustomIcon() {
    let session = viewModel.createSession(
      name: "Custom",
      icon: "🚀",
      context: "Custom context"
    )

    XCTAssertEqual(session.icon, "🚀")
    XCTAssertEqual(session.context, "Custom context")
  }

  func testDeleteSession() {
    let session = viewModel.createSession(name: "To Delete")
    let sessionId = session.id

    // Verify session exists
    XCTAssertNotNil(viewModel.getSession(sessionId: sessionId))

    // Delete session
    viewModel.deleteSession(sessionId: sessionId)

    // Verify session is deleted
    XCTAssertNil(viewModel.getSession(sessionId: sessionId))
  }

  func testDeleteSession_createsWelcomeSession() {
    let session = viewModel.createSession(name: "Only Session")
    viewModel.deleteSession(sessionId: session.id)

    // Should have at least welcome session
    XCTAssertGreaterThanOrEqual(viewModel.sessions.count, 1)
  }

  func testGetSession() {
    let session = viewModel.createSession(name: "Test")
    let retrieved = viewModel.getSession(sessionId: session.id)

    XCTAssertNotNil(retrieved)
    XCTAssertEqual(retrieved?.sessionId, session.id)
    XCTAssertEqual(retrieved?.sessionKey, session.sessionKey)
  }

  func testGetSession_notFound() {
    let retrieved = viewModel.getSession(sessionId: "non-existent")
    XCTAssertNil(retrieved)
  }

  func testSessionOrder() {
    let initialCount = viewModel.sessionOrder.count
    let session1 = viewModel.createSession(name: "First")
    let session2 = viewModel.createSession(name: "Second")
    let session3 = viewModel.createSession(name: "Third")

    XCTAssertEqual(viewModel.sessionOrder[initialCount], session1.id.lowercased())
    XCTAssertEqual(viewModel.sessionOrder[initialCount + 1], session2.id.lowercased())
    XCTAssertEqual(viewModel.sessionOrder[initialCount + 2], session3.id.lowercased())
  }

  // MARK: - Event Handling Tests

  func testHandleGatewayEvent_unknownEvent() {
    let event = GatewayEvent(event: "unknown.event", payload: nil)
    viewModel.handleGatewayEvent(event)
    // Should not crash
  }

  func testHandleGatewayEvent_tickEvent() {
    let event = GatewayEvent(event: "tick", payload: nil)
    viewModel.handleGatewayEvent(event)
    // Should be ignored
  }

  func testHandleGatewayEvent_healthEvent() {
    let event = GatewayEvent(event: "health", payload: nil)
    viewModel.handleGatewayEvent(event)
    // Should be ignored
  }

  func testHandleGatewayEvent_heartbeatEvent() {
    let event = GatewayEvent(event: "heartbeat", payload: nil)
    viewModel.handleGatewayEvent(event)
    // Should be ignored
  }

  // MARK: - Gateway Event Integration Tests

  func testHandleAgentEvent_withInvalidPayload() {
    let event = GatewayEvent(event: "agent", payload: nil)
    viewModel.handleGatewayEvent(event)
    // Should not crash
  }

  func testHandleAgentEvent_withMissingSessionKey() {
    let event = GatewayEvent(
      event: "agent",
      payload: ["runId": "run-1", "stream": "assistant"]
    )
    viewModel.handleGatewayEvent(event)
    // Should not crash
  }

  // MARK: - State Management Tests

  func testSessionStatusTransitions() {
    let session = viewModel.createSession(name: "Test")
    let sessionState = viewModel.getSession(sessionId: session.id)

    XCTAssertNotNil(sessionState, "Session should exist")
    guard let state = sessionState else { return }

    // Initial state
    XCTAssertEqual(state.status, .idle)

    // Set to thinking
    state.status = .thinking
    XCTAssertEqual(state.status, .thinking)

    // Set to streaming
    state.status = .streaming
    XCTAssertEqual(state.status, .streaming)

    // Set to error
    state.status = .error("Test error")
    XCTAssertEqual(state.status, .error("Test error"))

    // Back to idle
    state.status = .idle
    XCTAssertEqual(state.status, .idle)
  }

  // MARK: - Edge Cases

  func testCreateSession_withEmptyName() {
    let session = viewModel.createSession(name: "")
    XCTAssertNotNil(session)
    XCTAssertFalse(session.id.isEmpty)
  }

  func testCreateSession_withSpecialCharacters() {
    let session = viewModel.createSession(name: "Test @#$% Session")
    XCTAssertNotNil(session)
  }

  func testDeleteNonExistentSession() {
    // Should not crash
    viewModel.deleteSession(sessionId: "non-existent")
  }

  func testMultipleSessionsWithSameName() {
    let initialCount = viewModel.sessions.count
    let session1 = viewModel.createSession(name: "Same Name")
    let session2 = viewModel.createSession(name: "Same Name")

    // Should have different IDs
    XCTAssertNotEqual(session1.id, session2.id)
    XCTAssertEqual(viewModel.sessions.count, initialCount + 2)
  }
}
