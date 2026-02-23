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
        let params: [String: String] = ["key1": "value1", "key2": "value2"]
        let requestWithParams = GatewayRequest(
            id: "test-id-2",
            method: "agent",
            params: params
        )

        #expect(requestWithParams.type == "req")
        #expect(requestWithParams.id == "test-id-2")
        #expect(requestWithParams.method == "agent")
        #expect(requestWithParams.params?["key1"] == "value1")
        #expect(requestWithParams.params?["key2"] == "value2")
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

    @Test func testGatewayRequestCodable() async throws {
        // Test 1: Request without params
        let request1 = GatewayRequest(id: "test-id", method: "connect")

        let encoder = JSONEncoder()
        let data1 = try encoder.encode(request1)

        let decoder = JSONDecoder()
        let decoded1 = try decoder.decode(GatewayRequest.self, from: data1)

        #expect(decoded1.type == "req")
        #expect(decoded1.id == "test-id")
        #expect(decoded1.method == "connect")
        #expect(decoded1.params == nil)

        // Test 2: Request with params
        let request2 = GatewayRequest(
            id: "test-id-2",
            method: "agent",
            params: ["agentId": "main", "message": "hello"]
        )

        let data2 = try encoder.encode(request2)
        let decoded2 = try decoder.decode(GatewayRequest.self, from: data2)

        #expect(decoded2.type == "req")
        #expect(decoded2.id == "test-id-2")
        #expect(decoded2.method == "agent")
        #expect(decoded2.params?["agentId"] == "main")
        #expect(decoded2.params?["message"] == "hello")
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
        #expect(successResponse.payload == "{\"status\": \"success\"}")
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

    @Test func testGatewayResponseCodable() async throws {
        // Test 1: Success response
        let successResponse = GatewayResponse(
            id: "test-id",
            ok: true,
            payload: "{\"runId\": \"run-123\", \"status\": \"running\"}",
            error: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(successResponse)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(GatewayResponse.self, from: data)

        #expect(decoded.type == "res")
        #expect(decoded.id == "test-id")
        #expect(decoded.ok == true)
        #expect(decoded.payload == "{\"runId\": \"run-123\", \"status\": \"running\"}")
        #expect(decoded.error == nil)

        // Test 2: Error response
        let error = GatewayError(code: 500, message: "Internal error", details: "Server crashed")
        let errorResponse = GatewayResponse(
            id: "test-id-2",
            ok: false,
            payload: nil,
            error: error
        )

        let data2 = try encoder.encode(errorResponse)
        let decoded2 = try decoder.decode(GatewayResponse.self, from: data2)

        #expect(decoded2.type == "res")
        #expect(decoded2.id == "test-id-2")
        #expect(decoded2.ok == false)
        #expect(decoded2.payload == nil)
        #expect(decoded2.error?.code == 500)
        #expect(decoded2.error?.message == "Internal error")
        #expect(decoded2.error?.details == "Server crashed")
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
        #expect(event2.payload == "{\"result\": \"completed\"}")
        #expect(event2.seq == 5)
        #expect(event2.stateVersion == 10)
    }

    @Test func testGatewayEventIsType() {
        let event = GatewayEvent(event: "agent.content")

        #expect(event.isType("agent.content"))
        #expect(!event.isType("agent.done"))
        #expect(!event.isType("agent.error"))
    }

    @Test func testGatewayEventCodable() async throws {
        // Test 1: Event without optional fields
        let event1 = GatewayEvent(event: "agent.thinking")

        let encoder = JSONEncoder()
        let data1 = try encoder.encode(event1)

        let decoder = JSONDecoder()
        let decoded1 = try decoder.decode(GatewayEvent.self, from: data1)

        #expect(decoded1.type == "event")
        #expect(decoded1.event == "agent.thinking")
        #expect(decoded1.payload == nil)
        #expect(decoded1.seq == nil)
        #expect(decoded1.stateVersion == nil)

        // Test 2: Event with all fields
        let event2 = GatewayEvent(
            event: "agent.tool_use",
            payload: "{\"tool\": \"search\"}",
            seq: 3,
            stateVersion: 7
        )

        let data2 = try encoder.encode(event2)
        let decoded2 = try decoder.decode(GatewayEvent.self, from: data2)

        #expect(decoded2.type == "event")
        #expect(decoded2.event == "agent.tool_use")
        #expect(decoded2.payload == "{\"tool\": \"search\"}")
        #expect(decoded2.seq == 3)
        #expect(decoded2.stateVersion == 7)
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

    @Test func testGatewayErrorCodable() async throws {
        // Test 1: Error without details
        let error1 = GatewayError(code: 401, message: "Unauthorized")

        let encoder = JSONEncoder()
        let data1 = try encoder.encode(error1)

        let decoder = JSONDecoder()
        let decoded1 = try decoder.decode(GatewayError.self, from: data1)

        #expect(decoded1.code == 401)
        #expect(decoded1.message == "Unauthorized")
        #expect(decoded1.details == nil)

        // Test 2: Error with details
        let error2 = GatewayError(
            code: 403,
            message: "Forbidden",
            details: "Insufficient permissions"
        )

        let data2 = try encoder.encode(error2)
        let decoded2 = try decoder.decode(GatewayError.self, from: data2)

        #expect(decoded2.code == 403)
        #expect(decoded2.message == "Forbidden")
        #expect(decoded2.details == "Insufficient permissions")
    }

    // MARK: - Integration Tests

    @Test func testFullRequestResponseCycle() async throws {
        // Simulate a full request/response cycle
        let request = GatewayRequest(
            id: "deck-1-1234567890",
            method: "agent",
            params: ["agentId": "main", "message": "Hello"]
        )

        let encoder = JSONEncoder()
        let requestData = try encoder.encode(request)

        // Simulate server response
        let response = GatewayResponse(
            id: "deck-1-1234567890",
            ok: true,
            payload: "{\"runId\": \"run-abc\", \"status\": \"running\"}",
            error: nil
        )

        let responseData = try encoder.encode(response)

        let decoder = JSONDecoder()
        let decodedRequest = try decoder.decode(GatewayRequest.self, from: requestData)
        let decodedResponse = try decoder.decode(GatewayResponse.self, from: responseData)

        #expect(decodedRequest.id == decodedResponse.id)
        #expect(decodedResponse.ok == true)
        #expect(decodedResponse.error == nil)
    }

    @Test func testEventStream() async throws {
        // Simulate a stream of events
        let events = [
            GatewayEvent(event: "agent.thinking", seq: 1, stateVersion: 1),
            GatewayEvent(event: "agent.content", payload: "Hello", seq: 2, stateVersion: 2),
            GatewayEvent(event: "agent.content", payload: " world", seq: 3, stateVersion: 3),
            GatewayEvent(event: "agent.done", seq: 4, stateVersion: 4)
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        var accumulatedContent = ""

        for event in events {
            let data = try encoder.encode(event)
            let decoded = try decoder.decode(GatewayEvent.self, from: data)

            if decoded.event == "agent.content", let payload = decoded.payload {
                accumulatedContent += payload
            }
        }

        #expect(accumulatedContent == "Hello world")
    }
}
