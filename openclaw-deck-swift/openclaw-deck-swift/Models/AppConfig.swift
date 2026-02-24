// AppConfig.swift
// OpenClaw Deck Swift
//
// Created by jihuihuang on 2/23/2026.
// Copyright © 2026 OpenClaw. All rights reserved.

import Foundation

/// 应用配置信息（本地管理）
struct AppConfig: Codable {
  /// Gateway WebSocket URL（默认值：ws://127.0.0.1:18789）
  var gatewayUrl: String

  /// 认证 Token（用户手动输入，不持久化存储）
  var token: String?

  /// 固定的 Main Agent ID（用于与 Gateway 通信）
  let mainAgentId: String

  /// 最低支持版本（iPadOS 18.0 / macOS 15.0）
  let minSupportedVersion: String

  /// 默认配置（用于初始化）
  static let `default` = AppConfig(
    gatewayUrl: "ws://127.0.0.1:18789",
    token: nil,
    mainAgentId: "main",
    minSupportedVersion: "18.0"
  )

  init(
    gatewayUrl: String, token: String?, mainAgentId: String, minSupportedVersion: String = "18.0"
  ) {
    self.gatewayUrl = gatewayUrl
    self.token = token
    self.mainAgentId = mainAgentId
    self.minSupportedVersion = minSupportedVersion
  }

  /// 检查 Gateway URL 是否有效（是否为有效的 WebSocket URL）
  var isValidGatewayUrl: Bool {
    guard let url = URL(string: gatewayUrl),
      !gatewayUrl.isEmpty,
      url.host != nil
    else { return false }
    return url.scheme == "ws" || url.scheme == "wss"
  }

  /// 检查 Token 是否有效（非空）
  var isValidToken: Bool {
    guard let token = token else { return false }
    return !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  /// 检查配置是否完整（所有必要字段都已设置）
  var isComplete: Bool {
    return isValidGatewayUrl && isValidToken
  }
}

// MARK: - Extensions

extension AppConfig {
  /// 检查配置是否为默认配置（未修改过）
  var isDefault: Bool {
    return gatewayUrl == "ws://127.0.0.1:18789" && token == nil
  }
}
