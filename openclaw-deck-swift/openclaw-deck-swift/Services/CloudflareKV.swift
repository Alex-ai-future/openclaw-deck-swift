// CloudflareKV.swift
// OpenClaw Deck Swift
//
// Cloudflare KV 同步服务 - 实现多设备 Session 同步

import Foundation
import os.log

private let logger = Logger(subsystem: "com.openclaw.deck", category: "CloudflareKV")

// MARK: - 同步数据结构

/// Cloudflare KV 中存储的同步数据
struct SyncData: Codable, Equatable {
  /// Session ID 列表（有序）
  var sessions: [String]

  /// 最后更新时间戳
  var lastUpdated: String

  /// 创建空数据
  static var empty: SyncData {
    return SyncData(
      sessions: [],
      lastUpdated: ISO8601DateFormatter().string(from: Date()))
  }
}

// MARK: - 合并结果

/// 合并结果来源
enum MergeSource: CustomStringConvertible {
  case local  // 本地数据更新
  case remote  // 云端数据更新
  case same  // 数据一致
  case conflict  // 数据冲突，需要用户选择
  
  var description: String {
    switch self {
    case .local: return "local"
    case .remote: return "remote"
    case .same: return "same"
    case .conflict: return "conflict"
    }
  }
}

/// 合并结果
struct MergeResult {
  let source: MergeSource
  let data: SyncData
  let localData: SyncData?
  let remoteData: SyncData?
}

// MARK: - Cloudflare KV 客户端

/// Cloudflare KV HTTP API 封装
@MainActor
class CloudflareKV {
  static let shared = CloudflareKV()

  /// 配置是否已设置
  var isConfigured: Bool {
    guard let accountId = loadAccountId(),
      let namespaceId = loadNamespaceId(),
      let userId = loadUserId(),
      loadApiToken() != nil
    else {
      return false
    }
    return !accountId.isEmpty && !namespaceId.isEmpty && !userId.isEmpty
  }

  // MARK: - 配置加载（UserDefaults）

  private func loadAccountId() -> String? {
    return UserDefaults.standard.string(forKey: "openclaw.deck.cloudflare.accountId")
  }

  private func loadNamespaceId() -> String? {
    return UserDefaults.standard.string(forKey: "openclaw.deck.cloudflare.namespaceId")
  }

  private func loadUserId() -> String? {
    return UserDefaults.standard.string(forKey: "openclaw.deck.cloudflare.userId")
  }

  private func loadApiToken() -> String? {
    // API Token 存储在 Keychain 中（加密）
    return KeychainWrapper.shared.string(forKey: "openclaw.deck.cloudflare.apiToken")
  }

  // MARK: - 配置保存

  func saveConfig(accountId: String, namespaceId: String, userId: String, apiToken: String) throws {
    UserDefaults.standard.set(accountId, forKey: "openclaw.deck.cloudflare.accountId")
    UserDefaults.standard.set(namespaceId, forKey: "openclaw.deck.cloudflare.namespaceId")
    UserDefaults.standard.set(userId, forKey: "openclaw.deck.cloudflare.userId")

    // API Token 存入 Keychain
    try KeychainWrapper.shared.set(apiToken, forKey: "openclaw.deck.cloudflare.apiToken")
  }

  func clearConfig() {
    UserDefaults.standard.removeObject(forKey: "openclaw.deck.cloudflare.accountId")
    UserDefaults.standard.removeObject(forKey: "openclaw.deck.cloudflare.namespaceId")
    UserDefaults.standard.removeObject(forKey: "openclaw.deck.cloudflare.userId")
    KeychainWrapper.shared.delete(forKey: "openclaw.deck.cloudflare.apiToken")
  }

  // MARK: - 核心同步方法

  /// 智能同步：自动比较本地和云端数据，返回合并结果
  /// - 如果只有本地有数据 → 上传到云端
  /// - 如果只有云端有数据 → 下载到本地
  /// - 如果两边都有 → 比较数据，一致则自动通过，冲突时返回让用户选择
  /// - 对调用者透明，自动处理所有情况
  func syncAndGet() async throws -> MergeResult {
    guard isConfigured else {
      logger.error("未配置，跳过同步")
      throw CloudflareError.notConfigured
    }

    logger.debug("开始智能同步...")

    // 1. 同时读取本地和云端
    let localData = loadLocalData()
    let remoteData = try? await loadFromKV()

    logger.debug("本地数据：\(localData?.sessions.count ?? 0) 个 sessions")
    logger.debug("云端数据：\(remoteData?.sessions.count ?? 0) 个 sessions")

    // 2. 智能合并
    let merged = merge(local: localData, remote: remoteData)

    logger.debug("合并结果：\(merged.source.description)")

    // 3. 自动保存（如果需要）
    switch merged.source {
    case .local:
      // 本地更新，同步到云端
      try await saveToKV(merged.data)
      logger.info("本地数据已同步到云端")
    case .remote:
      // 云端更新，保存到本地
      saveLocalData(merged.data)
      logger.info("云端数据已下载到本地")
    case .same:
      // 数据一致，无需操作
      logger.info("数据一致，无需同步")
    case .conflict:
      // 数据冲突，不自动保存，由用户选择
      logger.warning("数据冲突，等待用户选择")
    }

    // 4. 返回合并结果
    logger.debug("同步完成，返回 \(merged.source)")
    return merged
  }

  /// 保存数据到 KV（用于本地修改后主动同步）
  func save(_ data: SyncData) async throws {
    guard isConfigured else {
      throw CloudflareError.notConfigured
    }

    logger.debug("保存数据到 KV：\(data.sessions.count) 个 sessions")
    try await saveToKV(data)
    saveLocalData(data)
    logger.info("已保存到本地和云端")
  }

  // MARK: - 私有方法

  /// 合并本地和云端数据
  private func merge(local: SyncData?, remote: SyncData?) -> MergeResult {
    switch (local, remote) {
    case (.some(let l), .none):
      // 只有本地有 → 用本地
      logger.debug("只有本地有数据，使用本地（\(l.sessions.count) 个 sessions）")
      return MergeResult(source: .local, data: l, localData: l, remoteData: nil)

    case (.none, .some(let r)):
      // 只有云端有 → 用云端
      logger.debug("只有云端有数据，使用云端（\(r.sessions.count) 个 sessions）")
      return MergeResult(source: .remote, data: r, localData: nil, remoteData: r)

    case (.some(let l), .some(let r)):
      // 两边都有 → 比较数据是否一致
      if l.sessions == r.sessions {
        // 数据一致 → 自动通过
        logger.info("数据一致（\(l.sessions.count) 个 sessions），自动同步")
        return MergeResult(source: .same, data: l, localData: l, remoteData: r)
      } else {
        // 数据不一致 → 需要用户选择
        logger.warning("数据冲突：本地 \(l.sessions.count) 个，云端 \(r.sessions.count) 个")
        return MergeResult(
          source: .conflict,
          data: l,  // 临时返回本地，实际由用户选择
          localData: l,
          remoteData: r
        )
      }

    case (.none, .none):
      // 两边都没有 → 返回空数据
      logger.debug("本地和云端都没有数据")
      return MergeResult(source: .same, data: .empty, localData: nil, remoteData: nil)
    }
  }

  /// 加载本地数据
  private func loadLocalData() -> SyncData? {
    let storage = UserDefaultsStorage.shared
    let sessions = storage.loadSessionOrder()

    guard !sessions.isEmpty else {
      return nil
    }

    // 使用最后更新时间（从 UserDefaults 中读取）
    // ⚠️ 如果时间戳丢失（备份恢复/数据迁移/UserDefaults 被清除），使用固定旧时间
    // 这样可以防止本地数据错误地覆盖云端数据
    // 云端数据同步回来后会更新正确的时间戳
    let lastUpdated =
      UserDefaults.standard.string(forKey: "openclaw.deck.sessionOrder.lastUpdated")
      ?? "1970-01-01T00:00:00Z"

    return SyncData(sessions: sessions, lastUpdated: lastUpdated)
  }

  /// 保存本地数据
  private func saveLocalData(_ data: SyncData) {
    let storage = UserDefaultsStorage.shared
    storage.saveSessionOrder(data.sessions)

    // 保存时间戳
    UserDefaults.standard.set(
      data.lastUpdated, forKey: "openclaw.deck.sessionOrder.lastUpdated")

    logger.debug("本地数据已保存：\(data.sessions.count) 个 sessions")
  }

  /// 从 KV 加载数据
  private func loadFromKV() async throws -> SyncData? {
    guard let accountId = loadAccountId(),
      let namespaceId = loadNamespaceId(),
      let userId = loadUserId(),
      let apiToken = loadApiToken()
    else {
      throw CloudflareError.notConfigured
    }

    let urlString =
      "https://api.cloudflare.com/client/v4/accounts/\(accountId)/storage/kv/namespaces/\(namespaceId)/values/\(userId)"
    guard let url = URL(string: urlString) else {
      throw CloudflareError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")

    logger.debug("GET 请求：\(urlString)")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw CloudflareError.invalidResponse
    }

    logger.debug("HTTP 状态码：\(httpResponse.statusCode)")

    if httpResponse.statusCode == 404 {
      // Key 不存在，返回 nil
      logger.debug("Key 不存在（404）")
      return nil
    }

    guard httpResponse.statusCode == 200 else {
      logger.error("HTTP 错误：\(httpResponse.statusCode)")
      throw CloudflareError.httpError(httpResponse.statusCode)
    }

    let decoded = try JSONDecoder().decode(SyncData.self, from: data)
    logger.info("解析成功：\(decoded.sessions.count) 个 sessions")
    return decoded
  }

  /// 保存数据到 KV
  private func saveToKV(_ data: SyncData) async throws {
    guard let accountId = loadAccountId(),
      let namespaceId = loadNamespaceId(),
      let userId = loadUserId(),
      let apiToken = loadApiToken()
    else {
      throw CloudflareError.notConfigured
    }

    let urlString =
      "https://api.cloudflare.com/client/v4/accounts/\(accountId)/storage/kv/namespaces/\(namespaceId)/values/\(userId)"
    guard let url = URL(string: urlString) else {
      throw CloudflareError.invalidURL
    }

    let jsonData = try JSONEncoder().encode(data)

    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData

    logger.debug("PUT 请求：\(urlString)")
    logger.debug("请求数据：\(String(data: jsonData, encoding: .utf8) ?? "nil")")

    let (_, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      logger.error("响应错误：不是 HTTPURLResponse")
      throw CloudflareError.invalidResponse
    }

    logger.debug("HTTP 状态码：\(httpResponse.statusCode)")

    if httpResponse.statusCode != 200 {
      logger.error("保存失败，状态码：\(httpResponse.statusCode)")
      throw CloudflareError.httpError(httpResponse.statusCode)
    }

    logger.info("保存成功")
  }
}

// MARK: - 错误类型

enum CloudflareError: LocalizedError {
  case notConfigured
  case invalidURL
  case invalidResponse
  case httpError(Int)
  case saveFailed
  case decodeError

  var errorDescription: String? {
    switch self {
    case .notConfigured:
      return "Cloudflare KV not configured. Please enter configuration in Settings."
    case .invalidURL:
      return "Invalid URL"
    case .invalidResponse:
      return "Invalid server response"
    case .httpError(let code):
      return "HTTP Error: \(code)"
    case .saveFailed:
      return "Save failed"
    case .decodeError:
      return "Data parsing failed"
    }
  }
}

// MARK: - Keychain 包装器（简化版）

/// Keychain 存储包装器
class KeychainWrapper {
  static let shared = KeychainWrapper()

  private init() {}

  /// 保存字符串到 Keychain
  func set(_ string: String, forKey key: String) throws {
    guard let data = string.data(using: .utf8) else {
      throw KeychainError.encodingFailed
    }

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecValueData as String: data,
    ]

    // 先删除旧的
    SecItemDelete(query as CFDictionary)

    // 添加新的
    let status = SecItemAdd(query as CFDictionary, nil)

    guard status == errSecSuccess else {
      throw KeychainError.saveFailed(status)
    }
  }

  /// 从 Keychain 读取字符串
  func string(forKey key: String) -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess,
      let data = result as? Data,
      let string = String(data: data, encoding: .utf8)
    else {
      return nil
    }

    return string
  }

  /// 从 Keychain 删除
  func delete(forKey key: String) {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
    ]
    SecItemDelete(query as CFDictionary)
  }
}

enum KeychainError: LocalizedError {
  case encodingFailed
  case saveFailed(OSStatus)

  var errorDescription: String? {
    switch self {
    case .encodingFailed:
      return "Data encoding failed"
    case .saveFailed(let status):
      return "Keychain save failed: \(status)"
    }
  }
}
