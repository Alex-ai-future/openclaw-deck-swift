# OpenClaw Deck Swift - 技术架构

**版本：** 1.5  
**最后更新：** 2026-02-28  
**目标读者：** 开发者、贡献者

---

## 目录

1. [架构概览](#architecture)
2. [技术选型](#tech-stack)
3. [代码结构](#code-structure)
4. [核心组件](#core-components)
5. [会话状态轮询](#session-polling) NEW
6. [开发指南](#development-guide)
7. [测试标准](#testing)

---

## 架构概览 {#architecture}

### 整体架构

```
┌─────────────────────────────────────────────────────────┐
│                         SwiftUI Views                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │
│  │ ContentView │  │ DeckView    │  │ SessionColumn│      │
│  │ (主容器)     │  │ (多列布局)   │  │ View (单列)  │      │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘      │
│         │                │                │              │
│         ▼                ▼                ▼              │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    ViewModels                            ││
│  │              DeckViewModel (统一管理)                     ││
│  │  • 管理 Session Key 列表                                 ││
│  │  • 创建/删除 Session                                     ││
│  │  • 发送消息/处理事件                                     ││
│  │  • GlobalInputState (全局输入状态)                       ││
│  └─────────────────────────┬───────────────────────────────┘│
└────────────────────────────┼────────────────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────┐
│                       Services                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 GatewayClient                         │   │
│  │  • WebSocket 连接管理                                  │   │
│  │  • 挑战握手认证（nonce 验证）                           │   │
│  │  • 请求/响应关联                                        │   │
│  │  • 事件流订阅                                          │   │
│  └─────────────────────────┬───────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 CloudflareKV                          │   │
│  │  • Session 列表同步（多设备）                           │   │
│  │  • 自动冲突解决（最新修改优先）                         │   │
│  │  • 支持手动同步                                       │   │
│  └─────────────────────────┬───────────────────────────┘   │
└────────────────────────────┼────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │ OpenClaw Gateway │
                    │ Main Agent       │
                    │ (消息/状态存储)   │
                    └────────────────┘
```

### 设计原则

1. **单一 Agent** - 使用固定的 Main Agent，不涉及多 Agent 管理
2. **无本地持久化** - 消息、状态等数据全部存储在 Gateway
3. **Session 即会话** - 每个 Session 代表一个独立的聊天会话
4. **全局输入状态** - GlobalInputState 统一管理所有输入

---

## 技术选型 {#tech-stack}

### 为什么用 SwiftUI？

**优势：**
- ✅ 声明式 UI，代码简洁
- ✅ 自动状态管理（@Observable）
- ✅ 跨平台（macOS + iPadOS）
- ✅ 原生性能

**最低版本：**
- macOS 15.0+
- iPadOS 18.0+

### 为什么用 WebSocket？

**需求：**
- ✅ 实时双向通信
- ✅ 低延迟（流式响应）
- ✅ 持久连接

**实现：**
- `URLSessionWebSocketTask`（原生）
- 自定义协议层（GatewayClient）

### 为什么用 MVVM？

**优势：**
- ✅ 清晰的职责分离
- ✅ 易于测试
- ✅ 状态管理简单

**结构：**
```
View (展示) → ViewModel (状态/逻辑) → Service (网络/存储)
```

---

## 代码结构 {#code-structure}

### 目录结构

```
openclaw-deck-swift/
├── openclaw-deck-swift/          # 主应用
│   ├── Models/                   # 数据模型
│   │   ├── AppConfig.swift       # 应用配置
│   │   ├── ChatMessage.swift     # 消息模型
│   │   ├── GatewayFrame.swift    # 通信协议
│   │   ├── SessionConfig.swift   # Session 配置
│   │   └── SessionState.swift    # Session 状态
│   ├── ViewModels/               # 视图模型
│   │   └── DeckViewModel.swift   # 主 ViewModel
│   ├── Views/                    # 视图组件
│   │   ├── ContentView.swift     # 主容器
│   │   ├── DeckView.swift        # 多列布局
│   │   ├── SessionColumnView.swift # 单列聊天
│   │   ├── GlobalInputView.swift # 全局输入框
│   │   └── SettingsView.swift    # 设置页面
│   ├── Services/                 # 服务层
│   │   ├── GatewayClient.swift   # WebSocket 客户端
│   │   ├── CloudflareKV.swift    # Cloudflare KV 同步
│   │   └── SpeechRecognizer.swift # 语音识别
│   └── Utils/                    # 工具类
│       └── UserDefaultsStorage.swift
├── openclaw-deck-swiftTests/     # 单元测试 (93 个测试)
├── script/                       # 构建脚本
└── docs/                         # 文档
```

### 关键文件说明

| 文件 | 行数 | 职责 |
|------|------|------|
| `DeckViewModel.swift` | ~750 | 核心业务逻辑，管理所有 Session |
| `GatewayClient.swift` | ~850 | WebSocket 连接、认证、事件处理 |
| `CloudflareKV.swift` | ~250 | Cloudflare KV 同步、冲突解决 |
| `SessionColumnView.swift` | ~1000 | 单列聊天 UI，包含快速操作按钮 |
| `GlobalInputView.swift` | ~90 | 全局输入框，统一管理输入状态 |

---

## 核心组件 {#core-components}

### GlobalInputState

**设计决策：**
- 全局唯一实例，管理所有输入状态
- 避免每个 Session 独立的输入框
- 简化架构，减少状态同步
- 支持 `/new` 命令快速创建 Session

**代码结构：**
```swift
@Observable
class GlobalInputState {
  var inputText: String = ""
  var textHeight: CGFloat = 36
  var selectedSessionId: String?
  
  func sendMessage(to session: SessionState, viewModel: DeckViewModel) async {
    // 发送逻辑
  }
}
```

### CloudflareKV

**同步机制：**
- 使用 Cloudflare KV 存储 Session 列表和顺序
- 自动同步：每次 Session 变化时触发
- 手动同步：用户点击 "Sync Now" 按钮
- 冲突解决：基于时间戳，最新修改优先

**数据格式：**
```swift
struct SyncData {
  let sessions: [String]  // Session ID 列表
  let lastUpdated: String  // ISO8601 时间戳
}
```

### SessionColumnView

**快速操作按钮组设计：**

```swift
// 只在选中时显示
if isSelected {
  HStack(spacing: 8) {
    Button { sendOKMessage() }
    label: { Text("OK") }
    
    Button { sendInputMessage() }
    label: { Image(systemName: "arrow.up.circle.fill") }
  }
  .transition(.opacity.combined(with: .scale))
}
```

**设计决策：**
- OK 按钮 + 发送按钮只在选中 Session 显示
- 避免多 Session 模式下按钮重复
- 蓝色底条 = 选中状态视觉反馈

### GatewayClient

**认证流程：**
```
1. WebSocket 连接
2. 接收 connect.challenge (nonce)
3. 使用 Ed25519 签名
4. 发送 connect 请求
5. 接收 deviceToken（持久化）
```

**请求/响应关联：**
```swift
struct PendingRequest {
  let continuation: CheckedContinuation<GatewayResponse, Error>
  let timeout: Task<Void, Never>
}

private var pendingRequests: [String: PendingRequest] = [:]
```

---

### 会话状态轮询机制 NEW

**设计决策：**

**问题：** 之前依赖生命周期事件（`lifecycle.start` / `lifecycle.end`）更新会话状态，存在以下问题：
- ❌ 错过事件会导致状态不准确
- ❌ 无法获取历史会话状态
- ❌ 断线重连后状态丢失

**解决方案：** 主动轮询 + 事件补充

**实现：**
```swift
// DeckViewModel.swift
private let sessionPollingInterval: TimeInterval = 30  // 30 秒轮询一次

private func startSessionPolling() {
  sessionPollingTimer = Timer.scheduledTimer(
    withTimeInterval: sessionPollingInterval,
    repeats: true
  ) { [weak self] _ in
    Task { @MainActor in
      await self?.pollSessionStatus()
    }
  }
}

private func pollSessionStatus() async {
  let statuses = try await client.fetchSessions(activeMinutes: 60)
  updateSessionStates(from: statuses)
}
```

**工作流程：**
```
1. Gateway 连接成功
   ↓
2. 启动轮询定时器（30 秒）
   ↓
3. 调用 GatewayClient.fetchSessions()
   ↓
4. Gateway 返回活跃会话列表
   ↓
5. 更新本地 Session 状态
   ↓
6. UI 自动刷新（@Observable）
```

**优势：**
- ✅ 不依赖事件，主动获取权威状态
- ✅ 断线重连后立即同步
- ✅ 可以查询历史会话
- ✅ 事件作为实时补充（双重保障）

**数据模型：**
```swift
struct GatewaySessionStatus {
  let key: String
  let sessionId: String
  let isProcessing: Bool  // 推断是否正在处理
  let updatedAt: Date
  let totalTokens: Int?
  // ...
}
```

---

---

## 开发指南 {#development-guide}

### 添加新功能

**步骤：**

1. **确定位置**
   - UI → Views/
   - 逻辑 → ViewModels/
   - 网络 → Services/

2. **编写代码**
   - 遵循现有架构
   - 使用 @Observable 管理状态

3. **添加测试**
   - 单元测试 → openclaw-deck-swiftTests/
   - 确保测试通过

4. **格式化**
   ```bash
   swift-format format -i 文件.swift
   ```

### 调试技巧

**查看日志：**
```bash
# 应用日志
log show --predicate 'process == "openclaw-deck-swift"' --last 1h

# WebSocket 调试
# 在 GatewayClient.swift 中启用 logger
```

**检查 Gateway 连接：**
```bash
# 查看 Gateway 进程
ps aux | grep openclaw

# 查看端口
lsof -i :18789
```

### 常见问题

**Q: 如何添加新的 UI 组件？**

A: 
1. 在 Views/ 创建新文件
2. 使用 @Bindable 接收状态
3. 在父组件中引入

**Q: 如何修改通信协议？**

A:
1. 修改 GatewayFrame.swift
2. 更新 GatewayClient.swift
3. 确保与 Gateway 兼容

**Q: 如何添加新的 Session 操作？**

A:
1. 在 DeckViewModel 添加方法
2. 在 SessionColumnView 添加 UI
3. 添加单元测试

---

## 测试标准 {#testing}

### 测试框架

- **框架：** XCTest
- **运行：** `bash script/run_unit_tests.sh`
- **目标：** 93 个测试，100% 通过

### 测试覆盖

| 模块 | 测试文件 | 测试数 | 通过率 |
|------|---------|--------|--------|
| Models | AppConfig/ChatMessage/Session* | 35 | 100% |
| Services | GatewayClient/GatewayFrame | 24 | 100% |
| ViewModels | DeckViewModel | 21 | 100% |
| Utils | UserDefaultsStorage | 13 | 100% |

### 编写测试

**标准：**
```swift
@MainActor
final class MyTests: XCTestCase {
  var mockStorage: MockUserDefaultsStorage!
  
  override func setUp() async throws {
    mockStorage = MockUserDefaultsStorage()
  }
  
  func testSomething() {
    // 测试逻辑
    XCTAssertEqual(...)
  }
}
```

**原则：**
- ✅ 使用 Mock 隔离依赖
- ✅ 每个测试独立
- ✅ 测试名称描述行为

### 代码质量

**格式化：**
```bash
# 格式化单个文件
swift-format format -i 文件.swift

# 格式化所有文件
find . -name "*.swift" -exec swift-format format -i {} \;
```

**提交规范：**
```
[feature] 添加新功能
[fix] 修复 bug
[ui] UI 改进
[refactor] 重构
[docs] 文档更新
[style] 代码格式化
```

---

## 附录

### A. 相关资源

- [SwiftUI 官方文档](https://developer.apple.com/documentation/swiftui)
- [OpenClaw 架构](https://docs.openclaw.ai/concepts/architecture)
- [WebSocket 协议](https://datatracker.ietf.org/doc/html/rfc6455)

### B. 性能指标

| 指标 | 目标 | 实际 |
|------|------|------|
| 启动时间 | < 2s | ~1s |
| 消息延迟 | < 500ms | ~200ms |
| 测试运行 | < 30s | ~16s |
| 测试覆盖 | > 70% | ~85% |

---

**贡献代码：** [GitHub](https://github.com/Alex-ai-future/openclaw-deck-swift)

---

## 📚 相关文档

- [用户指南](USER_GUIDE.html) - 如何使用
- [使用样例](USAGE_EXAMPLES.html) - 实际场景示例
- [隐私政策](PRIVACY.html) - 数据隐私说明
