// DeckViewModelTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/26.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation
import Testing

@testable import openclaw_deck_swift

/// DeckViewModel 测试套件 - 使用 .serialized 确保测试串行执行
@Suite(.serialized)
@MainActor
struct DeckViewModelTests {

  /// 为测试创建独立的 UserDefaultsStorage
  /// 每个测试使用唯一的 suite name 确保完全隔离
  private func createMockStorage() -> UserDefaultsStorage {
    let suiteName = "test.openclaw.deck.\(UUID().uuidString)"
    let userDefaults = UserDefaults(suiteName: suiteName)!
    let storage = UserDefaultsStorage(defaults: userDefaults)

    // 清除任何现有数据
    storage.clearAll()

    // 预先保存空数据，避免 DeckViewModel 自动创建 welcome session
    storage.saveSessions([])
    storage.saveSessionOrder([])

    return storage
  }

  @Test
  func testInitialStatus() async throws {
    let mockStorage = createMockStorage()
    let viewModel = DeckViewModel(storage: mockStorage)

    #expect(viewModel.sessions.isEmpty == true)
    #expect(viewModel.sessionOrder.isEmpty == true)
    #expect(viewModel.gatewayConnected == false)
    #expect(viewModel.isInitializing == false)
  }

  @Test
  func testCreateSession() async throws {
    let mockStorage = createMockStorage()
    let viewModel = DeckViewModel(storage: mockStorage)

    let config = viewModel.createSession(
      name: "Test Research Agent",
      icon: "R",
      context: "Research context"
    )

    #expect(config.name == "Test Research Agent")
    #expect(config.sessionKey.hasPrefix("agent:main:"))
    #expect(viewModel.sessions.count == 1)
    #expect(viewModel.sessionOrder.count == 1)
  }

  @Test
  func testCreateSession_generatesUniqueIds() async throws {
    let mockStorage = createMockStorage()
    let viewModel = DeckViewModel(storage: mockStorage)

    let config1 = viewModel.createSession(name: "Test Unique 1")
    let config2 = viewModel.createSession(name: "Test Unique 2")

    // 由于 generateId 添加了随机 hash，ID 应该不同
    #expect(config1.id != config2.id)
  }

  @Test
  func testDeleteSession() async throws {
    let mockStorage = createMockStorage()
    let viewModel = DeckViewModel(storage: mockStorage)

    let config = viewModel.createSession(name: "Test Delete Session")
    #expect(viewModel.sessions.count == 1)

    viewModel.deleteSession(sessionId: config.id)

    #expect(viewModel.sessions.isEmpty == true)
    #expect(viewModel.sessionOrder.isEmpty == true)
  }

  @Test
  func testDeleteSession_createsWelcomeSession() async throws {
    let mockStorage = createMockStorage()
    let viewModel = DeckViewModel(storage: mockStorage)

    let config = viewModel.createSession(name: "Test Welcome Session")
    viewModel.deleteSession(sessionId: config.id)

    // 删除后应该自动创建 welcome session
    #expect(viewModel.sessions.count == 1)
  }

  @Test
  func testGetSession() async throws {
    let mockStorage = createMockStorage()
    let viewModel = DeckViewModel(storage: mockStorage)

    let config = viewModel.createSession(name: "Test Get Session")
    let session = viewModel.getSession(sessionId: config.id)

    #expect(session != nil)
    #expect(session?.sessionId == config.id)
  }

  @Test
  func testGetSession_notFound() async throws {
    let mockStorage = createMockStorage()
    let viewModel = DeckViewModel(storage: mockStorage)

    let session = viewModel.getSession(sessionId: "non-existent-id")
    #expect(session == nil)
  }

  @Test
  func testSessionOrder() async throws {
    let mockStorage = createMockStorage()
    let viewModel = DeckViewModel(storage: mockStorage)

    let config1 = viewModel.createSession(name: "Test Session A")
    let config2 = viewModel.createSession(name: "Test Session B")
    let config3 = viewModel.createSession(name: "Test Session C")

    #expect(viewModel.sessionOrder.count == 3)
    #expect(viewModel.sessionOrder[0] == config1.id.lowercased())
    #expect(viewModel.sessionOrder[1] == config2.id.lowercased())
    #expect(viewModel.sessionOrder[2] == config3.id.lowercased())
  }
}
