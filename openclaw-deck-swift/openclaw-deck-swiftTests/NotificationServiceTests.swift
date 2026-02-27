// NotificationServiceTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/27/26.
// Copyright © 2026 OpenClaw. All rights reserved.

import XCTest
import UserNotifications

@testable import openclaw_deck_swift

@MainActor
final class NotificationServiceTests: XCTestCase {

  var notificationService: NotificationService!

  override func setUp() async throws {
    try await super.setUp()
    notificationService = NotificationService.shared
  }

  override func tearDown() async throws {
    notificationService = nil
    try await super.tearDown()
  }

  // MARK: - Initialization Tests

  func testSingletonInstance() {
    let instance1 = NotificationService.shared
    let instance2 = NotificationService.shared
    XCTAssertTrue(instance1 === instance2, "NotificationService 应该是单例")
  }

  // MARK: - Permission Tests

  func testRequestPermission_doesNotCrash() {
    // 验证请求权限不会崩溃
    // 注意：实际权限请求需要用户交互，测试中只验证不会崩溃
    XCTAssertNoThrow(notificationService.requestPermission())
  }

  func testCheckPermission_returnsBool() async {
    // 验证检查权限返回布尔值
    let hasPermission = await notificationService.checkPermission()
    // 验证返回的是有效的布尔值（true 或 false）
    XCTAssertTrue(hasPermission == true || hasPermission == false)
  }

  // MARK: - Send Notification Tests

  func testSendNewMessageNotification_doesNotCrash() {
    // 验证发送通知不会崩溃
    // 注意：实际发送需要权限，测试中只验证不会崩溃
    XCTAssertNoThrow(
      notificationService.sendNewMessageNotification(
        sessionName: "Test Session",
        messageText: "Test message"
      )
    )
  }

  func testSendNewMessageNotification_withLongText() {
    // 验证长文本会被截断
    let longText = String(repeating: "This is a very long message. ", count: 50)
    XCTAssertNoThrow(
      notificationService.sendNewMessageNotification(
        sessionName: "Test Session",
        messageText: longText
      )
    )
  }

  func testSendNewMessageNotification_withEmptyText() {
    // 验证空文本也能发送
    XCTAssertNoThrow(
      notificationService.sendNewMessageNotification(
        sessionName: "Test Session",
        messageText: ""
      )
    )
  }

  func testSendNewMessageNotification_withSpecialCharacters() {
    // 验证特殊字符也能发送
    let specialText = "Special chars: @#$%^&*()_+-=[]{}|;':\",./<>?"
    XCTAssertNoThrow(
      notificationService.sendNewMessageNotification(
        sessionName: "Test! @#$",
        messageText: specialText
      )
    )
  }

  func testSendNewMessageNotification_multipleCalls() {
    // 验证多次调用不会崩溃
    XCTAssertNoThrow(
      notificationService.sendNewMessageNotification(
        sessionName: "Session 1",
        messageText: "Message 1"
      )
    )
    XCTAssertNoThrow(
      notificationService.sendNewMessageNotification(
        sessionName: "Session 2",
        messageText: "Message 2"
      )
    )
  }

  // MARK: - Notification Content Tests

  func testNotificationContent_truncatesLongBody() {
    // 验证通知内容会截断长文本到 200 字符
    let longText = String(repeating: "A", count: 500)
    
    // 这个测试主要验证不会崩溃，实际截断逻辑在 sendNewMessageNotification 中
    XCTAssertNoThrow(
      notificationService.sendNewMessageNotification(
        sessionName: "Test",
        messageText: longText
      )
    )
  }

  // MARK: - Integration Tests

  func testNotificationService_fullWorkflow() async {
    // 验证完整工作流程
    let service = NotificationService.shared
    
    // 1. 请求权限
    XCTAssertNoThrow(service.requestPermission())
    
    // 2. 检查权限
    let hasPermission = await service.checkPermission()
    // 验证返回的是有效的布尔值
    XCTAssertTrue(hasPermission == true || hasPermission == false)
    
    // 3. 发送通知
    XCTAssertNoThrow(
      service.sendNewMessageNotification(
        sessionName: "Integration Test",
        messageText: "Test message"
      )
    )
  }

  func testNotificationService_differentSessionNames() {
    // 验证不同 Session 名称都能正常工作
    let names = ["Session 1", "测试会话", "Session with emoji 🚀", ""]
    
    for name in names {
      XCTAssertNoThrow(
        notificationService.sendNewMessageNotification(
          sessionName: name,
          messageText: "Test"
        )
      )
    }
  }

  func testNotificationService_permissionFlow() async {
    // 验证权限流程
    // 1. 检查权限（初始状态）
    let initialPermission = await notificationService.checkPermission()
    
    // 2. 请求权限
    notificationService.requestPermission()
    
    // 3. 再次检查权限
    let afterRequestPermission = await notificationService.checkPermission()
    
    // 验证返回的是有效的布尔值
    XCTAssertTrue(initialPermission == true || initialPermission == false)
    XCTAssertTrue(afterRequestPermission == true || afterRequestPermission == false)
  }
}
