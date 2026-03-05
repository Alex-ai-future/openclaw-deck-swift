# AGENTS.md - 项目工作规则

**项目：** OpenClaw Deck Swift  
**位置：** `~/Projects/openclaw-deck-swift/`  
**使用说明书：** [docs/USER_GUIDE.md](docs/USER_GUIDE.md)

---

## 📚 项目文档

### 文档分工原则

**核心文档，明确分工，避免重复：**

| 文档 | 目标读者 | 内容重点 | 篇幅 | 写作原则 |
|------|---------|---------|------|---------|
| **README.md** | 访问者 | 项目简介 + 快速开始 + 文档索引 | ≤100 行 | 极简，只引用不展开 |
| **USER_GUIDE.md** | 用户 | 怎么使用 + 故障排除 | 按任务组织 | **50% 篇幅用于故障排除** |
| **introduction.md** | 开发者 | 技术架构 + 设计决策 + 开发指南 | ≤500 行 | 纯技术，不写功能说明 |

**USER_GUIDE.md 写作标准：**
- ✅ 按"我要做 X"组织，不是按"功能 Y"组织
- ✅ **故障排除占 50% 篇幅**（连接问题、发送失败、常见错误）
- ✅ 每个问题包含：症状、检查步骤、解决方法
- ❌ 不写技术实现细节
- ❌ 不写设计原理

**introduction.md 写作标准：**
- ✅ 架构设计和技术选型
- ✅ 解释"为什么这样设计"
- ✅ 开发指南和测试标准
- ❌ 不写功能说明（用户指南里有）
- ❌ 不写 API 细节（代码注释里有）

**README.md 写作标准：**
- ✅ 一句话说明项目
- ✅ 3 步快速开始
- ✅ 文档链接索引
- ❌ 不写功能列表
- ❌ 不写技术细节

**核心原则：**
1. **用户文档 = 故障排除手册** - 用户遇到问题时能快速找到答案
2. **技术文档 = 架构指南** - 新开发者能快速理解架构
3. **README = 门面** - 5 秒内理解项目是做什么的

---

## 🛑 核心规则：修改前必须确认

**在任何修改操作之前，必须遵循以下流程：**

```
1. 分析需求 → 2. 制定计划 → 3. 向用户确认 → 4. 获得批准 → 5. 执行修改
```

### 具体要求：

1. **不要直接修改文件** - 即使是很小的改动，也要先告知用户
2. **提供完整的修改计划** - 列出所有要修改的文件和内容
3. **等待用户批准** - 用户明确说"可以"后才能执行
4. **修改后汇报** - 完成后告知用户并说明验证方法
5. **禁止直接修改代码** ⚠️ - 任何代码修改前必须先提供修改计划

---

## 🤖 子代理使用规则

**核心原则：耗时操作（>30 秒）必须通过子代理执行**

### 必须使用子代理的操作：

| 操作类型 | 命令示例 | 原因 |
|---------|---------|------|
| **编译项目** | `xcodebuild`, `bash script/build_*.sh` | 耗时 3-15 分钟 |
| **运行测试** | `bash script/run_*_tests.sh` | 耗时 2-10 分钟 |
| **代码格式化** | `swift-format format --in-place` | 可能修改多个文件 |
| **其他耗时操作** | 预计超过 30 秒的命令 | 避免阻塞主会话 |

### 执行流程：

```
用户请求 → 创建子代理 (sessions_spawn) → 子代理执行 → 完成后自动通知
```

### 好处：

- ✅ **不阻塞主会话** - 编译期间可以继续聊天
- ✅ **隔离操作** - 失败不影响主会话状态
- ✅ **清晰分工** - 主代理负责沟通，子代理负责执行

---

## 🧠 经验规则：Swift 开发最佳实践

### SwiftData 规范

**模型定义：**
```swift
@Model
class Message {
    @Attribute(.unique) var id: String
    var content: String
    var timestamp: Date
    var session: Session?  // 使用可选类型表示关系
}
```

**查询最佳实践：**
```swift
// ✅ 使用 FetchDescriptor 过滤和排序
let descriptor = FetchDescriptor<Message>(
    predicate: #Predicate { $0.session == selectedSession },
    sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
)
let messages = try modelContext.fetch(descriptor)

// ❌ 避免：先 fetch 全部再过滤
```

**数据更新：**
```swift
// ✅ 批量操作使用 perform 包裹
modelContext.perform {
    for message in oldMessages {
        modelContext.delete(message)
    }
    try? modelContext.save()
}

// ✅ 单个对象直接修改
message.content = "new content"
try? modelContext.save()
```

**常见陷阱：**
- ⚠️ 不要在主线程执行大量数据导入
- ⚠️ 避免在 View body 中直接 fetch（使用 Task 或 ObservableObject）
- ⚠️ 删除对象后必须 save，否则不会持久化

---

### 并发编程规范

**async/await 使用：**
```swift
// ✅ 使用 async let 并发执行独立任务
async let sessions = gateway.listSessions()
async let config = gateway.getConfig()
let (sessionsResult, configResult) = try await (sessions, config)

// ✅ 使用 Task Group 处理动态数量的任务
try await withTaskGroup(of: Void.self) { group in
    for session in sessions {
        group.addTask {
            await self.process(session)
        }
    }
}

// ❌ 避免：顺序执行独立任务
let sessions = try await gateway.listSessions()
let config = try await gateway.getConfig()  // 没必要等 sessions 完成
```

**主线程隔离：**
```swift
// ✅ UI 更新必须在主线程
@MainActor
func updateUI() {
    // UI 代码
}

// ✅ 从后台切换回主线程
Task { @MainActor in
    // 更新 UI
}

// ❌ 避免：在后台线程直接修改 @Published 属性
```

**错误处理：**
```swift
// ✅ 使用 do-catch 明确处理错误
do {
    try await connect()
} catch let error as ConnectionError {
    logger.error("连接失败：\(error)")
    // 显示用户友好的错误消息
} catch {
    logger.error("未知错误：\(error)")
}

// ✅ 使用 Result 类型传递可能失败的值
func load() async -> Result<Data, Error> {
    do {
        return .success(try await fetchData())
    } catch {
        return .failure(error)
    }
}
```

---

### 编译错误快速诊断

**常见错误及解决方法：**

| 错误类型 | 症状 | 快速解决 |
|---------|------|---------|
| **模块找不到** | `No such module: 'X'` | 检查 Target Membership，确认文件在正确的 target 中 |
| **协议一致性** | `Type does not conform to protocol` | 使用 Xcode 的 Fix-it 自动添加缺失的方法 |
| **可选值解包** | `Value of optional type must be unwrapped` | 使用 `if let` 或 `guard let`，避免 force unwrap |
| **并发隔离** | `Call to main actor-isolated initializer in nonisolated context` | 添加 `@MainActor` 或使用 `Task { @MainActor in }` |
| **SwiftData 宏** | `Macro expansion is not supported` | 确认 Xcode 版本 ≥ 15，清理构建缓存 |

**诊断流程：**
```
1. 读取完整错误信息（不要只看第一行）
2. 定位错误文件和行号
3. 检查上下文（前后 5-10 行）
4. 使用 Xcode 的 Fix-it 建议
5. 如果不确定，搜索错误信息 + "Swift"
```

**清理构建缓存：**
```bash
# 删除 DerivedData
rm -rf build/macos/DerivedData
rm -rf build/ios/DerivedData

# 或者使用 Xcode
Xcode → Product → Clean Build Folder (Cmd+Shift+K)
```

---

### 测试修复流程

**当测试失败时：**

```
1. 读取失败日志 → 2. 定位失败原因 → 3. 分析是代码问题还是测试问题
   → 4. 制定修复方案 → 5. 用户批准 → 6. 执行修复 → 7. 重新运行测试
```

**失败类型判断：**

| 类型 | 特征 | 解决方法 |
|------|------|---------|
| **代码 bug** | 断言失败，逻辑错误 | 修复代码逻辑 |
| **测试过期** | 测试期望与新的设计不符 | 更新测试断言 |
| **环境问题** | 找不到资源、权限问题 | 修复测试环境配置 |
| **并发问题** | 随机失败、时序相关 | 添加等待或同步机制 |

**修复原则：**
- ✅ 优先修复代码，而不是修改测试来"通过"
- ✅ 如果测试本身有误，明确说明原因再修改
- ✅ 修复后必须重新运行全部测试
- ✅ 新增回归测试防止问题重现

---

### 编译前检查清单

**在执行编译前，快速检查以下项目（<30 秒）：**

- [ ] **Git 状态干净** - `git status` 确认没有意外修改
- [ ] **分支正确** - 在正确的功能分支上，不是 main
- [ ] **文件保存** - 所有修改的文件已保存（Cmd+S）
- [ ] **无语法错误** - Xcode 没有显示红色错误标记
- [ ] **依赖完整** - 没有缺失的 import 或模块

**快速检查命令：**
```bash
# 检查 Git 状态
git status --short

# 检查是否有未保存的文件（Mac）
# 在 Xcode 中查看文件标签是否有圆点

# 快速语法检查（不编译）
swiftc -parse Sources/**/*.swift 2>&1 | head -20
```

**如果检查失败：**
- Git 有未预期修改 → 询问用户是否要包含
- 分支错误 → 切换到正确的分支
- 语法错误 → 先修复错误再编译

---

## 📝 Git 提交规则

**⚠️ 绝对禁止：AI 不能自行提交代码！**

### 提交流程

```
完成任务 → 列出修改文件 → 请求用户批准 → 用户允许 → 执行提交
```

### 具体要求

1. **禁止自动提交** - 必须先向用户展示修改内容并等待批准
2. **提交范围限制** - 只能提交自己修改过的文件
3. **提交信息格式** - `[类型] 简要描述`
   - 示例：`[feature] 添加会话搜索功能`
4. **必须使用 `script/committer` 脚本**

### 使用脚本提交

```bash
# 用法
./script/committer "<提交信息>" <文件 1> [文件 2]...

# 示例
./script/committer "[fix] 修复空指针崩溃" Sources/Managers/SessionManager.swift
```

**脚本特性：**
- ✅ 自动检查文件是否存在
- ✅ 自动跳过无修改的文件
- ✅ 只显示提交指定的文件
- ✅ 防止误操作

**提交类型：**
| 类型 | 用途 |
|------|------|
| `[feature]` | 新功能 |
| `[fix]` | 修复 bug |
| `[ui]` | UI 改进 |
| `[refactor]` | 重构 |
| `[docs]` | 文档更新 |
| `[style]` | 代码格式化 |
| `[ci]` | CI/CD 配置 |
| `[test]` | 测试相关 |

---

## 🚀 PR 提交流程（精简版）

### 前提条件

1. **代码格式化** - `bash script/format.sh` ✅
2. **本地编译** - 三个平台编译通过（用子代理）
3. **单元测试** - 所有测试通过（用子代理）
4. **查看分支差别** - `git log --oneline origin/main..HEAD`

### 提交步骤

```bash
# 1. 提交代码（使用脚本）
./script/committer "[类型] 描述" 文件...

# 2. 推送到 GitHub
git push origin <分支名>

# 3. 创建 PR
# 访问：https://github.com/Alex-ai-future/openclaw-deck-swift/pulls
# 点击 "New pull request"，选择分支

# 4. 填写 PR 描述
# - 改动说明（目的和解决的问题）
# - 测试清单（编译 + 测试 + 格式化）
# - 相关 Issue 编号
# - 提交历史（git log --oneline origin/main..HEAD）

# 5. 等待 CI 通过
# - GitHub Actions 自动运行
# - 查看 PR 页面底部的检查状态

# 6. 合并 PR
# - 所有 CI 检查通过
# - 至少 1 人审查通过
# - 使用 "Squash and merge"（推荐）
```

### CI 失败处理

**调试步骤：**
1. 点击 "Details" 查看详细日志
2. 定位失败的步骤（Format/Build/Test）
3. **创建子代理**重新运行对应命令
4. 根据日志修复问题
5. 重新推送代码，CI 会自动重新运行

---

## 🧪 测试规范

### 测试框架
- **XCTest** - Swift 原生测试框架
- **测试脚本**: `bash script/run_unit_tests.sh`
- **测试位置**: 与源码同目录，`*Tests.swift` 命名
- **测试数量**: 93 个单元测试

### 测试运行规则

**⚠️ 主代理禁止直接运行测试（耗时 2-10 分钟）**

**正确流程：**
```
1. AI 修改逻辑代码
2. AI 问："需要运行测试吗？"
3. 用户批准
4. AI 用子代理运行测试
5. 测试通过后才能提交
```

### 测试覆盖要求

**必须添加测试的情况：**
- ✅ 新增功能模块
- ✅ 修复 bug（添加回归测试）
- ✅ 重构核心逻辑

**测试命名规范：**
```swift
// 格式：test<功能>_<场景>_<预期结果>()
func testSendMessage_WithValidSession_ShouldSucceed()
func testParseMessage_WithInvalidFormat_ShouldReturnNil()
```

### 特殊情况

**可以不运行测试的情况：**
- 📝 只修改文档
- 🎨 只修改注释/空格
- 🖼️ 只修改 UI 资源文件

**但必须问用户：** "我只改了文档/注释，需要运行测试吗？"

---

## 🔒 多代理安全规则

**背景：** 当多个 AI 同时工作时，某些操作可能互相干扰。

### ❌ 禁止的操作（除非用户明确指令）

**1. 禁止 git stash** - 可能隐藏其他 AI 的改动  
**2. 禁止切换分支** - 可能打断其他 AI 的工作  
**3. 禁止修改 worktree** - 改变项目结构  
**4. 禁止自动 rebase** - autostash 可能丢失改动

### ✅ 允许的操作

**1. 查看状态（只读）** - `git status`, `git diff`, `git log`  
**2. 提交自己的改动** - 使用 `script/committer`  
**3. 用户明确指令时** - 可以执行 git pull/checkout 等

### 🤝 多代理协作建议

1. **编译前询问** - "现在可以编译吗？"
2. **避免同时编译** - 等另一个 AI 完成
3. **只提交自己的改动** - 不提交其他 AI 修改的文件

---

## 📝 文档编写规则

### 文档内容规范

**✅ 应该写的内容：**
- 功能说明和使用方法
- 技术架构和实现细节
- 故障排除指南
- 最佳实践

**❌ 不应该写的内容：**
- **变更日志/更新记录** - 不要记录"某月某日添加了什么功能"
- 版本历史
- 临时性的开发笔记

**原因：** 文档应该聚焦在"如何使用"和"是什么"，变更记录通过 git history 查看。

---

## 🧹 代码清理规则

### 使用 swiftformat 格式化代码

**安装：** `brew install swiftformat`

**命令：**
```bash
# 格式化整个项目
bash script/format.sh --all

# 格式化修改的文件
bash script/format.sh

# 只检查不修改（CI 用）
bash script/format.sh --check
```

**注意事项：**
- ✅ 提交时自动格式化（pre-commit hook）
- ✅ 无需手动运行格式化
- ⚠️ 格式化后建议运行编译测试

---

## ✅ 代码修改后的标准流程

**每次修改代码后：**

### 1. 自动格式化（pre-commit hook）
提交时会自动触发 pre-commit hook 格式化 Swift 代码，无需手动运行。

### 2. 提交代码
```bash
./script/committer "[类型] 描述" 文件 1 文件 2...
```

**注意：** 不自动执行编译（太耗时），如需验证，手动运行编译脚本（用子代理）。

---

## 📝 日志规范

### 日志查看（iOS 设备）

**设备日志自动同步到 Mac！**

**1. Console.app（推荐）**
```
1. Mac 打开 Console.app
2. 左侧选择你的 iPhone
3. 搜索：com.openclaw.deck
4. 实时查看所有日志
```

**2. Xcode 控制台**
```
1. Xcode → Window → Devices and Simulators
2. 选择 iPhone → 勾选 "Show the console"
3. 运行 App → 日志自动显示
```

### 日志级别使用

| 级别 | 用途 | 示例 |
|------|------|------|
| `error` | 错误，需要立即处理 | 连接失败、数据丢失 |
| `warning` | 警告，不影响功能 | 重试成功、降级处理 |
| `info` | 重要事件 | 用户登录、配置变更 |
| `debug` | 调试信息 | 状态变化、中间结果 |

### 日志代码示例

```swift
import OSLog

private let logger = Logger(subsystem: "com.openclaw.deck", category: "Gateway")

logger.error("连接失败：\(error)")
logger.warning("重试成功")
logger.info("用户登录")
logger.debug("状态变化：\(state)")
```

---

**创建日期：** 2026-02-26  
**最后更新：** 2026-03-06（蒸馏工作流程经验 - 精简过时内容 + 新增实践规范）
