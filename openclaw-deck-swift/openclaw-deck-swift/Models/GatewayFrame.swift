// GatewayFrame.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation

// MARK: - Gateway Frame Types

/// WebSocket 请求帧（请求）
struct GatewayRequest {
    let type: String = "req"
    let id: String
    let method: String
    let params: [String: Any]?

    init(id: String, method: String, params: [String: Any]? = nil) {
        self.id = id
        self.method = method
        self.params = params
    }

    /// 编码为 JSON 数据
    func toJSON() throws -> Data {
        var json: [String: Any] = [
            "type": type,
            "id": id,
            "method": method,
        ]
        if let params = params {
            json["params"] = params
        }
        return try JSONSerialization.data(withJSONObject: json)
    }

    /// 从 JSON 数据解码
    static func fromJSON(_ data: Data) throws -> GatewayRequest {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let id = json["id"] as? String,
            let method = json["method"] as? String
        else {
            throw NSError(
                domain: "GatewayRequest", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
        }

        let type = json["type"] as? String ?? "req"
        let params = json["params"] as? [String: Any]

        return GatewayRequest(id: id, method: method, params: params)
    }
}

/// WebSocket 响应帧（响应）
struct GatewayResponse {
    let type: String = "res"
    let id: String
    let ok: Bool
    let payload: Any?
    let error: GatewayError?

    init(id: String, ok: Bool, payload: Any? = nil, error: GatewayError? = nil) {
        self.id = id
        self.ok = ok
        self.payload = payload
        self.error = error
    }

    /// 从 JSON 字典创建
    static func fromJSON(_ json: [String: Any]) -> GatewayResponse {
        let type = json["type"] as? String ?? "res"
        let id = json["id"] as? String ?? ""
        let ok = json["ok"] as? Bool ?? false
        let payload = json["payload"]
        let errorDict = json["error"] as? [String: Any]
        let error = errorDict != nil ? GatewayError.fromJSON(errorDict!) : nil

        return GatewayResponse(id: id, ok: ok, payload: payload, error: error)
    }
}

/// WebSocket 事件帧（事件）
struct GatewayEvent {
    let type: String
    let event: String
    let payload: Any?
    let seq: Int?
    let stateVersion: Int?

    init(event: String, payload: Any? = nil, seq: Int? = nil, stateVersion: Int? = nil) {
        self.type = "event"
        self.event = event
        self.payload = payload
        self.seq = seq
        self.stateVersion = stateVersion
    }

    /// 从 JSON 字典创建
    static func fromJSON(_ json: [String: Any]) -> GatewayEvent {
        let event = json["event"] as? String ?? ""
        let payload = json["payload"]
        let seq = json["seq"] as? Int
        let stateVersion = json["stateVersion"] as? Int

        return GatewayEvent(event: event, payload: payload, seq: seq, stateVersion: stateVersion)
    }
}

/// Gateway 错误信息
struct GatewayError {
    let code: Int
    let message: String
    let details: String?

    init(code: Int, message: String, details: String? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }

    /// 从 JSON 字典创建
    static func fromJSON(_ json: [String: Any]) -> GatewayError {
        let code = json["code"] as? Int ?? 0
        let message = json["message"] as? String ?? ""
        let details = json["details"] as? String

        return GatewayError(code: code, message: message, details: details)
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
