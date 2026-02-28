// CloudflareKVTests.swift
// OpenClaw Deck Swift
//
// Cloudflare KV 存储测试

import XCTest

@testable import openclaw_deck_swift

@MainActor
final class CloudflareKVTests: XCTestCase {

  var cloudflare: CloudflareKV!

  override func setUp() async throws {
    try await super.setUp()
    cloudflare = CloudflareKV.shared
  }

  override func tearDown() async throws {
    cloudflare = nil
    try await super.tearDown()
  }

  // MARK: - Configuration Tests

  func testIsConfigured_withoutConfiguration() {
    // 默认情况下应该未配置
    XCTAssertFalse(cloudflare.isConfigured)
  }

  func testConfigure_withValidURL() {
    let validURL =
      "https://api.cloudflare.com/client/v4/accounts/test-account/storage/kv/namespaces/test-namespace"
    let validToken = "test-api-token"

    cloudflare.configure(url: validURL, apiToken: validToken)

    XCTAssertTrue(cloudflare.isConfigured)
  }

  func testConfigure_withInvalidURL() {
    let invalidURL = "not-a-valid-url"
    let validToken = "test-api-token"

    cloudflare.configure(url: invalidURL, apiToken: validToken)

    // URL 无效时应该未配置
    XCTAssertFalse(cloudflare.isConfigured)
  }

  func testConfigure_withEmptyToken() {
    let validURL =
      "https://api.cloudflare.com/client/v4/accounts/test-account/storage/kv/namespaces/test-namespace"
    let emptyToken = ""

    cloudflare.configure(url: validURL, apiToken: emptyToken)

    // Token 为空时应该未配置
    XCTAssertFalse(cloudflare.isConfigured)
  }

  func testConfigure_clearsPreviousConfiguration() {
    // 先配置一次
    cloudflare.configure(
      url: "https://api.cloudflare.com/client/v4/accounts/acc1/storage/kv/namespaces/ns1",
      apiToken: "token1"
    )
    XCTAssertTrue(cloudflare.isConfigured)

    // 用空配置清除
    cloudflare.configure(url: "", apiToken: "")
    XCTAssertFalse(cloudflare.isConfigured)
  }

  // MARK: - URL Validation Tests

  func testValidURLFormats() {
    let validURLs = [
      "https://api.cloudflare.com/client/v4/accounts/test/storage/kv/namespaces/test",
      "https://api.cloudflare.com/client/v4/accounts/abc123/storage/kv/namespaces/xyz789",
    ]

    for url in validURLs {
      cloudflare.configure(url: url, apiToken: "test-token")
      XCTAssertTrue(cloudflare.isConfigured, "URL 应该是有效的：\(url)")

      // 清除配置
      cloudflare.configure(url: "", apiToken: "")
    }
  }

  func testInvalidURLFormats() {
    let invalidURLs = [
      "",
      "not-a-url",
      "http://example.com",  // 必须是 https
      "ftp://example.com",
      "cloudflare.com",
    ]

    for url in invalidURLs {
      cloudflare.configure(url: url, apiToken: "test-token")
      XCTAssertFalse(cloudflare.isConfigured, "URL 应该是无效的：\(url)")
    }
  }

  // MARK: - Token Validation Tests

  func testValidTokenFormats() {
    let validTokens = [
      "test-token",
      "ABC123xyz789",
      String(repeating: "a", count: 32),  // 长 token
    ]

    for token in validTokens {
      cloudflare.configure(
        url: "https://api.cloudflare.com/client/v4/accounts/test/storage/kv/namespaces/test",
        apiToken: token
      )
      XCTAssertTrue(cloudflare.isConfigured, "Token 应该是有效的：\(token)")

      // 清除配置
      cloudflare.configure(url: "", apiToken: "")
    }
  }

  func testInvalidTokenFormats() {
    let invalidTokens = [
      "",
      " ",  // 只有空格
    ]

    for token in invalidTokens {
      cloudflare.configure(
        url: "https://api.cloudflare.com/client/v4/accounts/test/storage/kv/namespaces/test",
        apiToken: token
      )
      XCTAssertFalse(cloudflare.isConfigured, "Token 应该是无效的：\(token)")
    }
  }

  // MARK: - SyncData Tests

  func testSyncData_initialization() {
    let sessions = ["session1", "session2", "session3"]
    let lastUpdated = "2024-01-01T00:00:00Z"

    let syncData = SyncData(sessions: sessions, lastUpdated: lastUpdated)

    XCTAssertEqual(syncData.sessions, sessions)
    XCTAssertEqual(syncData.lastUpdated, lastUpdated)
  }

  func testSyncData_encoding() throws {
    let sessions = ["session1", "session2", "session3"]
    let lastUpdated = "2024-01-01T00:00:00Z"

    let syncData = SyncData(sessions: sessions, lastUpdated: lastUpdated)

    // 编码为 JSON
    let encoder = JSONEncoder()
    let jsonData = try encoder.encode(syncData)

    // 解码验证
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(SyncData.self, from: jsonData)

    XCTAssertEqual(decoded.sessions, sessions)
    XCTAssertEqual(decoded.lastUpdated, lastUpdated)
  }

  func testSyncData_emptySessions() throws {
    let syncData = SyncData(sessions: [], lastUpdated: "2024-01-01T00:00:00Z")

    let encoder = JSONEncoder()
    let jsonData = try encoder.encode(syncData)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(SyncData.self, from: jsonData)

    XCTAssertEqual(decoded.sessions.count, 0)
    XCTAssertEqual(decoded.lastUpdated, "2024-01-01T00:00:00Z")
  }

  // MARK: - MergeResult Tests

  func testMergeResult_sourceCases() {
    // 测试所有 MergeSource 类型
    let sources: [MergeSource] = [.local, .remote, .merged, .conflict]

    for source in sources {
      switch source {
      case .local:
        XCTAssertEqual(source.description, "local")
      case .remote:
        XCTAssertEqual(source.description, "remote")
      case .merged:
        XCTAssertEqual(source.description, "merged")
      case .conflict:
        XCTAssertEqual(source.description, "conflict")
      }
    }
  }

  func testMergeResult_creation() {
    let localData = SyncData(sessions: ["local1"], lastUpdated: "2024-01-01T00:00:00Z")
    let remoteData = SyncData(sessions: ["remote1"], lastUpdated: "2024-01-01T00:00:00Z")

    let result = MergeResult(
      data: localData,
      source: .local,
      localData: localData,
      remoteData: remoteData
    )

    XCTAssertEqual(result.data.sessions, ["local1"])
    XCTAssertEqual(result.source, .local)
    XCTAssertEqual(result.localData?.sessions, ["local1"])
    XCTAssertEqual(result.remoteData?.sessions, ["remote1"])
  }

  // MARK: - Singleton Tests

  func testSingletonInstance() {
    let instance1 = CloudflareKV.shared
    let instance2 = CloudflareKV.shared

    XCTAssertTrue(instance1 === instance2)
  }

  func testSingletonConfiguration() {
    // 配置单例
    cloudflare.configure(
      url: "https://api.cloudflare.com/client/v4/accounts/test/storage/kv/namespaces/test",
      apiToken: "test-token"
    )

    // 获取新的引用
    let anotherInstance = CloudflareKV.shared

    // 验证配置保持
    XCTAssertTrue(anotherInstance.isConfigured)
  }

  // MARK: - Error Handling Tests

  func testConfigure_withMalformedURL() {
    let malformedURLs = [
      "://missing-scheme.com",
      "https://",
      "https://api.cloudflare.com",  // 缺少路径
    ]

    for url in malformedURLs {
      cloudflare.configure(url: url, apiToken: "test-token")
      XCTAssertFalse(cloudflare.isConfigured)
    }
  }

  // MARK: - Thread Safety Tests

  func testConcurrentConfiguration() {
    let expectation = XCTestExpectation(description: "Concurrent configuration")

    // 并发配置多次
    for i in 0..<10 {
      Task {
        cloudflare.configure(
          url:
            "https://api.cloudflare.com/client/v4/accounts/test\(i)/storage/kv/namespaces/test\(i)",
          apiToken: "token\(i)"
        )
        if i == 9 {
          expectation.fulfill()
        }
      }
    }

    wait(for: [expectation], timeout: 5.0)

    // 验证最后一次配置生效
    XCTAssertTrue(cloudflare.isConfigured)
  }

  // MARK: - Integration Tests

  func testFullConfigurationWorkflow() {
    // 1. 初始状态：未配置
    XCTAssertFalse(cloudflare.isConfigured)

    // 2. 配置
    cloudflare.configure(
      url: "https://api.cloudflare.com/client/v4/accounts/test/storage/kv/namespaces/test",
      apiToken: "test-token"
    )

    // 3. 验证已配置
    XCTAssertTrue(cloudflare.isConfigured)

    // 4. 清除配置
    cloudflare.configure(url: "", apiToken: "")

    // 5. 验证已清除
    XCTAssertFalse(cloudflare.isConfigured)
  }

  func testConfigurationPersistence() {
    // 配置
    cloudflare.configure(
      url: "https://api.cloudflare.com/client/v4/accounts/test/storage/kv/namespaces/test",
      apiToken: "test-token"
    )

    // 立即验证
    XCTAssertTrue(cloudflare.isConfigured)

    // 等待一小段时间
    Task {
      try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 秒

      // 验证配置仍然保持
      XCTAssertTrue(cloudflare.isConfigured)
    }
  }
}
