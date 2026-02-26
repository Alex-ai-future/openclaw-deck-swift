// AppConfigTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/26.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation
import Testing

struct AppConfigTests {

  @Test
  func testDefaultConfig() {
    let config = AppConfig.default

    #expect(config.gatewayUrl == "ws://127.0.0.1:18789")
    #expect(config.token == nil)
    #expect(config.mainAgentId == "main")
    #expect(config.minSupportedVersion == "18.0")
  }

  @Test
  func testCustomConfig() {
    let config = AppConfig(
      gatewayUrl: "ws://localhost:8080",
      token: "test-token",
      mainAgentId: "custom-agent",
      minSupportedVersion: "18.0"
    )

    #expect(config.gatewayUrl == "ws://localhost:8080")
    #expect(config.token == "test-token")
    #expect(config.mainAgentId == "custom-agent")
  }

  @Test
  func testIsValidGatewayUrl_valid() {
    var config = AppConfig.default
    config.gatewayUrl = "ws://localhost:8080"
    #expect(config.isValidGatewayUrl == true)

    config.gatewayUrl = "wss://example.com/ws"
    #expect(config.isValidGatewayUrl == true)
  }

  @Test
  func testIsValidGatewayUrl_invalid() {
    var config = AppConfig.default

    config.gatewayUrl = ""
    #expect(config.isValidGatewayUrl == false)

    config.gatewayUrl = "http://localhost:8080"
    #expect(config.isValidGatewayUrl == false)

    config.gatewayUrl = "invalid-url"
    #expect(config.isValidGatewayUrl == false)
  }

  @Test
  func testIsValidToken_valid() {
    var config = AppConfig.default
    config.token = "valid-token"
    #expect(config.isValidToken == true)

    config.token = "  token-with-spaces  "
    #expect(config.isValidToken == true)
  }

  @Test
  func testIsValidToken_invalid() {
    var config = AppConfig.default

    config.token = nil
    #expect(config.isValidToken == false)

    config.token = ""
    #expect(config.isValidToken == false)

    config.token = "   "
    #expect(config.isValidToken == false)
  }

  @Test
  func testIsComplete() {
    var config = AppConfig.default

    // Missing token
    #expect(config.isComplete == false)

    // Complete config
    config.token = "valid-token"
    #expect(config.isComplete == true)

    // Invalid URL
    config.gatewayUrl = ""
    #expect(config.isComplete == false)
  }

  @Test
  func testIsDefault() {
    let config = AppConfig.default
    #expect(config.isDefault == true)

    let modifiedConfig = AppConfig(
      gatewayUrl: "ws://localhost:8080",
      token: nil,
      mainAgentId: "main"
    )
    #expect(modifiedConfig.isDefault == false)
  }
}
