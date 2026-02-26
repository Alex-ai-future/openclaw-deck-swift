// DeckViewModelTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/26.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation
import Testing

/// DeckViewModel 测试
/// 注意：由于 DeckViewModel 依赖 UserDefaults 且使用 @MainActor，
/// 复杂的集成测试容易受到状态污染影响。
/// 建议对核心逻辑使用单元测试，对 ViewModel 使用 UI 测试或集成测试。
@Suite
struct DeckViewModelTests {

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
