// GatewayClientTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/26.
// Copyright © 2026 OpenClaw. All rights reserved.

@testable import openclaw_deck_swift
import XCTest

@MainActor
final class GatewayClientTests: XCTestCase {
    // MARK: - Initialization Tests

    func testInitialStatus() throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        XCTAssertFalse(client.connected)
        XCTAssertFalse(client.isConnecting)
        XCTAssertNil(client.connectionError)
    }

    // MARK: - Connection Tests

    func testMockConnection() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        await client.connect()
        XCTAssertTrue(client.connected)
    }

    func testDisconnect() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        await client.connect()
        XCTAssertTrue(client.connected)

        client.disconnect()
        XCTAssertFalse(client.connected)
    }

    func testDisconnectWithoutConnect() throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        client.disconnect()
        XCTAssertFalse(client.connected)
    }

    func testClearError() throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        client.clearError()
        XCTAssertNil(client.connectionError)
    }

    // MARK: - Agent Tests

    func testMockRunAgent() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        await client.connect()

        let (runId, status) = try await client.runAgent(
            agentId: "main",
            message: "Hello",
            sessionKey: "agent:main:test"
        )

        XCTAssertTrue(runId.hasPrefix("mock-run-"))
        XCTAssertEqual(status, "success")
    }

    func testMockRunAgentWithoutSessionKey() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        await client.connect()

        let (runId, status) = try await client.runAgent(
            agentId: "main",
            message: "Hello"
        )

        XCTAssertTrue(runId.hasPrefix("mock-run-"))
        XCTAssertEqual(status, "success")
    }

    func testRunAgentGeneratesIdempotencyKey() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        await client.connect()

        let (runId1, _) = try await client.runAgent(agentId: "main", message: "Msg1")
        let (runId2, _) = try await client.runAgent(agentId: "main", message: "Msg2")

        XCTAssertNotEqual(runId1, runId2)
    }

    // MARK: - State Tests

    func testConnectedState() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        XCTAssertFalse(client.connected)

        await client.connect()
        XCTAssertTrue(client.connected)

        client.disconnect()
        XCTAssertFalse(client.connected)
    }

    func testMultipleConnectDisconnectCycles() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        for _ in 0 ..< 3 {
            await client.connect()
            XCTAssertTrue(client.connected)
            client.disconnect()
            XCTAssertFalse(client.connected)
        }
    }

    // MARK: - Utility Tests

    func testResetDeviceIdentity() throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        client.resetDeviceIdentity()
    }

    // MARK: - Full Workflow Test

    func testFullWorkflow() async throws {
        let client = try GatewayClient(
            url: XCTUnwrap(URL(string: "ws://localhost:8080")),
            token: nil,
            webSocket: MockWebSocketConnection()
        )

        await client.connect()
        XCTAssertTrue(client.connected)

        let (runId, status) = try await client.runAgent(
            agentId: "main",
            message: "Test message",
            sessionKey: "agent:main:test"
        )

        XCTAssertEqual(status, "success")
        XCTAssertTrue(runId.hasPrefix("mock-run-"))

        client.disconnect()
        XCTAssertFalse(client.connected)
    }
}
