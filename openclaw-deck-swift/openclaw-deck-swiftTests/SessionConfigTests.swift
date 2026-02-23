//
//  SessionConfigTests.swift
//  openclaw-deck-swiftTests
//
//  Created by Jihui Huang on 2/23/26.
//

import Testing
import Foundation
@testable import openclaw_deck_swift

@MainActor
struct SessionConfigTests {
    
    @Test func testGenerateId() {
        // Test 1: Normal name with spaces
        let name1 = "My Test Session"
        let id1 = SessionConfig.generateId(from: name1)
        #expect(id1 == "my-test-session")
        
        // Test 2: Name with special characters
        let name2 = "Test@Session#123"
        let id2 = SessionConfig.generateId(from: name2)
        #expect(id2 == "test-session-123")
        
        // Test 3: Empty name should generate timestamp-based ID
        let name3 = ""
        let id3 = SessionConfig.generateId(from: name3)
        #expect(id3.contains("session-"))
        
        // Test 4: Name with only special characters
        let name4 = "@#$%"
        let id4 = SessionConfig.generateId(from: name4)
        #expect(id4.contains("session-"))
        
        // Test 5: Name with uppercase letters
        let name5 = "UPPERCASE TEST"
        let id5 = SessionConfig.generateId(from: name5)
        #expect(id5 == "uppercase-test")
    }
    
    @Test func testGenerateSessionKey() {
        // Test 1: Normal session ID
        let sessionId1 = "test-session-123"
        let key1 = SessionConfig.generateSessionKey(sessionId: sessionId1)
        #expect(key1 == "agent:main:test-session-123")
        
        // Test 2: Empty session ID
        let sessionId2 = ""
        let key2 = SessionConfig.generateSessionKey(sessionId: sessionId2)
        #expect(key2 == "agent:main:")
        
        // Test 3: Session ID with special characters
        let sessionId3 = "test@session"
        let key3 = SessionConfig.generateSessionKey(sessionId: sessionId3)
        #expect(key3 == "agent:main:test@session")
    }
    
    @Test func testSessionConfigInitialization() {
        // Test 1: Create a session config with all fields
        let id = "test-session"
        let sessionKey = "agent:main:test-session"
        let createdAt = Date()
        let name = "Test Session"
        let icon = "test-icon"
        let accentColor = "#FF0000"
        let context = "Test context"
        
        let config = SessionConfig(
            id: id,
            sessionKey: sessionKey,
            createdAt: createdAt,
            name: name,
            icon: icon,
            accentColor: accentColor,
            context: context
        )
        
        #expect(config.id == id)
        #expect(config.sessionKey == sessionKey)
        #expect(config.createdAt == createdAt)
        #expect(config.name == name)
        #expect(config.icon == icon)
        #expect(config.accentColor == accentColor)
        #expect(config.context == context)
        #expect(!config.isEmpty)
        
        // Test 2: Create a session config with minimal fields
        let minimalConfig = SessionConfig(
            id: "minimal",
            sessionKey: "agent:main:minimal",
            createdAt: Date(),
            name: nil,
            icon: nil,
            accentColor: nil,
            context: nil
        )
        
        #expect(minimalConfig.id == "minimal")
        #expect(minimalConfig.sessionKey == "agent:main:minimal")
        #expect(minimalConfig.name == nil)
        #expect(minimalConfig.icon == nil)
        #expect(minimalConfig.accentColor == nil)
        #expect(minimalConfig.context == nil)
        #expect(!minimalConfig.isEmpty)
    }
    
    @Test func testEmptyCheck() {
        // Test 1: Empty config
        let emptyConfig = SessionConfig(
            id: "",
            sessionKey: "",
            createdAt: Date(),
            name: nil,
            icon: nil,
            accentColor: nil,
            context: nil
        )
        
        #expect(emptyConfig.isEmpty)
        
        // Test 2: Non-empty config
        let nonEmptyConfig = SessionConfig(
            id: "test",
            sessionKey: "agent:main:test",
            createdAt: Date(),
            name: nil,
            icon: nil,
            accentColor: nil,
            context: nil
        )
        
        #expect(!nonEmptyConfig.isEmpty)
    }
    
    @Test func testCodable() async throws {
        // Test encoding and decoding
        let originalConfig = SessionConfig(
            id: "test-session",
            sessionKey: "agent:main:test-session",
            createdAt: Date(),
            name: "Test Session",
            icon: "test-icon",
            accentColor: "#FF0000",
            context: "Test context"
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(originalConfig)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let decodedConfig = try decoder.decode(SessionConfig.self, from: data)
        
        #expect(decodedConfig.id == originalConfig.id)
        #expect(decodedConfig.sessionKey == originalConfig.sessionKey)
        #expect(decodedConfig.name == originalConfig.name)
        #expect(decodedConfig.icon == originalConfig.icon)
        #expect(decodedConfig.accentColor == originalConfig.accentColor)
        #expect(decodedConfig.context == originalConfig.context)
    }
}