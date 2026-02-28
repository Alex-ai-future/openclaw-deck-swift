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
    XCTAssertNil(event.payload)
  }

  func testGatewayEvent_withPayload() {
    let payload: [String: Any] = ["key": "value", "number": 42]
    let event = GatewayEvent(event: "test.event", payload: payload)
    
    XCTAssertEqual(event.event, "test.event")
    XCTAssertNotNil(event.payload)
  }

  func testGatewayEvent_isType() {
    let event1 = GatewayEvent(event: "agent.start", payload: nil)
    let event2 = GatewayEvent(event: "agent.stop", payload: nil)
    let event3 = GatewayEvent(event: "other.event", payload: nil)
    
    XCTAssertTrue(event1.isType("agent"))
    XCTAssertTrue(event2.isType("agent"))
    XCTAssertFalse(event3.isType("agent"))
  }

  func testGatewayEvent_isType_withNestedPath() {
    let event = GatewayEvent(event: "gateway.agent.start", payload: nil)
    
    XCTAssertTrue(event.isType("gateway"))
    XCTAssertTrue(event.isType("gateway.agent"))
    XCTAssertTrue(event.isType("agent"))
    XCTAssertFalse(event.isType("other"))
  }

  func testGatewayEvent_isType_emptyString() {
    let event = GatewayEvent(event: "test.event", payload: nil)
    
    XCTAssertFalse(event.isType(""))
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
    XCTAssertEqual(request.params?["session_key"] as? String, "test-key")
  }

  func testGatewayRequest_defaultID() {
    let request = GatewayRequest(
      method: "run_agent",
      params: nil
    )
    
    XCTAssertNotNil(request.id)
    XCTAssertFalse(request.id.isEmpty)
  }

  func testGatewayRequest_encoding() throws {
    let request = GatewayRequest(
      id: "req-123",
      method: "run_agent",
      params: ["key": "value"]
    )
    
    let encoder = JSONEncoder()
    let jsonData = try encoder.encode(request)
    
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(GatewayRequest.self, from: jsonData)
    
    XCTAssertEqual(decoded.id, "req-123")
    XCTAssertEqual(decoded.method, "run_agent")
    XCTAssertEqual(decoded.params?["key"] as? String, "value")
  }

  func testGatewayRequest_withNilParams() throws {
    let request = GatewayRequest(
      id: "req-123",
      method: "run_agent",
      params: nil
    )
    
    let encoder = JSONEncoder()
    let jsonData = try encoder.encode(request)
    
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(GatewayRequest.self, from: jsonData)
    
    XCTAssertNil(decoded.params)
  }

  // MARK: - GatewayResponse Tests

  func testGatewayResponse_initialization() {
    let response = GatewayResponse(
      id: "resp-123",
      result: ["status": "success"],
      error: nil
    )
    
    XCTAssertEqual(response.id, "resp-123")
    XCTAssertEqual(response.result?["status"] as? String, "success")
    XCTAssertNil(response.error)
  }

  func testGatewayResponse_withError() {
    let error = GatewayError(code: 500, message: "Internal error")
    let response = GatewayResponse(
      id: "resp-123",
      result: nil,
      error: error
    )
    
    XCTAssertNil(response.result)
    XCTAssertNotNil(response.error)
    XCTAssertEqual(response.error?.code, 500)
    XCTAssertEqual(response.error?.message, "Internal error")
  }

  func testGatewayResponse_encoding() throws {
    let response = GatewayResponse(
      id: "resp-123",
      result: ["data": "value"],
      error: nil
    )
    
    let encoder = JSONEncoder()
    let jsonData = try encoder.encode(response)
    
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(GatewayResponse.self, from: jsonData)
    
    XCTAssertEqual(decoded.id, "resp-123")
    XCTAssertEqual(decoded.result?["data"] as? String, "value")
  }

  // MARK: - GatewayError Tests

  func testGatewayError_initialization() {
    let error = GatewayError(code: 404, message: "Not found")
    
    XCTAssertEqual(error.code, 404)
    XCTAssertEqual(error.message, "Not found")
  }

  func testGatewayError_fromJSON() throws {
    let json = """
    {"code": 500, "message": "Internal server error"}
    """
    
    let data = Data(json.utf8)
    let decoder = JSONDecoder()
    let error = try decoder.decode(GatewayError.self, from: data)
    
    XCTAssertEqual(error.code, 500)
    XCTAssertEqual(error.message, "Internal server error")
  }

  func testGatewayError_encoding() throws {
    let error = GatewayError(code: 403, message: "Forbidden")
    
    let encoder = JSONEncoder()
    let jsonData = try encoder.encode(error)
    
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(GatewayError.self, from: jsonData)
    
    XCTAssertEqual(decoded.code, 403)
    XCTAssertEqual(decoded.message, "Forbidden")
  }

  func testGatewayError_commonCodes() {
    let errors = [
      (400, "Bad Request"),
      (401, "Unauthorized"),
      (403, "Forbidden"),
      (404, "Not Found"),
      (500, "Internal Server Error"),
      (502, "Bad Gateway"),
      (503, "Service Unavailable"),
    ]
    
    for (code, message) in errors {
      let error = GatewayError(code: code, message: message)
      XCTAssertEqual(error.code, code)
      XCTAssertEqual(error.message, message)
    }
  }

  // MARK: - Event Stream Tests

  func testEventStreamParsing() throws {
    let eventData = """
    event: agent
    data: {"sessionKey": "test", "text": "Hello"}
    
    """
    
    let data = Data(eventData.utf8)
    let events = try GatewayEvent.parseEventStream(data)
    
    XCTAssertEqual(events.count, 1)
    XCTAssertEqual(events[0].event, "agent")
    XCTAssertNotNil(events[0].payload)
  }

  func testEventStreamParsing_multipleEvents() throws {
    let eventData = """
    event: agent
    data: {"text": "First"}
    
    event: agent
    data: {"text": "Second"}
    
    """
    
    let data = Data(eventData.utf8)
    let events = try GatewayEvent.parseEventStream(data)
    
    XCTAssertEqual(events.count, 2)
    XCTAssertEqual(events[0].payload?["text"] as? String, "First")
    XCTAssertEqual(events[1].payload?["text"] as? String, "Second")
  }

  func testEventStreamParsing_emptyData() throws {
    let data = Data()
    let events = try GatewayEvent.parseEventStream(data)
    
    XCTAssertEqual(events.count, 0)
  }

  func testEventStreamParsing_malformedData() {
    let malformedData = """
    not a valid event format
    
    """
    
    let data = Data(malformedData.utf8)
    
    // 应该抛出错误
    XCTAssertThrowsError(try GatewayEvent.parseEventStream(data))
  }

  // MARK: - Full Request/Response Cycle Tests

  func testFullRequestResponseCycle() throws {
    // 创建请求
    let request = GatewayRequest(
      id: "req-123",
      method: "run_agent",
      params: ["session_key": "test-key"]
    )
    
    // 编码请求
    let encoder = JSONEncoder()
    let requestData = try encoder.encode(request)
    
    // 解码请求
    let decoder = JSONDecoder()
    let decodedRequest = try decoder.decode(GatewayRequest.self, from: requestData)
    
    XCTAssertEqual(decodedRequest.id, "req-123")
    XCTAssertEqual(decodedRequest.method, "run_agent")
    
    // 创建响应
    let response = GatewayResponse(
      id: "req-123",
      result: ["status": "success"],
      error: nil
    )
    
    // 编码响应
    let responseData = try encoder.encode(response)
    
    // 解码响应
    let decodedResponse = try decoder.decode(GatewayResponse.self, from: responseData)
    
    XCTAssertEqual(decodedResponse.id, "req-123")
    XCTAssertEqual(decodedResponse.result?["status"] as? String, "success")
  }

  // MARK: - Edge Cases

  func testGatewayRequest_withComplexParams() throws {
    let complexParams: [String: Any] = [
      "string": "value",
      "number": 42,
      "array": [1, 2, 3],
      "nested": ["key": "value"]
    ]
    
    let request = GatewayRequest(
      id: "req-123",
      method: "complex_method",
      params: complexParams
    )
    
    let encoder = JSONEncoder()
    let jsonData = try encoder.encode(request)
    
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(GatewayRequest.self, from: jsonData)
    
    XCTAssertEqual(decoded.method, "complex_method")
    XCTAssertNotNil(decoded.params)
  }

  func testGatewayResponse_withComplexResult() throws {
    let complexResult: [String: Any] = [
      "data": ["id": 1, "name": "test"],
      "count": 10,
      "items": ["a", "b", "c"]
    ]
    
    let response = GatewayResponse(
      id: "resp-123",
      result: complexResult,
      error: nil
    )
    
    let encoder = JSONEncoder()
    let jsonData = try encoder.encode(response)
    
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(GatewayResponse.self, from: jsonData)
    
    XCTAssertNotNil(decoded.result)
    XCTAssertEqual(decoded.id, "resp-123")
  }

  // MARK: - Performance Tests

  func testEventStreamParsing_performance() {
    let eventData = """
    event: agent
    data: {"text": "Test message"}
    
    """
    
    let data = Data(eventData.utf8)
    
    self.measure {
      _ = try? GatewayEvent.parseEventStream(data)
    }
  }

  func testJSONEncoding_performance() throws {
    let request = GatewayRequest(
      id: "req-123",
      method: "run_agent",
      params: ["session_key": "test-key"]
    )
    
    self.measure {
      _ = try? JSONEncoder().encode(request)
    }
  }
}
