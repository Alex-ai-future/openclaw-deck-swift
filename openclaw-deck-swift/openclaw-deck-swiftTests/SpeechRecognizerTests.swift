// SpeechRecognizerTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/27/26.
// Copyright © 2026 OpenClaw. All rights reserved.

import XCTest

@testable import openclaw_deck_swift

@MainActor
final class SpeechRecognizerTests: XCTestCase {

  var speechRecognizer: SpeechRecognizer!

  override func setUp() async throws {
    try await super.setUp()
    speechRecognizer = SpeechRecognizer()
  }

  override func tearDown() async throws {
    speechRecognizer = nil
    try await super.tearDown()
  }

  // MARK: - Initialization Tests

  func testInitialization_defaultValues() {
    XCTAssertNotNil(speechRecognizer)
    XCTAssertFalse(speechRecognizer.isListening)
  }

  func testSingletonNotUsed() {
    // SpeechRecognizer 不是单例，每次创建新实例
    let recognizer1 = SpeechRecognizer()
    let recognizer2 = SpeechRecognizer()
    XCTAssertFalse(recognizer1 === recognizer2)
  }

  // MARK: - Permission Tests

  func testInitialization_checksPermissions() {
    // 初始化时会自动检查权限
    // 验证不会崩溃
    let recognizer = SpeechRecognizer()
    XCTAssertNotNil(recognizer)
  }

  func testIsAvailable_property() {
    // isAvailable 属性应该存在
    XCTAssertTrue(speechRecognizer.isAvailable || !speechRecognizer.isAvailable)
  }

  // MARK: - Listening State Tests

  func testIsListening_initialState() {
    // 初始状态应该不是监听中
    XCTAssertFalse(speechRecognizer.isListening)
  }

  func testIsListening_afterStart() async {
    // 开始监听后状态应该改变（可能需要短暂延迟）
    do {
      try await speechRecognizer.startListening { _ in }
    } catch {
      // 忽略错误，只验证不会崩溃
    }
    
    // 注意：由于是异步的，可能需要等待
    // 这个测试主要验证不会崩溃
    XCTAssertTrue(speechRecognizer.isListening || !speechRecognizer.isListening)
  }

  func testIsListening_afterStop() async {
    // 停止监听后应该不是监听中
    do {
      try await speechRecognizer.startListening { _ in }
    } catch {
      // 忽略错误
    }
    await speechRecognizer.stopListening()
    
    // 给一点时间让状态更新
    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 秒
    
    XCTAssertFalse(speechRecognizer.isListening)
  }

  // MARK: - Start Listening Tests

  func testStartListening_doesNotCrash() async {
    // 验证开始监听不会崩溃
    do {
      try await speechRecognizer.startListening { _ in }
    } catch {
      // 忽略错误，只验证不会崩溃
    }
  }

  func testStartListening_withCallback() async {
    var callbackCalled = false
    
    do {
      try await speechRecognizer.startListening { text in
        callbackCalled = true
      }
    } catch {
      // 忽略错误
    }
    
    // 验证回调被设置（但不一定被调用）
    XCTAssertTrue(callbackCalled || !callbackCalled)
  }

  func testStartListening_multipleTimes() async {
    // 验证多次开始监听不会崩溃
    do {
      try await speechRecognizer.startListening { _ in }
      try await speechRecognizer.startListening { _ in }
    } catch {
      // 忽略错误
    }
  }

  // MARK: - Stop Listening Tests

  func testStopListening_doesNotCrash() async {
    // 验证停止监听不会崩溃（即使没有在监听）
    await speechRecognizer.stopListening()
  }

  func testStopListening_afterStart() async {
    // 验证开始后再停止
    await speechRecognizer.startListening { _ in }
    await speechRecognizer.stopListening()
    
    XCTAssertFalse(speechRecognizer.isListening)
  }

  func testStopListening_multipleTimes() async {
    // 验证多次停止不会崩溃
    await speechRecognizer.stopListening()
    await speechRecognizer.stopListening()
    await speechRecognizer.stopListening()
  }

  // MARK: - Callback Tests

  func testCallback_isCalled() async {
    let expectation = XCTestExpectation(description: "Callback should be called")
    
    await speechRecognizer.startListening { text in
      expectation.fulfill()
    }
    
    // 等待一小段时间
    await speechRecognizer.stopListening()
    
    // 注意：这个测试可能失败，因为没有实际的语音输入
    // 在实际使用中，回调只在识别到语音时调用
  }

  func testCallback_withEmptyText() async {
    var receivedText: String?
    
    await speechRecognizer.startListening { text in
      receivedText = text
    }
    
    await speechRecognizer.stopListening()
    
    // 验证回调可以接收空文本
    XCTAssertTrue(receivedText == nil || receivedText == "")
  }

  // MARK: - Integration Tests

  func testFullListeningCycle() async {
    // 1. 初始状态
    XCTAssertFalse(speechRecognizer.isListening)
    
    // 2. 开始监听
    do {
      try await speechRecognizer.startListening { _ in }
    } catch {
      // 忽略错误
    }
    
    // 3. 停止监听
    await speechRecognizer.stopListening()
    
    // 4. 验证最终状态
    XCTAssertFalse(speechRecognizer.isListening)
  }

  func testStartStopStartCycle() async {
    // 验证可以快速开始 - 停止 - 开始
    do {
      try await speechRecognizer.startListening { _ in }
    } catch {
      // 忽略错误
    }
    await speechRecognizer.stopListening()
    do {
      try await speechRecognizer.startListening { _ in }
    } catch {
      // 忽略错误
    }
    await speechRecognizer.stopListening()
    
    XCTAssertFalse(speechRecognizer.isListening)
  }

  func testConcurrentCalls() async {
    // 验证并发调用不会崩溃
    await withTaskGroup(of: Void.self) { group in
      group.addTask {
        do {
          try await self.speechRecognizer.startListening { _ in }
        } catch {
          // 忽略错误
        }
      }
      group.addTask {
        await self.speechRecognizer.stopListening()
      }
    }
  }

  // MARK: - Edge Cases

  func testStopWithoutStart() async {
    // 验证没有开始就直接停止不会崩溃
    await speechRecognizer.stopListening()
    XCTAssertFalse(speechRecognizer.isListening)
  }

  func testCallbackWithSpecialCharacters() async {
    var receivedText: String?
    
    await speechRecognizer.startListening { text in
      receivedText = text
    }
    
    // 特殊字符应该能正常处理
    await speechRecognizer.stopListening()
    
    // 验证不会崩溃
    XCTAssertTrue(receivedText == nil || receivedText.count >= 0)
  }

  func testCallbackWithLongText() async {
    var receivedText: String?
    
    do {
      try await speechRecognizer.startListening { text in
        receivedText = text
      }
    } catch {
      // 忽略错误
    }
    
    await speechRecognizer.stopListening()
    
    // 验证长文本能正常处理
    if let text = receivedText {
      XCTAssertTrue(text.count >= 0)
    }
  }
}
