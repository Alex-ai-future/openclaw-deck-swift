// GatewayFrameExtendedTests.swift
// OpenClaw Deck Swift
//
// Gateway Frame 扩展测试

import XCTest

@testable import openclaw_deck_swift

final class GatewayFrameExtendedTests: XCTestCase {

  // MARK: - GatewayEvent Tests

  func testGatewayEvent_initialization() {
    let event = GatewayEvent(event: "test.event", payload: nil)

    XCTAssertEqual(event.event, "test.event")
    XCTAssertEqual(event.type, "event")
    XCTAssertNil(event.payload)
  }

  func testGatewayEvent_withPayload() {
    let payload: [String: Any] = ["key": "value", "number": 42]
    let event = GatewayEvent(event: "test.event", payload: payload)

    XCTAssertEqual(event.event, "test.event")
    XCTAssertNotNil(event.payload)
  }

  func testGatewayEvent_fromJSON() {
    let json: [String: Any] = [
      "type": "event",
      "event": "agent",
      "payload": ["text": "Hello"],
    ]

    let event = GatewayEvent.fromJSON(json)

    XCTAssertEqual(event.event, "agent")
    XCTAssertNotNil(event.payload)
  }

  func testGatewayEvent_isType() {
    let event1 = GatewayEvent(event: "agent.start", payload: nil)
    let event2 = GatewayEvent(event: "agent.stop", payload: nil)
    let event3 = GatewayEvent(event: "other.event", payload: nil)

    XCTAssertTrue(event1.event.contains("agent"))
    XCTAssertTrue(event2.event.contains("agent"))
    XCTAssertFalse(event3.event.contains("agent"))
  }

  // MARK: - GatewayRequest Tests

  func testGatewayRequest_initialization() {
    let request = GatewayRequest(
      id: "req-123",
      method: "run_agent",
      params: ["session_key": "test-key"]
    )

    XCTAssertEqual(request.id, "req-123")
    XCTAssertEqual(request.method, "run_agent")
    XCTAssertEqual(request.type, "req")
  }

  func testGatewayRequest_defaultParams() {
    let request = GatewayRequest(
      id: "req-123",
      method: "run_agent"
    )

    XCTAssertNil(request.params)
  }

  func testGatewayRequest_toJSON() throws {
    let request = GatewayRequest(
      id: "req-123",
      method: "run_agent",
      params: ["key": "value"]
    )

    let data = try request.toJSON()
    XCTAssertGreaterThan(data.count, 0)

    // 验证可以解析
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertEqual(json?["id"] as? String, "req-123")
    XCTAssertEqual(json?["method"] as? String, "run_agent")
  }

  func testGatewayRequest_fromJSON() throws {
    let json: [String: Any] = [
      "type": "req",
      "id": "req-123",
      "method": "run_agent",
      "params": ["key": "value"],
    ]

    let data = try JSONSerialization.data(withJSONObject: json)
    let request = try GatewayRequest.fromJSON(data)

    XCTAssertEqual(request.id, "req-123")
    XCTAssertEqual(request.method, "run_agent")
  }

  // MARK: - GatewayResponse Tests

  func testGatewayResponse_initialization() {
    let response = GatewayResponse(
      id: "resp-123",
      ok: true,
      payload: ["status": "success"]
    )

    XCTAssertEqual(response.id, "resp-123")
    XCTAssertTrue(response.ok)
    XCTAssertNotNil(response.payload)
    XCTAssertNil(response.error)
  }

  func testGatewayResponse_withError() {
    let error = GatewayError(code: 500, message: "Internal error")
    let response = GatewayResponse(
      id: "resp-123",
      ok: false,
      payload: nil,
      error: error
    )

    XCTAssertFalse(response.ok)
    XCTAssertNotNil(response.error)
    XCTAssertEqual(response.error?.code, 500)
    XCTAssertEqual(response.error?.message, "Internal error")
  }

  func testGatewayResponse_fromJSON() {
    let json: [String: Any] = [
      "type": "res",
      "id": "resp-123",
      "ok": true,
      "payload": ["status": "success"],
    ]

    let response = GatewayResponse.fromJSON(json)

    XCTAssertEqual(response.id, "resp-123")
    XCTAssertTrue(response.ok)
  }

  func testGatewayResponse_fromJSONWithError() {
    let json: [String: Any] = [
      "type": "res",
      "id": "resp-123",
      "ok": false,
      "error": ["code": 500, "message": "Error"],
    ]

    let response = GatewayResponse.fromJSON(json)

    XCTAssertFalse(response.ok)
    XCTAssertNotNil(response.error)
    XCTAssertEqual(response.error?.code, 500)
  }

  // MARK: - GatewayError Tests

  func testGatewayError_initialization() {
    let error = GatewayError(code: 404, message: "Not found")

    XCTAssertEqual(error.code, 404)
    XCTAssertEqual(error.message, "Not found")
  }

  func testGatewayError_fromJSON() {
    let json: [String: Any] = [
      "code": 500,
      "message": "Internal server error",
    ]

    let error = GatewayError.fromJSON(json)

    XCTAssertEqual(error.code, 500)
    XCTAssertEqual(error.message, "Internal server error")
  }

  func testGatewayError_commonCodes() {
    let errors = [
      (400, "Bad Request"),
      (401, "Unauthorized"),
      (403, "Forbidden"),
      (404, "Not Found"),
      (500, "Internal Server Error"),
    ]

    for (code, message) in errors {
      let error = GatewayError(code: code, message: message)
      XCTAssertEqual(error.code, code)
      XCTAssertEqual(error.message, message)
    }
  }

  // MARK: - Edge Cases

  func testGatewayRequest_withEmptyParams() {
    let request = GatewayRequest(
      id: "req-123",
      method: "test",
      params: [:]
    )

    XCTAssertNotNil(request.params)
    XCTAssertTrue(request.params!.isEmpty)
  }

  func testGatewayResponse_withNilPayload() {
    let response = GatewayResponse(
      id: "resp-123",
      ok: true,
      payload: nil
    )

    XCTAssertNil(response.payload)
    XCTAssertTrue(response.ok)
  }

  func testGatewayEvent_withNilPayload() {
    let event = GatewayEvent(event: "test", payload: nil)

    XCTAssertNil(event.payload)
  }

  // MARK: - Integration Tests

  func testFullRequestResponseCycle() throws {
    // 创建请求
    let request = GatewayRequest(
      id: "req-123",
      method: "run_agent",
      params: ["session_key": "test-key"]
    )

    // 编码
    let requestData = try request.toJSON()

    // 解码
    let decodedRequest = try GatewayRequest.fromJSON(requestData)
    XCTAssertEqual(decodedRequest.id, "req-123")

    // 创建响应
    let response = GatewayResponse(
      id: "resp-123",
      ok: true,
      payload: ["status": "success"]
    )

    // 验证响应
    XCTAssertTrue(response.ok)
    XCTAssertEqual(response.id, "resp-123")
  }

  // MARK: - Performance Tests

  func testGatewayRequest_toJSON_performance() {
    let request = GatewayRequest(
      id: "req-123",
      method: "run_agent",
      params: ["session_key": "test-key"]
    )

    self.measure {
      _ = try? request.toJSON()
    }
  }

  func testGatewayResponse_fromJSON_performance() {
    let json: [String: Any] = [
      "type": "res",
      "id": "resp-123",
      "ok": true,
      "payload": ["status": "success"],
    ]

    self.measure {
      _ = GatewayResponse.fromJSON(json)
    }
  }
}
