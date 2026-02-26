// GatewayClientTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/26.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation
import Testing

@Suite
struct GatewayClientTests {

  @Test
  func testInitialStatus() {
    let client = GatewayClient(
      url: URL(string: "ws://localhost:8080")!,
      token: nil,
      isMock: true
    )

    #expect(client.connected == false)
    #expect(client.isConnecting == false)
    #expect(client.connectionError == nil)
  }

  @Test
  func testMockConnection() async {
    let client = GatewayClient(
      url: URL(string: "ws://localhost:8080")!,
      token: nil,
      isMock: true
    )

    await client.connect()

    #expect(client.connected == true)
  }

  @Test
  func testDisconnect() async {
    let client = GatewayClient(
      url: URL(string: "ws://localhost:8080")!,
      token: nil,
      isMock: true
    )

    await client.connect()
    #expect(client.connected == true)

    client.disconnect()
    #expect(client.connected == false)
  }

  @Test
  func testClearError() {
    let client = GatewayClient(
      url: URL(string: "ws://localhost:8080")!,
      token: nil,
      isMock: true
    )

    // 手动设置错误（通过 KVC 或其他方式）
    // 这里测试 clearError 方法存在且可以调用
    client.clearError()
    #expect(client.connectionError == nil)
  }

  @Test
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

    #expect(runId.hasPrefix("mock-run-"))
    #expect(status == "success")
  }

  @Test
  func testConnectionCallback() async {
    let client = GatewayClient(
      url: URL(string: "ws://localhost:8080")!,
      token: nil,
      isMock: true
    )

    var connectionChangedCount = 0
    client.onConnection = { connected in
      connectionChangedCount += 1
    }

    await client.connect()
    #expect(connectionChangedCount >= 1)
  }

  @Test
  func testNextIdGeneration() async {
    let client = GatewayClient(
      url: URL(string: "ws://localhost:8080")!,
      token: nil,
      isMock: true
    )

    // 通过调用 request 方法来测试 ID 生成（在 mock 模式下）
    await client.connect()

    // 连续调用应该生成不同的 ID
    let (runId1, _) = try await client.runAgent(agentId: "main", message: "Msg1")
    let (runId2, _) = try await client.runAgent(agentId: "main", message: "Msg2")

    #expect(runId1 != runId2)
  }

  @Test
  func testResetDeviceIdentity() {
    let client = GatewayClient(
      url: URL(string: "ws://localhost:8080")!,
      token: nil,
      isMock: true
    )

    // 测试方法存在且可以调用
    client.resetDeviceIdentity()
  }
}
