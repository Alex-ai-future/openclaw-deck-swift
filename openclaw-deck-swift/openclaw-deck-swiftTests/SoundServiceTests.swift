// SoundServiceTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/27/26.
// Copyright © 2026 OpenClaw. All rights reserved.

import XCTest

@testable import openclaw_deck_swift

@MainActor
final class SoundServiceTests: XCTestCase {

  var soundService: SoundService!

  override func setUp() async throws {
    try await super.setUp()
    soundService = SoundService.shared
  }

  override func tearDown() async throws {
    soundService = nil
    try await super.tearDown()
  }

  // MARK: - Initialization Tests

  func testSingletonInstance() {
    let instance1 = SoundService.shared
    let instance2 = SoundService.shared
    XCTAssertTrue(instance1 === instance2, "SoundService 应该是单例")
  }

  // MARK: - Play Message Notification Tests

  func testPlayMessageNotification_doesNotCrash() {
    // 验证播放提示音不会崩溃
    XCTAssertNoThrow(soundService.playMessageNotification())
  }

  func testPlayMessageNotification_multipleCalls() {
    // 验证多次调用不会崩溃
    XCTAssertNoThrow(soundService.playMessageNotification())
    XCTAssertNoThrow(soundService.playMessageNotification())
    XCTAssertNoThrow(soundService.playMessageNotification())
  }

  // MARK: - Play Error Sound Tests

  func testPlayErrorSound_doesNotCrash() {
    // 验证播放错误提示音不会崩溃
    XCTAssertNoThrow(soundService.playErrorSound())
  }

  func testPlayErrorSound_multipleCalls() {
    // 验证多次调用不会崩溃
    XCTAssertNoThrow(soundService.playErrorSound())
    XCTAssertNoThrow(soundService.playErrorSound())
  }

  // MARK: - Sound Service Integration Tests

  func testBothSoundMethods_available() {
    // 验证两个方法都可以调用
    XCTAssertNoThrow(soundService.playMessageNotification())
    XCTAssertNoThrow(soundService.playErrorSound())
  }

  func testSoundService_crossPlatform() {
    // 验证 SoundService 在不同平台都能工作
    // macOS 使用 NSSound，iOS 使用 AudioToolbox
    // 这个测试确保代码在两个平台都能编译和运行
    let service = SoundService.shared
    XCTAssertNotNil(service)
    XCTAssertNoThrow(service.playMessageNotification())
    XCTAssertNoThrow(service.playErrorSound())
  }
}
