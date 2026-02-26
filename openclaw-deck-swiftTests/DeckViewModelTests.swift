// DeckViewModelTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/26.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation
import Testing

@Suite
struct DeckViewModelTests {

  @Test
  func testInitialStatus() {
    let viewModel = DeckViewModel()

    #expect(viewModel.sessions.isEmpty == true)
    #expect(viewModel.sessionOrder.isEmpty == true)
    #expect(viewModel.gatewayConnected == false)
    #expect(viewModel.isInitializing == false)
  }

  @Test
  func testCreateSession() {
    let viewModel = DeckViewModel()

    let config = viewModel.createSession(
      name: "Research Agent",
      icon: "R",
      context: "Research context"
    )

    #expect(config.name == "Research Agent")
    #expect(config.sessionKey.hasPrefix("agent:main:"))
    #expect(viewModel.sessions.count == 1)
    #expect(viewModel.sessionOrder.count == 1)
  }

  @Test
  func testCreateSession_generatesUniqueIds() {
    let viewModel = DeckViewModel()

    let config1 = viewModel.createSession(name: "Test")
    let config2 = viewModel.createSession(name: "Test")

    // 由于 generateId 添加了随机 hash，ID 应该不同
    #expect(config1.id != config2.id)
  }

  @Test
  func testDeleteSession() {
    let viewModel = DeckViewModel()

    let config = viewModel.createSession(name: "Test Session")
    #expect(viewModel.sessions.count == 1)

    viewModel.deleteSession(sessionId: config.id)

    #expect(viewModel.sessions.isEmpty == true)
    #expect(viewModel.sessionOrder.isEmpty == true)
  }

  @Test
  func testDeleteSession_createsWelcomeSession() {
    let viewModel = DeckViewModel()

    let config = viewModel.createSession(name: "Test Session")
    viewModel.deleteSession(sessionId: config.id)

    // 删除后应该自动创建 welcome session
    #expect(viewModel.sessions.count == 1)
  }

  @Test
  func testGetSession() {
    let viewModel = DeckViewModel()

    let config = viewModel.createSession(name: "Test")
    let session = viewModel.getSession(sessionId: config.id)

    #expect(session != nil)
    #expect(session?.sessionId == config.id)
  }

  @Test
  func testGetSession_notFound() {
    let viewModel = DeckViewModel()

    let session = viewModel.getSession(sessionId: "non-existent")
    #expect(session == nil)
  }

  @Test
  func testSessionOrder() {
    let viewModel = DeckViewModel()

    let config1 = viewModel.createSession(name: "Session A")
    let config2 = viewModel.createSession(name: "Session B")
    let config3 = viewModel.createSession(name: "Session C")

    #expect(viewModel.sessionOrder.count == 3)
    #expect(viewModel.sessionOrder[0] == config1.id.lowercased())
    #expect(viewModel.sessionOrder[1] == config2.id.lowercased())
    #expect(viewModel.sessionOrder[2] == config3.id.lowercased())
  }

  @Test
  func testClearConnectionError() {
    let viewModel = DeckViewModel()

    // 测试方法存在且可以调用
    viewModel.clearConnectionError()
    #expect(viewModel.connectionError == nil)
  }

  @Test
  func testDisconnect() async {
    let viewModel = DeckViewModel()

    // 测试方法存在且可以调用
    viewModel.disconnect()
    #expect(viewModel.gatewayConnected == false)
  }

  @Test
  func testSendMessage_gatewayNotConnected() async {
    let viewModel = DeckViewModel()

    let config = viewModel.createSession(name: "Test")

    // 在网关未连接时发送消息应该不会崩溃
    await viewModel.sendMessage(sessionId: config.id, text: "Hello")

    // 消息不应该被添加（因为网关未连接）
    #expect(viewModel.sessions[config.id.lowercased()]?.messages.isEmpty == true)
  }

  @Test
  func testHandleGatewayEvent_unknownEvent() {
    let viewModel = DeckViewModel()

    // 创建一个测试事件
    let event = GatewayEvent(event: "unknown.event", payload: nil)

    // 处理未知事件不应该崩溃
    viewModel.handleGatewayEvent(event)
  }

  @Test
  func testHandleGatewayEvent_tickEvent() {
    let viewModel = DeckViewModel()

    // 忽略 tick 事件
    let event = GatewayEvent(event: "tick", payload: nil)
    viewModel.handleGatewayEvent(event)
  }

  @Test
  func testHandleGatewayEvent_healthEvent() {
    let viewModel = DeckViewModel()

    // 忽略 health 事件
    let event = GatewayEvent(event: "health", payload: nil)
    viewModel.handleGatewayEvent(event)
  }
}
