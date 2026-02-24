//
//  GatewayFrameTests.swift
//  openclaw-deck-swiftTests
//
//  Created by Jihui Huang on 2/23/26.
//

import Testing
import Foundation
@testable import openclaw_deck_swift

@MainActor
struct GatewayFrameTests {

    // MARK: - GatewayRequest Tests

    @Test func testGatewayRequestInitialization() {
        // Test 1: Basic initialization
        let request = GatewayRequest(id: "test-id-1", method: "connect")

        #expect(request.type == "req")
        #expect(request.id == "test-id-1")
        #expect(request.method == "connect")
        #expect(request.params == nil)

        // Test 2: Initialization with params
        let params: [String: Any] = ["key1": "value1", "key2": "value2"]
        let requestWithParams = GatewayRequest(
            id: "test-id-2",
            method: "agent",
            params: params
        )

        #expect(requestWithParams.type == "req")
        #expect(requestWithParams.id == "test-id-2")
        #expect(requestWithParams.method == "agent")
        #expect(requestWithParams.params?["key1"] as? String == "value1")
        #expect(requestWithParams.params?["key2"] as? String == "value2")
    }

    @Test func testGatewayRequestGenerateId() async {
        let id1 = GatewayRequest.generateId()

        // Add small delay to ensure different timestamps
        try? await Task.sleep(nanoseconds: 1_000_000) // 1ms

        let id2 = GatewayRequest.generateId()

        // IDs should be unique (different timestamps)
        #expect(id1.starts(with: "deck-"))
        #expect(id2.starts(with: "deck-"))
        #expect(id1 != id2)

        // IDs should contain timestamp in milliseconds
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let id3 = GatewayRequest.generateId()
        let idTimestamp = Int(id3.replacingOccurrences(of: "deck-", with: "")) ?? 0
        #expect(abs(idTimestamp - timestamp) < 1000) // Within 1 second
    }

    @Test func testGatewayRequestCodable() throws {
        // Test 1: Request without params
        let request1 = GatewayRequest(id: "test-id", method: "connect")

        #expect(request1.type == "req")
        #expect(request1.id == "test-id")
        #expect(request1.method == "connect")
        #expect(request1.params == nil)

        // Test 2: Request with params
        let request2 = GatewayRequest(
            id: "test-id-2",
            method: "agent",
            params: ["agentId": "main", "message": "hello"]
        )

        #expect(request2.type == "req")
        #expect(request2.id == "test-id-2")
        #expect(request2.method == "agent")
        #expect(request2.params?["agentId"] as? String == "main")
        #expect(request2.params?["message"] as? String == "hello")

        // Test 3: JSON encoding/decoding
        let data = try request2.toJSON()
        let decoded = try GatewayRequest.fromJSON(data)

        #expect(decoded.id == request2.id)
        #expect(decoded.method == request2.method)
        #expect(decoded.params?["agentId"] as? String == "main")
    }

    // MARK: - GatewayResponse Tests

    @Test func testGatewayResponseInitialization() {
        // Test 1: Success response
        let successResponse = GatewayResponse(
            id: "test-id",
            ok: true,
            payload: "{\"status\": \"success\"}",
            error: nil
        )

        #expect(successResponse.type == "res")
        #expect(successResponse.id == "test-id")
        #expect(successResponse.ok == true)
        #expect(successResponse.payload as? String == "{\"status\": \"success\"}")
        #expect(successResponse.error == nil)
        #expect(successResponse.isSuccess)

        // Test 2: Error response
        let error = GatewayError(code: 400, message: "Bad request", details: "Invalid params")
        let errorResponse = GatewayResponse(
            id: "test-id-2",
            ok: false,
            payload: nil,
            error: error
        )

        #expect(errorResponse.type == "res")
        #expect(errorResponse.id == "test-id-2")
        #expect(errorResponse.ok == false)
        #expect(errorResponse.payload == nil)
        #expect(errorResponse.error?.code == 400)
        #expect(errorResponse.error?.message == "Bad request")
        #expect(!errorResponse.isSuccess)
    }

    @Test func testGatewayResponseCodable() {
        // Test 1: Success response
        let successResponse = GatewayResponse(
            id: "test-id",
            ok: true,
            payload: ["runId": "run-123", "status": "running"],
            error: nil
        )

        #expect(successResponse.type == "res")
        #expect(successResponse.id == "test-id")
        #expect(successResponse.ok == true)
        #expect(successResponse.isSuccess)
        #expect(successResponse.error == nil)

        // Test 2: Error response
        let error = GatewayError(code: 500, message: "Internal error", details: "Server crashed")
        let errorResponse = GatewayResponse(
            id: "test-id-2",
            ok: false,
            payload: nil,
            error: error
        )

        #expect(errorResponse.type == "res")
        #expect(errorResponse.id == "test-id-2")
        #expect(errorResponse.ok == false)
        #expect(errorResponse.payload == nil)
        #expect(errorResponse.error?.code == 500)
        #expect(errorResponse.error?.message == "Internal error")
        #expect(errorResponse.error?.details == "Server crashed")

        // Test 3: JSON parsing
        let json: [String: Any] = [
            "type": "res",
            "id": "test-123",
            "ok": true,
            "payload": ["result": "success"]
        ]
        let parsed = GatewayResponse.fromJSON(json)

        #expect(parsed.type == "res")
        #expect(parsed.id == "test-123")
        #expect(parsed.ok == true)
        #expect(parsed.payload != nil)
    }

    // MARK: - GatewayEvent Tests

    @Test func testGatewayEventInitialization() {
        // Test 1: Basic event
        let event1 = GatewayEvent(event: "agent.content")

        #expect(event1.type == "event")
        #expect(event1.event == "agent.content")
        #expect(event1.payload == nil)
        #expect(event1.seq == nil)
        #expect(event1.stateVersion == nil)

        // Test 2: Event with all fields
        let event2 = GatewayEvent(
            event: "agent.done",
            payload: "{\"result\": \"completed\"}",
            seq: 5,
            stateVersion: 10
        )

        #expect(event2.type == "event")
        #expect(event2.event == "agent.done")
        #expect(event2.payload as? String == "{\"result\": \"completed\"}")
        #expect(event2.seq == 5)
        #expect(event2.stateVersion == 10)
    }

    @Test func testGatewayEventIsType() {
        let event = GatewayEvent(event: "agent.content")

        #expect(event.isType("agent.content"))
        #expect(!event.isType("agent.done"))
        #expect(!event.isType("agent.error"))
    }

    @Test func testGatewayEventCodable() {
        // Test 1: Event without optional fields
        let event1 = GatewayEvent(event: "agent.thinking")

        #expect(event1.type == "event")
        #expect(event1.event == "agent.thinking")
        #expect(event1.payload == nil)
        #expect(event1.seq == nil)
        #expect(event1.stateVersion == nil)

        // Test 2: Event with all fields
        let event2 = GatewayEvent(
            event: "agent.tool_use",
            payload: ["tool": "search", "input": "query"],
            seq: 3,
            stateVersion: 7
        )

        #expect(event2.type == "event")
        #expect(event2.event == "agent.tool_use")
        #expect(event2.payload != nil)
        #expect(event2.seq == 3)
        #expect(event2.stateVersion == 7)

        // Test 3: JSON parsing
        let json: [String: Any] = [
            "type": "event",
            "event": "agent.content",
            "payload": "Hello",
            "seq": 1
        ]
        let parsed = GatewayEvent.fromJSON(json)

        #expect(parsed.type == "event")
        #expect(parsed.event == "agent.content")
        #expect(parsed.payload as? String == "Hello")
        #expect(parsed.seq == 1)
    }

    // MARK: - GatewayError Tests

    @Test func testGatewayErrorInitialization() {
        // Test 1: Basic error
        let error1 = GatewayError(code: 400, message: "Bad request")

        #expect(error1.code == 400)
        #expect(error1.message == "Bad request")
        #expect(error1.details == nil)

        // Test 2: Error with details
        let error2 = GatewayError(
            code: 500,
            message: "Internal server error",
            details: "Database connection failed"
        )

        #expect(error2.code == 500)
        #expect(error2.message == "Internal server error")
        #expect(error2.details == "Database connection failed")
    }

    @Test func testGatewayErrorCodable() {
        // Test 1: Error without details
        let error1 = GatewayError(code: 401, message: "Unauthorized")

        #expect(error1.code == 401)
        #expect(error1.message == "Unauthorized")
        #expect(error1.details == nil)

        // Test 2: Error with details
        let error2 = GatewayError(
            code: 403,
            message: "Forbidden",
            details: "Insufficient permissions"
        )

        #expect(error2.code == 403)
        #expect(error2.message == "Forbidden")
        #expect(error2.details == "Insufficient permissions")

        // Test 3: JSON parsing
        let json: [String: Any] = [
            "code": 500,
            "message": "Internal error",
            "details": "Server crashed"
        ]
        let parsed = GatewayError.fromJSON(json)

        #expect(parsed.code == 500)
        #expect(parsed.message == "Internal error")
        #expect(parsed.details == "Server crashed")
    }

    // MARK: - Integration Tests

    @Test func testFullRequestResponseCycle() {
        // Simulate a full request/response cycle
        let request = GatewayRequest(
            id: "deck-1-1234567890",
            method: "agent",
            params: ["agentId": "main", "message": "Hello"]
        )

        // Simulate server response
        let response = GatewayResponse(
            id: "deck-1-1234567890",
            ok: true,
            payload: ["runId": "run-abc", "status": "running"],
            error: nil
        )

        #expect(request.id == response.id)
        #expect(response.ok == true)
        #expect(response.error == nil)
    }

    @Test func testEventStream() {
        // Simulate a stream of events
        let events = [
            GatewayEvent(event: "agent.thinking", seq: 1, stateVersion: 1),
            GatewayEvent(event: "agent.content", payload: "Hello", seq: 2, stateVersion: 2),
            GatewayEvent(event: "agent.content", payload: " world", seq: 3, stateVersion: 3),
            GatewayEvent(event: "agent.done", seq: 4, stateVersion: 4)
        ]

        var accumulatedContent = ""

        for event in events {
            if event.event == "agent.content", let payload = event.payload as? String {
                accumulatedContent += payload
            }
        }

        #expect(accumulatedContent == "Hello world")
    }
}
