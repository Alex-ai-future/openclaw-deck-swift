// GatewayFrameTests.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/26.
// Copyright © 2026 OpenClaw. All rights reserved.

import XCTest

@testable import openclaw_deck_swift

final class GatewayFrameTests: XCTestCase {

  // MARK: - GatewayRequest Tests

  func testGatewayRequestInitialization() {
    let request = GatewayRequest(
      id: "req-1",
      method: "connect",
      params: ["url": "ws://localhost"]
    )

    XCTAssertEqual(request.id, "req-1")
    XCTAssertEqual(request.method, "connect")
  }

  func testGatewayRequestGenerateId() {
    let request = GatewayRequest(
      id: "req-1",
      method: "test"
    )

    XCTAssertEqual(request.id, "req-1")
    XCTAssertEqual(request.method, "test")
    XCTAssertNil(request.params)
  }

  func testGatewayRequestToJSON() throws {
    let request = GatewayRequest(
      id: "req-1",
      method: "agent",
      params: ["agentId": "main", "message": "Hello"]
    )

    let data = try request.toJSON()
    XCTAssertGreaterThan(data.count, 0)

    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertEqual(json?["id"] as? String, "req-1")
    XCTAssertEqual(json?["method"] as? String, "agent")
  }

  // MARK: - GatewayResponse Tests

  func testGatewayResponseInitialization() {
    let response = GatewayResponse(
      id: "res-1",
      ok: true,
      payload: ["status": "success"],
      error: nil
    )

    XCTAssertEqual(response.id, "res-1")
    XCTAssertTrue(response.ok)
    XCTAssertNil(response.error)
  }

  func testGatewayResponseFromJSON() throws {
    let json: [String: Any] = [
      "type": "res",
      "id": "res-1",
      "ok": true,
      "payload": ["result": "ok"],
    ]

    let response = try GatewayResponse.fromJSON(json)

    XCTAssertEqual(response.id, "res-1")
    XCTAssertTrue(response.ok)
  }

  // MARK: - GatewayEvent Tests

  func testGatewayEventInitialization() {
    let event = GatewayEvent(
      event: "agent.content",
      payload: ["text": "Hello"]
    )

    XCTAssertEqual(event.event, "agent.content")
  }

  func testGatewayEventIsType() {
    let event = GatewayEvent(
      event: "agent.done",
      payload: nil
    )

    XCTAssertTrue(event.isType("agent.done"))
    XCTAssertFalse(event.isType("agent.content"))
  }

  func testGatewayEventFromJSON() throws {
    let json: [String: Any] = [
      "type": "event",
      "event": "tick",
      "payload": ["timestamp": 123456],
    ]

    let event = try GatewayEvent.fromJSON(json)

    XCTAssertEqual(event.event, "tick")
  }

  // MARK: - GatewayError Tests

  func testGatewayErrorInitialization() {
    let error = GatewayError(
      code: -1,
      message: "Test error"
    )

    XCTAssertEqual(error.code, -1)
    XCTAssertEqual(error.message, "Test error")
  }

  func testGatewayErrorFromJSON() throws {
    let json: [String: Any] = [
      "code": 404,
      "message": "Not found",
    ]

    let error = try GatewayError.fromJSON(json)

    XCTAssertEqual(error.code, 404)
    XCTAssertEqual(error.message, "Not found")
  }

  // MARK: - Integration Tests

  func testFullRequestResponseCycle() throws {
    // Create request
    let request = GatewayRequest(
      id: "req-1",
      method: "agent",
      params: ["agentId": "main"]
    )

    // Encode request
    let requestData = try request.toJSON()
    let requestJSON = try JSONSerialization.jsonObject(with: requestData) as? [String: Any]
    XCTAssertEqual(requestJSON?["id"] as? String, "req-1")

    // Create response JSON
    let responseJSON: [String: Any] = [
      "type": "res",
      "id": "req-1",
      "ok": true,
      "payload": ["runId": "run-123"],
    ]

    // Decode response
    let response = try GatewayResponse.fromJSON(responseJSON)

    XCTAssertTrue(response.ok)
  }

  func testEventStream() throws {
    let events = [
      ["type": "event", "event": "agent", "payload": ["stream": "assistant"]],
      ["type": "event", "event": "agent.content", "payload": ["text": "Hello"]],
      ["type": "event", "event": "agent.done", "payload": nil],
    ]

    for eventJSON in events {
      let event = try GatewayEvent.fromJSON(eventJSON)
      XCTAssertNotNil(event.event)
    }
  }
}
