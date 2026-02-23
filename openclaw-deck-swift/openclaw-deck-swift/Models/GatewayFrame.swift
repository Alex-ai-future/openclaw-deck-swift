// GatewayFrame.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation

// MARK: - Gateway Frame Types

/// WebSocket 请求帧（请求）
struct GatewayRequest: Codable {
    let type: String = "req"
    let id: String
    let method: String
    let params: [String: String]?

    enum CodingKeys: String, CodingKey {
        case type, id, method, params
    }

    init(id: String, method: String, params: [String: String]? = nil) {
        self.id = id
        self.method = method
        self.params = params
    }
}

/// WebSocket 响应帧（响应）
struct GatewayResponse: Codable {
    let type: String = "res"
    let id: String
    let ok: Bool
    let payload: String?
    let error: GatewayError?

    enum CodingKeys: String, CodingKey {
        case type, id, ok, payload, error
    }

    init(id: String, ok: Bool, payload: String? = nil, error: GatewayError? = nil) {
        self.id = id
        self.ok = ok
        self.payload = payload
        self.error = error
    }
}

/// WebSocket 事件帧（事件）
struct GatewayEvent: Codable {
    let type: String = "event"
    let event: String
    let payload: String?
    let seq: Int?
    let stateVersion: Int?

    enum CodingKeys: String, CodingKey {
        case type, event, payload, seq, stateVersion
    }

    init(event: String, payload: String? = nil, seq: Int? = nil, stateVersion: Int? = nil) {
        self.event = event
        self.payload = payload
        self.seq = seq
        self.stateVersion = stateVersion
    }
}

/// Gateway 错误信息
struct GatewayError: Codable {
    let code: Int
    let message: String
    let details: String?

    enum CodingKeys: String, CodingKey {
        case code, message, details
    }

    init(code: Int, message: String, details: String? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }
}

// MARK: - Extensions

extension GatewayRequest {
    /// 生成唯一的请求 ID
    static func generateId() -> String {
        return "deck-\(Int(Date().timeIntervalSince1970 * 1000))"
    }
}

extension GatewayResponse {
    /// 检查响应是否成功
    var isSuccess: Bool {
        return ok
    }
}

extension GatewayEvent {
    /// 检查事件类型是否为指定类型
    func isType(_ eventType: String) -> Bool {
        return event == eventType
    }
}
