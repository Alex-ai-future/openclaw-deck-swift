// GatewayClientTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/26.
// Copyright © 2026 OpenClaw. All rights reserved.

import XCTest

@testable import openclaw_deck_swift

@MainActor
final class GatewayClientTests: XCTestCase {

  // MARK: - Initialization Tests

  func testInitialStatus() {
    let client = GatewayClient(
      url: URL(string: "ws://localhost:8080")!,
      token: nil,
      isMock: true
    )

    XCTAssertFalse(client.connected)
    XCTAssertFalse(client.isConnecting)
    XCTAssertNil(client.connectionError)
  }

  // MARK: - Connection Tests

  func testMockConnection() async {
    let client = GatewayClient(
      url: URL(string: "ws://localhost:8080")!,
      token: nil,
      isMock: true
    )

    await client.connect()
    XCTAssertTrue(client.connected)
  }

  func testDisconnect() async {
    let client = GatewayClient(
      url: URL(string: "ws://localhost:8080")!,
      token: nil,
      isMock: true
    )

    await client.connect()
    XCTAssertTrue(client.connected)

    client.disconnect()
    XCTAssertFalse(client.connected)
  }

  func testDisconnectWithoutConnect() {
    let client = GatewayClient(
      url: URL(string: "ws://localhost:8080")!,
      token: nil,
      isMock: true
    )

    client.disconnect()
    XCTAssertFalse(client.connected)
  }

  func testClearError() {
    let client = GatewayClient(
      url: URL(string: "ws://localhost:8080")!,
      token: nil,
      isMock: true
    )

    client.clearError()
    XCTAssertNil(client.connectionError)
  }

  // MARK: - Agent Tests

  func testMockRunAgent() async throws {
    let client = GatewayClient(
      url: URL(string: "ws://localhost:8080")!,
      token: nil,
      isMock: true
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
    let client = GatewayClient(
      url: URL(string: "ws://localhost:8080")!,
      token: nil,
      isMock: true
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
    let client = GatewayClient(
      url: URL(string: "ws://localhost:8080")!,
      token: nil,
      isMock: true
    )

    await client.connect()

    let (runId1, _) = try await client.runAgent(agentId: "main", message: "Msg1")
    let (runId2, _) = try await client.runAgent(agentId: "main", message: "Msg2")

    XCTAssertNotEqual(runId1, runId2)
  }

  // MARK: - State Tests

  func testConnectedState() async {
    let client = GatewayClient(
      url: URL(string: "ws://localhost:8080")!,
      token: nil,
      isMock: true
    )

    XCTAssertFalse(client.connected)

    await client.connect()
    XCTAssertTrue(client.connected)

    client.disconnect()
    XCTAssertFalse(client.connected)
  }

  func testMultipleConnectDisconnectCycles() async {
    let client = GatewayClient(
      url: URL(string: "ws://localhost:8080")!,
      token: nil,
      isMock: true
    )

    for _ in 0..<3 {
      await client.connect()
      XCTAssertTrue(client.connected)
      client.disconnect()
      XCTAssertFalse(client.connected)
    }
  }

  // MARK: - Utility Tests

  func testResetDeviceIdentity() {
    let client = GatewayClient(
      url: URL(string: "ws://localhost:8080")!,
      token: nil,
      isMock: true
    )

    client.resetDeviceIdentity()
  }

  // MARK: - Full Workflow Test

  func testFullWorkflow() async throws {
    let client = GatewayClient(
      url: URL(string: "ws://localhost:8080")!,
      token: nil,
      isMock: true
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
