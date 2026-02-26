// DeckViewModelTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/26.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation
import Testing

@Suite
struct DeckViewModelTests {

  /// 创建干净的 UserDefaultsStorage 用于测试
  private func makeStorage() -> UserDefaultsStorage {
    let suiteName = "test.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)
    precondition(defaults != nil, "Failed to create UserDefaults with suiteName: \(suiteName)")
    return UserDefaultsStorage(defaults: defaults!)
  }

  @Test
  func testInitialStatus() {
    let storage = makeStorage()
    let viewModel = DeckViewModel(storage: storage)

    // 注意：DeckViewModel 会自动创建 welcome session
    #expect(viewModel.sessions.count == 1)
    #expect(viewModel.sessionOrder.count == 1)
    #expect(viewModel.gatewayConnected == false)
    #expect(viewModel.isInitializing == false)
  }

  @Test
  func testCreateSession() {
    let storage = makeStorage()
    let viewModel = DeckViewModel(storage: storage)

    let config = viewModel.createSession(
      name: "Research Agent",
      icon: "R",
      context: "Research context"
    )

    #expect(config.name == "Research Agent")
    #expect(config.sessionKey.hasPrefix("agent:main:"))
    #expect(viewModel.sessions.count == 2)  // 1 (welcome) + 1 (new)
    #expect(viewModel.sessionOrder.count == 2)
  }

  @Test
  func testCreateSession_generatesUniqueIds() {
    let storage = makeStorage()
    let viewModel = DeckViewModel(storage: storage)

    let config1 = viewModel.createSession(name: "Test")
    let config2 = viewModel.createSession(name: "Test")

    // 由于 generateId 添加了随机 hash，ID 应该不同
    #expect(config1.id != config2.id)
  }

  @Test
  func testDeleteSession() {
    let storage = makeStorage()
    let viewModel = DeckViewModel(storage: storage)

    let config = viewModel.createSession(name: "Test Session")
    #expect(viewModel.sessions.count == 2)  // 1 (welcome) + 1 (new)

    viewModel.deleteSession(sessionId: config.id)

    // 删除后应该还有 welcome session
    #expect(viewModel.sessions.count == 1)
    #expect(viewModel.sessionOrder.count == 1)
  }

  @Test
  func testDeleteSession_createsWelcomeSession() {
    let storage = makeStorage()
    let viewModel = DeckViewModel(storage: storage)

    let config = viewModel.createSession(name: "Test Session")
    viewModel.deleteSession(sessionId: config.id)

    // 删除后应该自动创建/保留 welcome session
    #expect(viewModel.sessions.count == 1)
  }

  @Test
  func testGetSession() {
    let storage = makeStorage()
    let viewModel = DeckViewModel(storage: storage)

    let config = viewModel.createSession(name: "Test")
    let session = viewModel.getSession(sessionId: config.id)

    #expect(session != nil)
    #expect(session?.sessionId == config.id)
  }

  @Test
  func testGetSession_notFound() {
    let storage = makeStorage()
    let viewModel = DeckViewModel(storage: storage)

    let session = viewModel.getSession(sessionId: "non-existent")
    #expect(session == nil)
  }

  @Test
  func testSessionOrder() {
    let storage = makeStorage()
    let viewModel = DeckViewModel(storage: storage)

    // 初始有 welcome session
    #expect(viewModel.sessionOrder.count == 1)
    let welcomeId = viewModel.sessionOrder[0]
    #expect(welcomeId.hasPrefix("welcome-"))

    let config1 = viewModel.createSession(name: "Session A")
    let config2 = viewModel.createSession(name: "Session B")
    let config3 = viewModel.createSession(name: "Session C")

    #expect(viewModel.sessionOrder.count == 4)  // 1 (welcome) + 3 (new)
    #expect(viewModel.sessionOrder[0] == welcomeId)
    #expect(viewModel.sessionOrder[1] == config1.id.lowercased())
    #expect(viewModel.sessionOrder[2] == config2.id.lowercased())
    #expect(viewModel.sessionOrder[3] == config3.id.lowercased())
  }

  @Test
  func testClearConnectionError() {
    let storage = makeStorage()
    let viewModel = DeckViewModel(storage: storage)

    // 测试方法存在且可以调用
    viewModel.clearConnectionError()
    #expect(viewModel.connectionError == nil)
  }

  @Test
  func testDisconnect() async {
    let storage = makeStorage()
    let viewModel = DeckViewModel(storage: storage)

    // 测试方法存在且可以调用
    viewModel.disconnect()
    #expect(viewModel.gatewayConnected == false)
  }

  @Test
  func testSendMessage_gatewayNotConnected() async {
    let storage = makeStorage()
    let viewModel = DeckViewModel(storage: storage)

    let config = viewModel.createSession(name: "Test")

    // 在网关未连接时发送消息应该不会崩溃
    await viewModel.sendMessage(sessionId: config.id, text: "Hello")

    // 消息不应该被添加（因为网关未连接）
    #expect(viewModel.sessions[config.id.lowercased()]?.messages.isEmpty == true)
  }

  @Test
  func testHandleGatewayEvent_unknownEvent() {
    let storage = makeStorage()
    let viewModel = DeckViewModel(storage: storage)

    // 创建一个测试事件
    let event = GatewayEvent(event: "unknown.event", payload: nil)

    // 处理未知事件不应该崩溃
    viewModel.handleGatewayEvent(event)
  }

  @Test
  func testHandleGatewayEvent_tickEvent() {
    let storage = makeStorage()
    let viewModel = DeckViewModel(storage: storage)

    // 忽略 tick 事件
    let event = GatewayEvent(event: "tick", payload: nil)
    viewModel.handleGatewayEvent(event)
  }

  @Test
  func testHandleGatewayEvent_healthEvent() {
    let storage = makeStorage()
    let viewModel = DeckViewModel(storage: storage)

    // 忽略 health 事件
    let event = GatewayEvent(event: "health", payload: nil)
    viewModel.handleGatewayEvent(event)
  }
}
