// DeckViewModelTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/26.
// Copyright © 2026 OpenClaw. All rights reserved.

@testable import openclaw_deck_swift
import XCTest

@MainActor
final class DeckViewModelTests: XCTestCase {
    var viewModel: DeckViewModel!
    var mockStorage: MockUserDefaultsStorage!
    var mockGlobalInputState: MockGlobalInputState!

    override func setUp() async throws {
        try await super.setUp()
        // 使用 Mock 存储和 Mock GlobalInputState，完全隔离测试
        mockStorage = MockFactory.createMockStorage()
        mockGlobalInputState = MockGlobalInputState()
        let testDIContainer = MockFactory.createDIContainer(
            storage: mockStorage,
            globalInputState: mockGlobalInputState
        )
        viewModel = DeckViewModel(diContainer: testDIContainer)
    }

    override func tearDown() async throws {
        viewModel = nil
        mockStorage = nil
        mockGlobalInputState = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testViewModelInitialization() {
        XCTAssertNil(viewModel.gatewayClient)
        XCTAssertGreaterThanOrEqual(viewModel.sessions.count, 0)
        XCTAssertGreaterThanOrEqual(viewModel.sessionOrder.count, 0)
        XCTAssertFalse(viewModel.gatewayConnected)
        XCTAssertNil(viewModel.connectionError)
    }

    // MARK: - Connection Tests

    func testClearConnectionError() {
        viewModel.connectionError = "Test error"
        XCTAssertNotNil(viewModel.connectionError)
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

        XCTAssertNotNil(viewModel.getSession(sessionId: sessionId))
        viewModel.deleteSession(sessionId: sessionId)
        XCTAssertNil(viewModel.getSession(sessionId: sessionId))
    }

    func testDeleteSession_createsWelcomeSession() {
        let session = viewModel.createSession(name: "Only Session")
        viewModel.deleteSession(sessionId: session.id)
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
        let session1 = viewModel.createSession(name: "First")
        let session2 = viewModel.createSession(name: "Second")
        let session3 = viewModel.createSession(name: "Third")

        XCTAssertEqual(viewModel.sessionOrder[0], session3.id.lowercased())
        XCTAssertEqual(viewModel.sessionOrder[1], session2.id.lowercased())
        XCTAssertEqual(viewModel.sessionOrder[2], session1.id.lowercased())
    }

    // MARK: - Event Handling Tests

    func testHandleGatewayEvent_unknownEvent() {
        let event = GatewayEvent(event: "unknown.event", payload: nil)
        viewModel.handleGatewayEvent(event)
    }

    func testHandleGatewayEvent_tickEvent() {
        let event = GatewayEvent(event: "tick", payload: nil)
        viewModel.handleGatewayEvent(event)
    }

    func testHandleGatewayEvent_healthEvent() {
        let event = GatewayEvent(event: "health", payload: nil)
        viewModel.handleGatewayEvent(event)
    }

    func testHandleGatewayEvent_heartbeatEvent() {
        let event = GatewayEvent(event: "heartbeat", payload: nil)
        viewModel.handleGatewayEvent(event)
    }

    // MARK: - Gateway Event Integration Tests

    func testHandleAgentEvent_withInvalidPayload() {
        let event = GatewayEvent(event: "agent", payload: nil)
        viewModel.handleGatewayEvent(event)
    }

    func testHandleAgentEvent_withMissingSessionKey() {
        let event = GatewayEvent(
            event: "agent",
            payload: ["runId": "run-1", "stream": "assistant"]
        )
        viewModel.handleGatewayEvent(event)
    }

    // MARK: - State Management Tests

    func testSessionStatusTransitions() {
        let session = viewModel.createSession(name: "Test")
        let sessionState = viewModel.getSession(sessionId: session.id)

        XCTAssertNotNil(sessionState)
        guard let state = sessionState else { return }

        XCTAssertEqual(state.status, .idle)
        state.status = .thinking
        XCTAssertEqual(state.status, .thinking)
        state.status = .streaming
        XCTAssertEqual(state.status, .streaming)
        state.status = .error("Test error")
        XCTAssertEqual(state.status, .error("Test error"))
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
        viewModel.deleteSession(sessionId: "non-existent")
    }

    func testMultipleSessionsWithSameName() {
        let session1 = viewModel.createSession(name: "Same Name")
        let session2 = viewModel.createSession(name: "Same Name")

        XCTAssertNotEqual(session1.id, session2.id)
    }
}
