# 依赖注入 (DI) 架构

## 概述

本项目使用依赖注入容器 (DIContainer) 来管理服务依赖，使得测试和 Mock 更加容易。

## 架构

```
┌─────────────────┐
│   App Entry     │
│  (ContentView)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  DIContainer    │
│  (依赖容器)      │
└────────┬────────┘
         │
    ┌────┴────┬────────────┬────────────────┐
    ▼         ▼            ▼                ▼
┌────────┐ ┌──────────┐ ┌────────────┐ ┌──────────────┐
│Storage │ │Gateway   │ │ Cloudflare │ │GlobalInput   │
│        │ │Client    │ │ KV         │ │State         │
└────────┘ └──────────┘ └────────────┘ └──────────────┘
```

## 文件结构

```
openclaw-deck-swift/
├── DI/
│   ├── DIContainer.swift      # 依赖注入容器
│   └── README.md              # 本文档
├── Protocols/
│   ├── GatewayClientProtocol.swift   # Gateway 客户端协议
│   └── CloudflareKVProtocol.swift    # Cloudflare KV 协议
├── Mocks/
│   ├── MockGatewayClient.swift       # Mock Gateway 客户端
│   ├── MockCloudflareKV.swift        # Mock Cloudflare KV
│   └── MockUserDefaultsStorage.swift # Mock UserDefaults 存储
└── ViewModels/
    └── DeckViewModel.swift    # 使用 DI 的 ViewModel
```

## 使用方式

### 生产环境（默认）

```swift
// DeckViewModel 自动使用 DIContainer.shared
let viewModel = DeckViewModel()
```

### 测试环境

```swift
// 创建 Mock 依赖
let mockStorage = MockUserDefaultsStorage()
let mockGateway = MockGatewayClient()
let mockCloudflare = MockCloudflareKV()

// 创建测试用 DI 容器
let testDIContainer = DIContainer(
    storage: mockStorage,
    gatewayClientFactory: { _, _ in mockGateway },
    cloudflareKV: mockCloudflare,
    globalInputStateFactory: { GlobalInputState() }
)

// 使用测试容器创建 ViewModel
let viewModel = DeckViewModel(diContainer: testDIContainer)
```

## 优势

1. **可测试性** - 可以轻松替换为 Mock 实现
2. **解耦** - ViewModel 不直接依赖具体实现
3. **灵活性** - 可以在不同环境使用不同配置
4. **清晰** - 依赖关系一目了然

## UI 测试配置

UI 测试中，通过 `launchArguments` 标记测试模式，应用检测到后自动使用 Mock 依赖：

```swift
app.launchArguments = ["--ui-testing"]
app.launch()
```

详见：`openclaw-deck-swiftUITests/DIContainer+UITest.swift`

## 迁移说明

### 已完成
- ✅ DIContainer 创建
- ✅ GatewayClientProtocol 协议
- ✅ CloudflareKVProtocol 协议
- ✅ Mock 实现 (Gateway, Cloudflare, Storage)
- ✅ DeckViewModel 使用 DI
- ✅ GatewayClient 实现协议
- ✅ CloudflareKV 实现协议

### 待完成
- ⏳ 在 App 入口配置测试模式检测
- ⏳ UI 测试使用 DIContainer+UITest
- ⏳ 验证编译通过
- ⏳ 运行 UI 测试验证

## 注意事项

1. **Swift 6 隔离** - DIContainer 使用 `@MainActor` 确保线程安全
2. **协议一致性** - 所有 Mock 类必须实现协议的全部方法
3. **测试数据** - UI 测试中需要预置测试数据（Session 等）
