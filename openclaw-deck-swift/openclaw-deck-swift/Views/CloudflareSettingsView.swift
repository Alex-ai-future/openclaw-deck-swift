// CloudflareSettingsView.swift
// OpenClaw Deck Swift
//
// Cloudflare KV 配置界面

import SwiftUI

struct CloudflareSettingsView: View {
  @State private var accountId: String = ""
  @State private var namespaceId: String = ""
  @State private var userId: String = ""
  @State private var apiToken: String = ""

  @State private var isConfigured: Bool = false
  @State private var showingTestAlert = false
  @State private var testResult: String?
  @State private var isTesting = false

  var onSave: (() -> Void)?
  var onClose: (() -> Void)?

  var body: some View {
    NavigationStack {
      Form {
        // 说明
        Section {
          VStack(alignment: .leading, spacing: 8) {
            Text("Cloudflare KV 同步")
              .font(.headline)

            Text("使用 Cloudflare KV 实现多设备 Session 同步")
              .font(.subheadline)
              .foregroundColor(.secondary)

            Link("查看配置指南", destination: URL(string: "https://dash.cloudflare.com")!)
              .font(.caption)
          }
          .padding(.vertical, 4)
        } footer: {
          Text("免费额度：10 万次读/天，1000 次写/天，1GB 存储")
        }

        // 配置输入
        Section {
          TextField("User ID（自定义，如邮箱）", text: $userId)

          TextField("Account ID", text: $accountId)

          TextField("Namespace ID", text: $namespaceId)

          SecureField("API Token", text: $apiToken)
        } header: {
          Text("Cloudflare 配置")
        } footer: {
          Text("API Token 将加密存储在 Keychain 中")
        }

        // 状态
        Section {
          HStack {
            Circle()
              .fill(isConfigured ? Color.green : Color.orange)
              .frame(width: 10, height: 10)

            Text(isConfigured ? "已配置" : "未配置")
              .foregroundColor(.primary)
              .fontWeight(.medium)

            Spacer()
          }
        } header: {
          Text("状态")
        }

        // 操作
        Section {
          Button {
            Task {
              await testConnection()
            }
          } label: {
            HStack {
              Image(systemName: "antenna.radiowaves.left.and.right")
              Text("测试连接")
            }
          }
          .disabled(isTesting || !isFormValid)

          if isConfigured {
            Button(role: .destructive) {
              clearConfig()
            } label: {
              HStack {
                Image(systemName: "trash.fill")
                Text("清除配置")
              }
            }
          }
        } header: {
          Text("操作")
        } footer: {
          if isTesting {
            Text("正在测试连接...")
              .foregroundColor(.secondary)
          } else if let result = testResult {
            Text(result)
              .foregroundColor(testResult?.contains("成功") ?? false ? .green : .red)
          }
        }
      }
      .navigationTitle("Cloudflare 同步")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("取消") {
            onClose?()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("保存") {
            saveConfig()
            onSave?()
            onClose?()
          }
          .fontWeight(.semibold)
          .keyboardShortcut(.defaultAction)
          .disabled(!isFormValid)
        }
      }
      .onAppear {
        loadConfig()
      }
    }
    .formStyle(.grouped)
  }

  // MARK: - 私有方法

  private var isFormValid: Bool {
    !accountId.trimmingCharacters(in: .whitespaces).isEmpty
      && !namespaceId.trimmingCharacters(in: .whitespaces).isEmpty
      && !userId.trimmingCharacters(in: .whitespaces).isEmpty
      && !apiToken.trimmingCharacters(in: .whitespaces).isEmpty
  }

  private func loadConfig() {
    accountId =
      UserDefaults.standard.string(
        forKey: "openclaw.deck.cloudflare.accountId") ?? ""
    namespaceId =
      UserDefaults.standard.string(
        forKey: "openclaw.deck.cloudflare.namespaceId") ?? ""
    userId = UserDefaults.standard.string(forKey: "openclaw.deck.cloudflare.userId") ?? ""
    apiToken = KeychainWrapper.shared.string(forKey: "openclaw.deck.cloudflare.apiToken") ?? ""

    isConfigured = CloudflareKV.shared.isConfigured
  }

  private func saveConfig() {
    do {
      try CloudflareKV.shared.saveConfig(
        accountId: accountId.trimmingCharacters(in: .whitespaces),
        namespaceId: namespaceId.trimmingCharacters(in: .whitespaces),
        userId: userId.trimmingCharacters(in: .whitespaces),
        apiToken: apiToken.trimmingCharacters(in: .whitespaces))
      isConfigured = true
      testResult = nil
    } catch {
      testResult = "保存失败：\(error.localizedDescription)"
    }
  }

  private func clearConfig() {
    CloudflareKV.shared.clearConfig()
    accountId = ""
    namespaceId = ""
    userId = ""
    apiToken = ""
    isConfigured = false
    testResult = "配置已清除"
  }

  private func testConnection() async {
    guard isFormValid else {
      testResult = "请先填写完整的配置信息"
      return
    }

    isTesting = true
    testResult = nil

    // 先临时保存配置
    do {
      try CloudflareKV.shared.saveConfig(
        accountId: accountId.trimmingCharacters(in: .whitespaces),
        namespaceId: namespaceId.trimmingCharacters(in: .whitespaces),
        userId: userId.trimmingCharacters(in: .whitespaces),
        apiToken: apiToken.trimmingCharacters(in: .whitespaces))
    } catch {
      testResult = "保存配置失败：\(error.localizedDescription)"
      isTesting = false
      return
    }

    // 测试连接
    do {
      _ = try await CloudflareKV.shared.syncAndGet()
      testResult = "✓ 连接成功，同步完成"
    } catch {
      testResult = "✗ 连接失败：\(error.localizedDescription)"
    }

    isTesting = false
  }
}

#Preview {
  CloudflareSettingsView()
}
