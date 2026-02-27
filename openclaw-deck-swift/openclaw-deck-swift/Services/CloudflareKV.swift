// CloudflareKV.swift
// OpenClaw Deck Swift
//
// Cloudflare KV 同步服务 - 实现多设备 Session 同步

import Foundation

// MARK: - 同步数据结构

/// Cloudflare KV 中存储的同步数据
struct SyncData: Codable {
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
enum MergeSource {
  case local  // 本地数据更新
  case remote  // 云端数据更新
  case same  // 数据一致
}

/// 合并结果
struct MergeResult {
  let source: MergeSource
  let data: SyncData
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

  /// 智能同步：自动比较本地和云端数据，返回最新结果
  /// - 如果只有本地有数据 → 上传到云端
  /// - 如果只有云端有数据 → 下载到本地
  /// - 如果两边都有 → 比较时间戳，保留新的，并同步到另一边
  /// - 对调用者透明，自动处理所有情况
  func syncAndGet() async throws -> SyncData {
    guard isConfigured else {
      throw CloudflareError.notConfigured
    }

    // 1. 同时读取本地和云端
    let localData = loadLocalData()
    let remoteData = try? await loadFromKV()

    // 2. 智能合并
    let merged = merge(local: localData, remote: remoteData)

    // 3. 自动保存（如果需要）
    switch merged.source {
    case .local:
      // 本地更新，同步到云端
      try await saveToKV(merged.data)
      print("[CloudflareKV] Synced local data to cloud")
    case .remote:
      // 云端更新，保存到本地
      saveLocalData(merged.data)
      print("[CloudflareKV] Synced cloud data to local")
    case .same:
      // 数据一致，无需操作
      break
    }

    // 4. 返回最新数据
    return merged.data
  }

  /// 保存数据到 KV（用于本地修改后主动同步）
  func save(_ data: SyncData) async throws {
    guard isConfigured else {
      throw CloudflareError.notConfigured
    }

    try await saveToKV(data)
    saveLocalData(data)
    print("[CloudflareKV] Saved data to both local and cloud")
  }

  // MARK: - 私有方法

  /// 合并本地和云端数据
  private func merge(local: SyncData?, remote: SyncData?) -> MergeResult {
    switch (local, remote) {
    case (.some(let l), .none):
      // 只有本地有 → 用本地
      return MergeResult(source: .local, data: l)

    case (.none, .some(let r)):
      // 只有云端有 → 用云端
      return MergeResult(source: .remote, data: r)

    case (.some(let l), .some(let r)):
      // 两边都有 → 比较时间戳
      if l.lastUpdated > r.lastUpdated {
        return MergeResult(source: .local, data: l)
      } else if r.lastUpdated > l.lastUpdated {
        return MergeResult(source: .remote, data: r)
      } else {
        // 时间戳相同 → 数据一致
        return MergeResult(source: .same, data: l)
      }

    case (.none, .none):
      // 两边都没有 → 返回空数据
      return MergeResult(source: .same, data: .empty)
    }
  }

  /// 加载本地数据
  private func loadLocalData() -> SyncData? {
    let storage = UserDefaultsStorage.shared
    let sessions = storage.loadSessionOrder()

    guard !sessions.isEmpty else {
      return nil
    }

    // 使用最后更新时间（从 UserDefaults 中读取或生成）
    let lastUpdated =
      UserDefaults.standard.string(forKey: "openclaw.deck.sessionOrder.lastUpdated")
      ?? ISO8601DateFormatter().string(from: Date())

    return SyncData(sessions: sessions, lastUpdated: lastUpdated)
  }

  /// 保存本地数据
  private func saveLocalData(_ data: SyncData) {
    let storage = UserDefaultsStorage.shared
    storage.saveSessionOrder(data.sessions)

    // 保存时间戳
    UserDefaults.standard.set(
      data.lastUpdated, forKey: "openclaw.deck.sessionOrder.lastUpdated")
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

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw CloudflareError.invalidResponse
    }

    if httpResponse.statusCode == 404 {
      // Key 不存在，返回 nil
      return nil
    }

    guard httpResponse.statusCode == 200 else {
      throw CloudflareError.httpError(httpResponse.statusCode)
    }

    return try JSONDecoder().decode(SyncData.self, from: data)
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

    let (_, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
      httpResponse.statusCode == 200
    else {
      throw CloudflareError.saveFailed
    }
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
      return "Cloudflare KV 未配置，请先在设置中填写配置信息"
    case .invalidURL:
      return "无效的 URL"
    case .invalidResponse:
      return "无效的服务器响应"
    case .httpError(let code):
      return "HTTP 错误：\(code)"
    case .saveFailed:
      return "保存失败"
    case .decodeError:
      return "数据解析失败"
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
      return "数据编码失败"
    case .saveFailed(let status):
      return "Keychain 保存失败：\(status)"
    }
  }
}
