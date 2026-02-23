//
//  ChatMessageTests.swift
//  openclaw-deck-swiftTests
//
//  Created by Jihui Huang on 2/23/26.
//

import Testing
import Foundation
@testable import openclaw_deck_swift

@MainActor
struct ChatMessageTests {
    
    @Test func testMessageRoleEnum() {
        // Test raw values
        #expect(MessageRole.user.rawValue == "user")
        #expect(MessageRole.assistant.rawValue == "assistant")
        #expect(MessageRole.system.rawValue == "system")
        
        // Test Codable
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let roles: [MessageRole] = [.user, .assistant, .system]
        for role in roles {
            let data = try! encoder.encode(role)
            let decoded = try! decoder.decode(MessageRole.self, from: data)
            #expect(decoded == role)
        }
    }
    
    @Test func testToolUseInfo() {
        // Test initialization
        let toolUse = ToolUseInfo(
            toolName: "search",
            input: "query: Swift testing",
            output: "Search results...",
            status: "completed"
        )
        
        #expect(toolUse.toolName == "search")
        #expect(toolUse.input == "query: Swift testing")
        #expect(toolUse.output == "Search results...")
        #expect(toolUse.status == "completed")
        
        // Test with nil output
        let toolUseNoOutput = ToolUseInfo(
            toolName: "code_interpreter",
            input: "print('hello')",
            output: nil,
            status: "running"
        )
        
        #expect(toolUseNoOutput.toolName == "code_interpreter")
        #expect(toolUseNoOutput.input == "print('hello')")
        #expect(toolUseNoOutput.output == nil)
        #expect(toolUseNoOutput.status == "running")
    }
    
    @Test func testChatMessageInitialization() {
        // Test 1: User message
        let userMessage = ChatMessage(
            id: "msg1",
            role: .user,
            text: "Hello, how are you?",
            timestamp: Date(),
            streaming: false,
            thinking: false,
            toolUse: nil,
            runId: "run123",
            isLoaded: true
        )
        
        #expect(userMessage.id == "msg1")
        #expect(userMessage.role == .user)
        #expect(userMessage.text == "Hello, how are you?")
        #expect(userMessage.streaming == false)
        #expect(userMessage.thinking == false)
        #expect(userMessage.toolUse == nil)
        #expect(userMessage.runId == "run123")
        #expect(userMessage.isLoaded == true)
        #expect(userMessage.isUserMessage)
        #expect(!userMessage.isAssistantMessage)
        #expect(!userMessage.isSystemMessage)
        #expect(!userMessage.isStreaming)
        #expect(!userMessage.isThinking)
        #expect(!userMessage.isToolUse)
        
        // Test 2: Assistant message with tool use
        let toolUse = ToolUseInfo(
            toolName: "search",
            input: "query",
            output: "result",
            status: "completed"
        )
        
        let assistantMessage = ChatMessage(
            id: "msg2",
            role: .assistant,
            text: "I found some information for you.",
            timestamp: Date(),
            streaming: true,
            thinking: false,
            toolUse: toolUse,
            runId: "run456",
            isLoaded: false
        )
        
        #expect(assistantMessage.id == "msg2")
        #expect(assistantMessage.role == .assistant)
        #expect(assistantMessage.text == "I found some information for you.")
        #expect(assistantMessage.streaming == true)
        #expect(assistantMessage.thinking == false)
        #expect(assistantMessage.toolUse?.toolName == "search")
        #expect(assistantMessage.runId == "run456")
        #expect(assistantMessage.isLoaded == false)
        #expect(!assistantMessage.isUserMessage)
        #expect(assistantMessage.isAssistantMessage)
        #expect(!assistantMessage.isSystemMessage)
        #expect(assistantMessage.isStreaming)
        #expect(!assistantMessage.isThinking)
        #expect(assistantMessage.isToolUse)
        
        // Test 3: System message
        let systemMessage = ChatMessage(
            id: "msg3",
            role: .system,
            text: "Connected to server",
            timestamp: Date(),
            streaming: nil,
            thinking: nil,
            toolUse: nil,
            runId: nil,
            isLoaded: true
        )
        
        #expect(systemMessage.id == "msg3")
        #expect(systemMessage.role == .system)
        #expect(systemMessage.text == "Connected to server")
        #expect(systemMessage.streaming == nil)
        #expect(systemMessage.thinking == nil)
        #expect(systemMessage.toolUse == nil)
        #expect(systemMessage.runId == nil)
        #expect(systemMessage.isLoaded == true)
        #expect(!systemMessage.isUserMessage)
        #expect(!systemMessage.isAssistantMessage)
        #expect(systemMessage.isSystemMessage)
        #expect(!systemMessage.isStreaming)
        #expect(!systemMessage.isThinking)
        #expect(!systemMessage.isToolUse)
    }
    
    @Test func testChatMessageExtensions() {
        let message = ChatMessage(
            id: "test",
            role: .assistant,
            text: "Test message",
            timestamp: Date()
        )
        
        // Test description
        #expect(message.description == "Test message")
        
        // Test with different roles
        let userMessage = ChatMessage(
            id: "test2",
            role: .user,
            text: "User message",
            timestamp: Date()
        )
        #expect(userMessage.description == "User message")
        
        let systemMessage = ChatMessage(
            id: "test3",
            role: .system,
            text: "System message",
            timestamp: Date()
        )
        #expect(systemMessage.description == "System message")
    }
    
    @Test func testChatMessageCodable() async throws {
        // Test encoding and decoding
        let toolUse = ToolUseInfo(
            toolName: "search",
            input: "query",
            output: "result",
            status: "completed"
        )
        
        let originalMessage = ChatMessage(
            id: "test-message",
            role: .assistant,
            text: "Hello, this is a test message",
            timestamp: Date(),
            streaming: true,
            thinking: false,
            toolUse: toolUse,
            runId: "run-123",
            isLoaded: true
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(originalMessage)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let decodedMessage = try decoder.decode(ChatMessage.self, from: data)
        
        #expect(decodedMessage.id == originalMessage.id)
        #expect(decodedMessage.role == originalMessage.role)
        #expect(decodedMessage.text == originalMessage.text)
        #expect(decodedMessage.streaming == originalMessage.streaming)
        #expect(decodedMessage.thinking == originalMessage.thinking)
        #expect(decodedMessage.toolUse?.toolName == originalMessage.toolUse?.toolName)
        #expect(decodedMessage.toolUse?.input == originalMessage.toolUse?.input)
        #expect(decodedMessage.toolUse?.output == originalMessage.toolUse?.output)
        #expect(decodedMessage.toolUse?.status == originalMessage.toolUse?.status)
        #expect(decodedMessage.runId == originalMessage.runId)
        #expect(decodedMessage.isLoaded == originalMessage.isLoaded)
    }
    
    @Test func testToolUseInfoCodable() async throws {
        // Test encoding and decoding ToolUseInfo
        let originalToolUse = ToolUseInfo(
            toolName: "code_interpreter",
            input: "print('hello world')",
            output: "hello world",
            status: "completed"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalToolUse)
        
        let decoder = JSONDecoder()
        let decodedToolUse = try decoder.decode(ToolUseInfo.self, from: data)
        
        #expect(decodedToolUse.toolName == originalToolUse.toolName)
        #expect(decodedToolUse.input == originalToolUse.input)
        #expect(decodedToolUse.output == originalToolUse.output)
        #expect(decodedToolUse.status == originalToolUse.status)
        
        // Test with nil output
        let toolUseNoOutput = ToolUseInfo(
            toolName: "search",
            input: "query",
            output: nil,
            status: "running"
        )
        
        let data2 = try encoder.encode(toolUseNoOutput)
        let decodedToolUse2 = try decoder.decode(ToolUseInfo.self, from: data2)
        
        #expect(decodedToolUse2.toolName == toolUseNoOutput.toolName)
        #expect(decodedToolUse2.input == toolUseNoOutput.input)
        #expect(decodedToolUse2.output == toolUseNoOutput.output)
        #expect(decodedToolUse2.status == toolUseNoOutput.status)
    }
}