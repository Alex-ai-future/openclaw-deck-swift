// SessionConfigTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/26.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation
import Testing

@testable import openclaw_deck_swift

struct SessionConfigTests {

  @Test
  func testGenerateId_withNormalName() {
    let sessionId = SessionConfig.generateId(from: "Research Agent")
    // ID 应该包含 "research-agent" 前缀
    #expect(sessionId.hasPrefix("research-agent-"))
  }

  @Test
  func testGenerateId_withSpecialCharacters() {
    let sessionId = SessionConfig.generateId(from: "Test @#$% Agent")
    // 特殊字符应该被替换为连字符
    #expect(sessionId.hasPrefix("test-agent-"))
  }

  @Test
  func testGenerateId_withEmptyName() {
    let sessionId = SessionConfig.generateId(from: "")
    // 空名称应该生成带时间戳的 ID
    #expect(sessionId.hasPrefix("session-"))
  }

  @Test
  func testGenerateId_isUnique() {
    // 多次生成应该得到不同的 ID（因为有随机 hash）
    let id1 = SessionConfig.generateId(from: "Test")
    let id2 = SessionConfig.generateId(from: "Test")
    #expect(id1 != id2)
  }

  @Test
  func testGenerateSessionKey() {
    let sessionKey = SessionConfig.generateSessionKey(sessionId: "test-agent")
    #expect(sessionKey == "agent:main:test-agent")
  }

  @Test
  func testSessionConfigInitialization() {
    let config = SessionConfig(
      id: "test-id",
      sessionKey: "agent:main:test-id",
      createdAt: Date(),
      name: "Test Session",
      icon: "T",
      context: "Test context"
    )

    #expect(config.id == "test-id")
    #expect(config.sessionKey == "agent:main:test-id")
    #expect(config.name == "Test Session")
    #expect(config.icon == "T")
    #expect(config.context == "Test context")
  }

  @Test
  func testSessionConfigIsEmpty() {
    let emptyConfig = SessionConfig(
      id: "",
      sessionKey: "",
      createdAt: Date(),
      name: nil,
      icon: nil,
      context: nil
    )

    #expect(emptyConfig.isEmpty == true)

    let nonEmptyConfig = SessionConfig(
      id: "test",
      sessionKey: "agent:main:test",
      createdAt: Date(),
      name: "Test",
      icon: nil,
      context: nil
    )

    #expect(nonEmptyConfig.isEmpty == false)
  }
}
