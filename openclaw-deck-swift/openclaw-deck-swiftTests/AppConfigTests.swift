// AppConfigTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/26.
// Copyright © 2026 OpenClaw. All rights reserved.

import XCTest
@testable import openclaw_deck_swift

final class AppConfigTests: XCTestCase {

  func testDefaultConfig() {
    let config = AppConfig.default

    XCTAssertEqual(config.gatewayUrl, "ws://127.0.0.1:18789")
    XCTAssertNil(config.token)
    XCTAssertEqual(config.mainAgentId, "main")
    XCTAssertEqual(config.minSupportedVersion, "18.0")
  }

  func testCustomConfig() {
    let config = AppConfig(
      gatewayUrl: "ws://localhost:8080",
      token: "test-token",
      mainAgentId: "custom-agent",
      minSupportedVersion: "18.0"
    )

    XCTAssertEqual(config.gatewayUrl, "ws://localhost:8080")
    XCTAssertEqual(config.token, "test-token")
    XCTAssertEqual(config.mainAgentId, "custom-agent")
  }

  func testIsValidGatewayUrl_valid() {
    var config = AppConfig.default
    config.gatewayUrl = "ws://localhost:8080"
    XCTAssertTrue(config.isValidGatewayUrl)

    config.gatewayUrl = "wss://example.com/ws"
    XCTAssertTrue(config.isValidGatewayUrl)
  }

  func testIsValidGatewayUrl_invalid() {
    var config = AppConfig.default

    config.gatewayUrl = ""
    XCTAssertFalse(config.isValidGatewayUrl)

    config.gatewayUrl = "http://localhost:8080"
    XCTAssertFalse(config.isValidGatewayUrl)

    config.gatewayUrl = "invalid-url"
    XCTAssertFalse(config.isValidGatewayUrl)
  }

  func testIsValidToken_valid() {
    var config = AppConfig.default
    config.token = "valid-token"
    XCTAssertTrue(config.isValidToken)

    config.token = "  token-with-spaces  "
    XCTAssertTrue(config.isValidToken)
  }

  func testIsValidToken_invalid() {
    var config = AppConfig.default

    config.token = nil
    XCTAssertFalse(config.isValidToken)

    config.token = ""
    XCTAssertFalse(config.isValidToken)

    config.token = "   "
    XCTAssertFalse(config.isValidToken)
  }

  func testIsComplete() {
    var config = AppConfig.default

    // Missing token
    XCTAssertFalse(config.isComplete)

    // Complete config
    config.token = "valid-token"
    XCTAssertTrue(config.isComplete)

    // Invalid URL
    config.gatewayUrl = ""
    XCTAssertFalse(config.isComplete)
  }

  func testIsDefault() {
    let config = AppConfig.default
    XCTAssertTrue(config.isDefault)

    let modifiedConfig = AppConfig(
      gatewayUrl: "ws://localhost:8080",
      token: nil,
      mainAgentId: "main"
    )
    XCTAssertFalse(modifiedConfig.isDefault)
  }
}
