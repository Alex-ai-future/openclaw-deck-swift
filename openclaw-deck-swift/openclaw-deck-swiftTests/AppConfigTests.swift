//
//  AppConfigTests.swift
//  openclaw-deck-swiftTests
//
//  Created by Jihui Huang on 2/23/26.
//

import Foundation
import Testing

@testable import openclaw_deck_swift

@MainActor
struct AppConfigTests {

  @Test func testDefaultConfiguration() {
    let defaultConfig = AppConfig.default

    #expect(defaultConfig.gatewayUrl == "ws://127.0.0.1:18789")
    #expect(defaultConfig.token == nil)
    #expect(defaultConfig.mainAgentId == "main")
    #expect(defaultConfig.minSupportedVersion == "18.0")
    #expect(defaultConfig.isDefault)
    #expect(defaultConfig.isValidGatewayUrl)
    #expect(!defaultConfig.isValidToken)  // token is nil
    #expect(!defaultConfig.isComplete)  // token is missing
  }

  @Test func testCustomInitialization() {
    // Test 1: Full configuration
    let config1 = AppConfig(
      gatewayUrl: "wss://example.com:8080",
      token: "test-token-123",
      mainAgentId: "custom-agent",
      minSupportedVersion: "19.0"
    )

    #expect(config1.gatewayUrl == "wss://example.com:8080")
    #expect(config1.token == "test-token-123")
    #expect(config1.mainAgentId == "custom-agent")
    #expect(config1.minSupportedVersion == "19.0")
    #expect(!config1.isDefault)
    #expect(config1.isValidGatewayUrl)
    #expect(config1.isValidToken)
    #expect(config1.isComplete)

    // Test 2: Configuration with empty token
    let config2 = AppConfig(
      gatewayUrl: "ws://localhost:3000",
      token: "",
      mainAgentId: "main"
    )

    #expect(config2.gatewayUrl == "ws://localhost:3000")
    #expect(config2.token == "")
    #expect(config2.mainAgentId == "main")
    #expect(config2.minSupportedVersion == "18.0")  // default value
    #expect(!config2.isDefault)
    #expect(config2.isValidGatewayUrl)
    #expect(!config2.isValidToken)  // token is empty
    #expect(!config2.isComplete)  // token is invalid

    // Test 3: Configuration with nil token
    let config3 = AppConfig(
      gatewayUrl: "ws://192.168.1.100:8080",
      token: nil,
      mainAgentId: "test-agent"
    )

    #expect(config3.gatewayUrl == "ws://192.168.1.100:8080")
    #expect(config3.token == nil)
    #expect(config3.mainAgentId == "test-agent")
    #expect(config3.minSupportedVersion == "18.0")
    #expect(!config3.isDefault)
    #expect(config3.isValidGatewayUrl)
    #expect(!config3.isValidToken)  // token is nil
    #expect(!config3.isComplete)  // token is missing
  }

  @Test func testGatewayUrlValidation() {
    // Test valid WebSocket URLs
    let validUrls = [
      "ws://localhost:8080",
      "wss://example.com",
      "ws://192.168.1.1:3000",
      "wss://api.example.com:443/ws",
    ]

    for url in validUrls {
      let config = AppConfig(
        gatewayUrl: url,
        token: "test",
        mainAgentId: "main"
      )
      #expect(config.isValidGatewayUrl, "URL should be valid: \(url)")
    }

    // Test invalid URLs
    let invalidUrls = [
      "http://example.com",  // wrong scheme
      "ftp://example.com",  // wrong scheme
      "not-a-url",  // invalid URL
      "",  // empty string
      "ws://",  // incomplete URL
    ]

    for url in invalidUrls {
      let config = AppConfig(
        gatewayUrl: url,
        token: "test",
        mainAgentId: "main"
      )
      #expect(!config.isValidGatewayUrl, "URL should be invalid: \(url)")
    }
  }

  @Test func testTokenValidation() {
    // Test valid tokens
    let validTokens = [
      "token123",
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
      String(repeating: "a", count: 100),  // long token
      "test-token-with-dashes",
    ]

    for token in validTokens {
      let config = AppConfig(
        gatewayUrl: "ws://localhost:8080",
        token: token,
        mainAgentId: "main"
      )
      #expect(config.isValidToken, "Token should be valid: \(token)")
    }

    // Test invalid tokens
    let invalidTokens: [String?] = [
      nil,  // nil token
      "",  // empty string
      "   ",  // whitespace only
    ]

    for token in invalidTokens {
      let config = AppConfig(
        gatewayUrl: "ws://localhost:8080",
        token: token,
        mainAgentId: "main"
      )
      #expect(!config.isValidToken, "Token should be invalid: \(token ?? "nil")")
    }
  }

  @Test func testConfigurationCompleteness() {
    // Test complete configuration
    let completeConfig = AppConfig(
      gatewayUrl: "ws://localhost:8080",
      token: "valid-token",
      mainAgentId: "main"
    )
    #expect(completeConfig.isComplete)

    // Test incomplete configurations
    let incompleteConfigs = [
      AppConfig(gatewayUrl: "ws://localhost:8080", token: nil, mainAgentId: "main"),  // missing token
      AppConfig(gatewayUrl: "ws://localhost:8080", token: "", mainAgentId: "main"),  // empty token
      AppConfig(gatewayUrl: "http://localhost:8080", token: "valid-token", mainAgentId: "main"),  // invalid URL
      AppConfig(gatewayUrl: "not-a-url", token: "valid-token", mainAgentId: "main"),  // invalid URL
    ]

    for config in incompleteConfigs {
      #expect(!config.isComplete, "Config should be incomplete: \(config)")
    }
  }

  @Test func testDefaultCheck() {
    // Test default configuration
    let defaultConfig = AppConfig.default
    #expect(defaultConfig.isDefault)

    // Test non-default configurations
    let nonDefaultConfigs = [
      AppConfig(gatewayUrl: "ws://other:8080", token: nil, mainAgentId: "main"),  // different URL
      AppConfig(gatewayUrl: "ws://127.0.0.1:18789", token: "token", mainAgentId: "main"),  // has token
      AppConfig(gatewayUrl: "ws://other:8080", token: "token", mainAgentId: "main"),  // both different
    ]

    for config in nonDefaultConfigs {
      #expect(!config.isDefault, "Config should not be default: \(config)")
    }
  }

  @Test func testCodable() async throws {
    // Test encoding and decoding
    let originalConfig = AppConfig(
      gatewayUrl: "wss://api.example.com:8080",
      token: "test-jwt-token-123",
      mainAgentId: "custom-agent",
      minSupportedVersion: "19.0"
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(originalConfig)

    let decoder = JSONDecoder()
    let decodedConfig = try decoder.decode(AppConfig.self, from: data)

    #expect(decodedConfig.gatewayUrl == originalConfig.gatewayUrl)
    #expect(decodedConfig.token == originalConfig.token)
    #expect(decodedConfig.mainAgentId == originalConfig.mainAgentId)
    #expect(decodedConfig.minSupportedVersion == originalConfig.minSupportedVersion)

    // Test with nil token
    let configWithNilToken = AppConfig(
      gatewayUrl: "ws://localhost:3000",
      token: nil,
      mainAgentId: "main"
    )

    let data2 = try encoder.encode(configWithNilToken)
    let decodedConfig2 = try decoder.decode(AppConfig.self, from: data2)

    #expect(decodedConfig2.gatewayUrl == configWithNilToken.gatewayUrl)
    #expect(decodedConfig2.token == configWithNilToken.token)  // should be nil
    #expect(decodedConfig2.mainAgentId == configWithNilToken.mainAgentId)
    #expect(decodedConfig2.minSupportedVersion == configWithNilToken.minSupportedVersion)
  }

  @Test func testMutableProperties() {
    var config = AppConfig.default

    // Test modifying gatewayUrl
    config.gatewayUrl = "wss://new.example.com"
    #expect(config.gatewayUrl == "wss://new.example.com")
    #expect(!config.isDefault)

    // Test modifying token
    config.token = "new-token"
    #expect(config.token == "new-token")
    #expect(config.isValidToken)

    // Test setting token to nil
    config.token = nil
    #expect(config.token == nil)
    #expect(!config.isValidToken)

    // Test setting token to empty
    config.token = ""
    #expect(config.token == "")
    #expect(!config.isValidToken)
  }
}
