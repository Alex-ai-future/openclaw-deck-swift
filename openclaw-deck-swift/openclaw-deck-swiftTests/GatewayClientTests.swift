//
//  GatewayClientTests.swift
//  openclaw-deck-swiftTests
//
//  Created by Jihui Huang on 2/23/26.
//

import Foundation
import Testing

@testable import openclaw_deck_swift

@MainActor
struct GatewayClientTests {

  // MARK: - Initialization Tests

  @Test func testInitialization() {
    // Test 1: Initialize with URL only
    let url = URL(string: "ws://localhost:8080")!
    let client1 = GatewayClient(url: url, isMock: true)

    #expect(client1.url == url)
    #expect(client1.token == nil)
    #expect(!client1.connected)

    // Test 2: Initialize with URL and token
    let client2 = GatewayClient(url: url, token: "test-token-123", isMock: true)

    #expect(client2.url == url)
    #expect(client2.token == "test-token-123")
    #expect(!client2.connected)
  }

  @Test func testInitializationWithDifferentURLs() {
    let urls = [
      "ws://localhost:8080",
      "ws://127.0.0.1:18789",
      "wss://api.example.com",
      "ws://192.168.1.100:3000",
    ]

    for urlString in urls {
      let url = URL(string: urlString)!
      let client = GatewayClient(url: url, token: "test", isMock: true)

      #expect(client.url == url)
      #expect(client.token == "test")
      #expect(!client.connected)
    }
  }

  // MARK: - Connection Tests

  @Test func testConnect() async {
    let url = URL(string: "ws://localhost:8080")!
    let client = GatewayClient(url: url, isMock: true)

    // Track connection state changes
    var connectionStates: [Bool] = []
    client.onConnection = { connected in
      connectionStates.append(connected)
    }

    // Connect
    await client.connect()

    #expect(client.connected)
    #expect(connectionStates.contains(true))
  }

  @Test func testDisconnect() async {
    let url = URL(string: "ws://localhost:8080")!
    let client = GatewayClient(url: url, isMock: true)

    // Track connection state changes
    var connectionStates: [Bool] = []
    client.onConnection = { connected in
      connectionStates.append(connected)
    }

    // Connect first
    await client.connect()
    #expect(client.connected)

    // Then disconnect
    client.disconnect()

    #expect(!client.connected)
    #expect(connectionStates.contains(true))
    #expect(connectionStates.contains(false))
  }

  @Test func testDisconnectWithoutConnect() {
    let url = URL(string: "ws://localhost:8080")!
    let client = GatewayClient(url: url, isMock: true)

    var connectionCalled = false
    client.onConnection = { connected in
      connectionCalled = true
    }

    // Disconnect without connecting
    client.disconnect()

    #expect(!client.connected)
    #expect(!connectionCalled)  // Should not trigger callback if never connected
  }

  // MARK: - Request Tests

  // Note: This test is skipped in mock mode because mock mode allows connect requests
  @Test(.disabled("Skipped in mock mode")) func testRequestWhenNotConnected() async {
    let url = URL(string: "ws://localhost:8080")!
    let client = GatewayClient(url: url, isMock: true)

    // Try to make a request without connecting
    do {
      _ = try await client.request(method: "connect")
      Issue.record("Should have thrown an error when not connected")
    } catch let error as NSError {
      #expect(error.domain == "GatewayClient")
      #expect(error.code == -1)
      #expect(error.localizedDescription.contains("Gateway not connected"))
    }
  }

  @Test func testRequestWhenConnected() async {
    let url = URL(string: "ws://localhost:8080")!
    let client = GatewayClient(url: url, isMock: true)

    // Connect first
    await client.connect()

    // Make a request
    let response = try! await client.request(method: "connect")

    #expect(response.ok == true)
    #expect(response.payload != nil)
    #expect(response.error == nil)
  }

  @Test func testRequestWithParams() async {
    let url = URL(string: "ws://localhost:8080")!
    let client = GatewayClient(url: url, isMock: true)

    await client.connect()

    let params: [String: Any] = [
      "agentId": "main",
      "message": "Hello, world!",
    ]

    let response = try! await client.request(method: "agent", params: params)

    #expect(response.ok == true)
    #expect(response.id.starts(with: "deck-"))
  }

  // MARK: - RunAgent Tests

  // Note: This test is skipped in mock mode because mock mode bypasses connection checks
  @Test(.disabled("Skipped in mock mode")) func testRunAgentWhenNotConnected() async {
    let url = URL(string: "ws://localhost:8080")!
    let client = GatewayClient(url: url, isMock: true)

    do {
      _ = try await client.runAgent(agentId: "main", message: "Hello")
      Issue.record("Should have thrown an error when not connected")
    } catch let error as NSError {
      #expect(error.domain == "GatewayClient")
      #expect(error.code == -1)
    }
  }

  @Test func testRunAgentWithoutSessionKey() async {
    let url = URL(string: "ws://localhost:8080")!
    let client = GatewayClient(url: url, isMock: true)

    await client.connect()

    let result = try! await client.runAgent(
      agentId: "main",
      message: "Hello, how are you?"
    )

    #expect(!result.runId.isEmpty)
    #expect(!result.status.isEmpty)
  }

  @Test func testRunAgentWithSessionKey() async {
    let url = URL(string: "ws://localhost:8080")!
    let client = GatewayClient(url: url, isMock: true)

    await client.connect()

    let sessionKey = "agent:main:test-session"
    let result = try! await client.runAgent(
      agentId: "main",
      message: "Continue our conversation",
      sessionKey: sessionKey
    )

    #expect(!result.runId.isEmpty)
    #expect(!result.status.isEmpty)
  }

  @Test func testRunAgentGeneratesIdempotencyKey() async {
    let url = URL(string: "ws://localhost:8080")!
    let client = GatewayClient(url: url, isMock: true)

    await client.connect()

    // Make two requests
    let result1 = try! await client.runAgent(agentId: "main", message: "Message 1")
    try! await Task.sleep(nanoseconds: 1_000_000)  // 1ms delay
    let result2 = try! await client.runAgent(agentId: "main", message: "Message 2")

    // Each request should have a unique runId (based on idempotency key)
    #expect(result1.runId != result2.runId)
  }

  // MARK: - Callback Tests

  @Test func testOnEventCallback() {
    let url = URL(string: "ws://localhost:8080")!
    let client = GatewayClient(url: url, isMock: true)

    var eventsReceived: [GatewayEvent] = []
    client.onEvent = { event in
      eventsReceived.append(event)
    }

    // Simulate receiving an event (this would normally happen through WebSocket)
    let testEvent = GatewayEvent(
      event: "agent.content",
      payload: "Test content",
      seq: 1,
      stateVersion: 1
    )

    // Manually trigger the callback for testing
    client.onEvent?(testEvent)

    #expect(eventsReceived.count == 1)
    #expect(eventsReceived[0].event == "agent.content")
    #expect(eventsReceived[0].payload as? String == "Test content")
  }

  @Test func testOnConnectionCallback() async {
    let url = URL(string: "ws://localhost:8080")!
    let client = GatewayClient(url: url, isMock: true)

    var connectionState: Bool?
    client.onConnection = { connected in
      connectionState = connected
    }

    await client.connect()
    #expect(connectionState == true)

    client.disconnect()
    #expect(connectionState == false)
  }

  // MARK: - State Tests

  @Test func testConnectedState() async {
    let url = URL(string: "ws://localhost:8080")!
    let client = GatewayClient(url: url, isMock: true)

    // Initial state
    #expect(!client.connected)

    // After connect
    await client.connect()
    #expect(client.connected)

    // After disconnect
    client.disconnect()
    #expect(!client.connected)
  }

  @Test func testMultipleConnectDisconnectCycles() async {
    let url = URL(string: "ws://localhost:8080")!
    let client = GatewayClient(url: url, isMock: true)

    var connectionChanges: [Bool] = []
    client.onConnection = { connected in
      connectionChanges.append(connected)
    }

    // First cycle
    await client.connect()
    #expect(client.connected)
    client.disconnect()
    #expect(!client.connected)

    // Second cycle
    await client.connect()
    #expect(client.connected)
    client.disconnect()
    #expect(!client.connected)

    // Third cycle
    await client.connect()
    #expect(client.connected)

    #expect(connectionChanges.filter { $0 == true }.count == 3)
    #expect(connectionChanges.filter { $0 == false }.count == 2)
  }

  // MARK: - Error Handling Tests

  // Note: These tests are skipped in mock mode because mock mode bypasses connection checks
  @Test(.disabled("Skipped in mock mode")) func testRequestErrorHandling() async {
    let url = URL(string: "ws://localhost:8080")!
    let client = GatewayClient(url: url, isMock: true)

    // Request without connection should fail
    do {
      _ = try await client.request(method: "invalid")
      Issue.record("Should throw error")
    } catch {
      #expect(error is NSError)
    }
  }

  @Test(.disabled("Skipped in mock mode")) func testRunAgentErrorHandling() async {
    let url = URL(string: "ws://localhost:8080")!
    let client = GatewayClient(url: url, isMock: true)

    // RunAgent without connection should fail
    do {
      _ = try await client.runAgent(agentId: "main", message: "test")
      Issue.record("Should throw error")
    } catch {
      #expect(error is NSError)
    }
  }

  // MARK: - Integration Tests

  @Test func testFullWorkflow() async {
    let url = URL(string: "ws://localhost:8080")!
    let client = GatewayClient(url: url, isMock: true)

    var events: [String] = []
    client.onEvent = { event in
      events.append(event.event)
    }

    client.onConnection = { connected in
      events.append(connected ? "connected" : "disconnected")
    }

    // 1. Connect
    await client.connect()
    #expect(client.connected)

    // 2. Make a request
    let response = try! await client.request(method: "connect")
    #expect(response.ok == true)

    // 3. Run agent
    let result = try! await client.runAgent(
      agentId: "main",
      message: "Hello",
      sessionKey: "agent:main:test"
    )
    #expect(!result.runId.isEmpty)

    // 4. Disconnect
    client.disconnect()
    #expect(!client.connected)

    #expect(events.contains("connected"))
    #expect(events.contains("disconnected"))
  }

}
