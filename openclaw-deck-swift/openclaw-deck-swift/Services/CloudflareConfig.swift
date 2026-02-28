// CloudflareConfig.swift
// OpenClaw Deck Swift
//
// Cloudflare KV 配置管理

import Foundation
import os.log

private let logger = Logger(subsystem: "com.openclaw.deck", category: "CloudflareConfig")

/// Cloudflare KV 配置
struct CloudflareConfig {
  /// Account ID
  var accountId: String

  /// Namespace ID
  var namespaceId: String

  /// User ID
  var userId: String

  /// API Token（敏感信息，存储在 Keychain）
  var apiToken: String

  // MARK: - UserDefaults Keys

  private enum Keys {
    static let accountId = "openclaw.deck.cloudflare.accountId"
    static let namespaceId = "openclaw.deck.cloudflare.namespaceId"
    static let userId = "openclaw.deck.cloudflare.userId"
    static let apiToken = "openclaw.deck.cloudflare.apiToken"
  }

  // MARK: - 加载配置

  /// 从 UserDefaults 和 Keychain 加载配置
  static func load() -> CloudflareConfig? {
    let accountId = UserDefaults.standard.string(forKey: Keys.accountId) ?? ""
    let namespaceId = UserDefaults.standard.string(forKey: Keys.namespaceId) ?? ""
    let userId = UserDefaults.standard.string(forKey: Keys.userId) ?? ""
    let apiToken = KeychainWrapper.shared.string(forKey: Keys.apiToken) ?? ""

    // 如果所有字段都为空，返回 nil
    if accountId.isEmpty && namespaceId.isEmpty && userId.isEmpty && apiToken.isEmpty {
      return nil
    }

    return CloudflareConfig(
      accountId: accountId,
      namespaceId: namespaceId,
      userId: userId,
      apiToken: apiToken
    )
  }

  // MARK: - 保存配置

  /// 保存配置到 UserDefaults 和 Keychain
  func save() throws {
    UserDefaults.standard.set(accountId, forKey: Keys.accountId)
    UserDefaults.standard.set(namespaceId, forKey: Keys.namespaceId)
    UserDefaults.standard.set(userId, forKey: Keys.userId)

    // API Token 存入 Keychain（加密）
    try KeychainWrapper.shared.set(apiToken, forKey: Keys.apiToken)

    logger.debug("配置已保存")
  }

  // MARK: - 清除配置

  /// 清除所有配置
  static func clear() {
    UserDefaults.standard.removeObject(forKey: Keys.accountId)
    UserDefaults.standard.removeObject(forKey: Keys.namespaceId)
    UserDefaults.standard.removeObject(forKey: Keys.userId)
    KeychainWrapper.shared.delete(forKey: Keys.apiToken)

    logger.info("配置已清除")
  }

  // MARK: - 验证

  /// 检查配置是否有效
  var isValid: Bool {
    !accountId.trimmingCharacters(in: .whitespaces).isEmpty
      && !namespaceId.trimmingCharacters(in: .whitespaces).isEmpty
      && !userId.trimmingCharacters(in: .whitespaces).isEmpty
      && !apiToken.trimmingCharacters(in: .whitespaces).isEmpty
  }

  // MARK: - URL 构建

  /// 构建 KV API URL
  func buildKVURL() -> String? {
    guard isValid else { return nil }
    return
      "https://api.cloudflare.com/client/v4/accounts/\(accountId)/storage/kv/namespaces/\(namespaceId)/values/\(userId)"
  }
}
