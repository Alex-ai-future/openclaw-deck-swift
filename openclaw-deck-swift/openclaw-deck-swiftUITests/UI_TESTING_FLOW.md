# UI 测试流程文档

**文档目的：** 记录 OpenClaw Deck Swift 的界面测试流程，确保所有核心功能都有对应的自动化测试覆盖。

**最后更新：** 2026-03-03

---

## 测试环境配置

### 启动参数
```swift
// 测试模式
app.launchEnvironment["UITESTING"] = "YES"

// 禁用动画（加速测试）
app.launchArguments.append("--disable-animations")
```

### 测试数据
- 使用 Mock 数据
- 不依赖真实 Gateway 服务器
- 会话和消息数据预加载

---

## 核心测试流程

### 流程 1：完整会话生命周期测试

**测试文件：** `SessionManagementUITests.swift`  
**测试方法：** `testCompleteSessionLifecycle()`

> 💡 **说明：** 此流程覆盖了会话创建、消息发送、排序、删除等核心功能，其他相关流程无需重复测试。

#### 前置条件
- 应用已保存凭证，启动后直接进入主界面（DeckView）
- 系统会自动保留至少 1 个会话，无法完全清空

---

#### 阶段 0：清理现有会话

**界面：** 主界面（DeckView）→ 会话详情 → 删除确认

| 步骤 | 操作 | 按钮/元素标识符 | 位置 |
|------|------|----------------|------|
| 0.1 | 获取当前会话列表 | `Button` (identifier 包含 "Session") | 会话列表 |
| 0.2 | 记录初始会话数量 | `initialCount` | - |
| 0.3 | 如果数量 > 1，进入循环 | - | - |
| 0.3.1 | 点击第一个会话 | `Button` (identifier 包含 "Session") | 会话列表 |
| 0.3.2 | 进入会话详情页 | - | 自动跳转 |
| 0.3.3 | 点击删除按钮 | `deleteSessionButton` | 详情页底部 |
| 0.3.4 | 确认删除弹窗出现 | alert "confirm_delete" | 屏幕中央 |
| 0.3.5 | 点击删除确认按钮 | "删除" 或 "Delete" | 弹窗右侧 |
| 0.3.6 | 验证会话消失，返回列表 | - | 自动返回 |
| 0.3.7 | 重复 0.3.1-0.3.6 | - | 直到只剩 1 个会话 |
| 0.4 | 验证列表只剩 1 个会话 | 系统自动保留 | 会话列表 |

**说明：**
- ⚠️ 系统会自动保留至少 1 个会话，无法完全清空
- 清理目标：删除到只剩 1 个系统默认会话

**代码示例：**
```swift
while true {
    let sessionButtons = app.buttons.matching(
        NSPredicate(format: "identifier CONTAINS 'Session'")
    ).allElementsBoundByIndex
    
    // 只剩 1 个会话时停止（系统自动保留）
    if sessionButtons.count <= 1 {
        print("✅ 清理完成，剩余 \(sessionButtons.count) 个会话（系统保留）")
        break
    }
    
    // 删除第一个会话
    sessionButtons[0].forceTap()
    // ... 删除流程
}
```

---

#### 阶段 1：创建三个会话

**界面：** 主界面（DeckView）→ 新建会话弹窗

| 步骤 | 操作 | 按钮/元素标识符 | 位置 |
|------|------|----------------|------|
| 1.1 | 点击新建会话按钮 | `NewSessionButton` (plus 图标) | 右上角工具栏 |
| 1.2 | 验证弹窗出现 | `sheet` 包含输入框 | 屏幕中央 |
| 1.3 | 在名称输入框输入 | 第一个 `TextField` | 弹窗顶部 |
| 1.4 | 在备注输入框输入 | 第一个 `TextEditor` | 弹窗中部 |
| 1.5 | 点击创建按钮 | "创建" 或 "Create" | 弹窗右上角 |
| 1.6 | 验证会话出现在列表 | `Button` (identifier 包含 "Session") | 会话列表 |
| 1.7 | 重复 1.1-1.6 两次 | - | - |

**输入内容示例：**
- 会话 1：名称="测试会话 1"，备注="这是第一个测试会话"
- 会话 2：名称="测试会话 2"，备注="这是第二个测试会话"
- 会话 3：名称="测试会话 3"，备注="这是第三个测试会话"

**验证：**
- ✅ 列表中有 4 个会话（1 个系统保留 + 3 个新建）
- ✅ 每个会话的名称都正确显示

---

#### 阶段 2：每个会话发送消息（触发连接失败）

**界面：** 主界面（DeckView）

| 步骤 | 操作 | 按钮/元素标识符 | 位置 |
|------|------|----------------|------|
| 2.1 | 点击选中第一个会话 | `Button` (identifier 包含 "Session") | 会话列表 |
| 2.2 | 在消息输入框输入 | `messageInput` (TextField) | 底部输入框 |
| 2.3 | 点击发送按钮 | `sendButton` (arrow.up.circle 图标) | 输入框右侧 |
| 2.4 | 连接失败弹窗出现 | alert | 屏幕中央 |
| 2.5 | 点击取消按钮 | "取消" 或 "Cancel" | 弹窗左侧 |
| 2.6 | 重复 2.1-2.5 | - | 对每个新建会话执行 |

**说明：**
- 测试模式下会弹出"连接失败"窗口
- 点击"取消"关闭弹窗，消息不会发送

---

#### 阶段 3：记录当前顺序

**操作：**
```swift
let sessions = app.buttons.matching(
    NSPredicate(format: "identifier CONTAINS 'Session'")
).allElementsBoundByIndex

let order = sessions.map { $0.identifier }
print("当前顺序：\(order)")
// 预期：["Session-测试会话 1", "Session-测试会话 2", "Session-测试会话 3", ...]
```

---

#### 阶段 4：排序 - 完全反转

**界面：** 主界面 → 排序弹窗

| 步骤 | 操作 | 按钮/元素标识符 | 位置 |
|------|------|----------------|------|
| 4.1 | 点击排序按钮 | `SortButton` (arrow.up.arrow.down 图标) | 右上角工具栏 |
| 4.2 | 验证排序弹窗打开 | `sheet` 包含拖拽手柄 | 屏幕中央 |
| 4.3 | 拖拽会话调整顺序 | `Image` (line.3.horizontal 图标) | 每个会话左侧 |
| 4.4 | 点击完成按钮 | "完成" 或 "Done" | 弹窗右上角 |
| 4.5 | 验证顺序已反转 | 检查会话按钮顺序 | 会话列表 |

**预期结果：**
- 原顺序：["测试会话 1", "测试会话 2", "测试会话 3"]
- 反转后：["测试会话 3", "测试会话 2", "测试会话 1"]

**验证：**
```swift
let sessions = app.buttons.matching(
    NSPredicate(format: "identifier CONTAINS 'Session'")
).allElementsBoundByIndex

// 验证顺序已反转
XCTAssertEqual(sessions[0].label, "测试会话 3")
XCTAssertEqual(sessions[1].label, "测试会话 2")
XCTAssertEqual(sessions[2].label, "测试会话 1")
```

---

#### 阶段 5：删除所有新建会话

**界面：** 主界面 → 会话详情 → 删除确认

| 步骤 | 操作 | 按钮/元素标识符 | 位置 |
|------|------|----------------|------|
| 5.1 | 点击第一个会话 | `Button` (identifier 包含 "Session") | 会话列表 |
| 5.2 | 进入会话详情页 | - | 自动跳转 |
| 5.3 | 点击删除按钮 | `deleteSessionButton` | 详情页底部 |
| 5.4 | 确认删除弹窗出现 | alert "confirm_delete" | 屏幕中央 |
| 5.5 | 点击删除确认按钮 | "删除" 或 "Delete" | 弹窗右侧 |
| 5.6 | 验证会话消失，返回列表 | - | 自动返回 |
| 5.7 | 重复 5.1-5.6 | - | 删除所有新建会话 |

**最终验证：**
- ✅ 列表只剩 1 个系统保留会话

---

### 流程 2：设置页面完整测试流程

**测试文件：** `SettingsUITests.swift`  
**测试方法：** `testSettingsCompleteFlow()`

> 💡 **说明：** 测试设置页面的所有输入框修改、取消不保存、保存生效的完整流程。

#### 前置条件
- 应用已启动，进入主界面（DeckView）
- 已有保存的 Gateway 配置（URL 和 Token）

---

#### 阶段 0：打开设置页面

| 步骤 | 操作 | 按钮/元素标识符 | 位置/说明 |
|------|------|----------------|-----------|
| 0.1 | 点击设置按钮 | `settingsButton` (gear 图标) | 左上角 |
| 0.2 | 验证设置弹窗出现 | `sheet` | 屏幕中央 |
| 0.3 | 验证连接状态显示 | Text "Connected" 或 "Not Connected" | 顶部 Section |

**验证：**
- ✅ 设置按钮存在
- ✅ 设置弹窗打开
- ✅ 连接状态正确显示

---

#### 阶段 1：记录并修改输入框内容（第一次）

**界面：设置弹窗**

| 步骤 | 操作 | 按钮/元素标识符 | 位置/说明 |
|------|------|----------------|-----------|
| 1.1 | 获取 Gateway URL 输入框 | `gatewayUrlInput` (TextField) | Gateway Section |
| 1.2 | 记录原始 URL 值 | `originalUrl` | - |
| 1.3 | 获取 Token 输入框 | `tokenInput` (SecureTextField) | Gateway Section |
| 1.4 | 记录原始 Token 值 | `originalToken` | - |
| 1.5 | 修改 Gateway URL | 输入："ws://test-host:12345" | `gatewayUrlInput` |
| 1.6 | 修改 Token | 输入："test-token-123" | `tokenInput` |
| 1.7 | 验证 "Apply & Reconnect" 按钮出现 | "Apply & Reconnect" 按钮 | 有修改时显示 |

**代码示例：**
```swift
// 记录原始值
let originalUrl = app.textFields["gatewayUrlInput"].value as! String
let originalToken = app.secureTextFields["tokenInput"].value as! String

// 修改 URL
let urlField = app.textFields["gatewayUrlInput"]
urlField.tap()
urlField.typeText("ws://test-host:12345")

// 修改 Token
let tokenField = app.secureTextFields["tokenInput"]
tokenField.tap()
tokenField.typeText("test-token-123")

// 验证 Apply & Reconnect 按钮出现
let applyButton = app.buttons["Apply & Reconnect"].firstMatch
XCTAssertTrue(applyButton.exists, "修改后应该显示 Apply & Reconnect 按钮")
```

**验证：**
- ✅ Gateway URL 输入框可编辑
- ✅ Token 输入框可编辑
- ✅ 修改后出现 "Apply & Reconnect" 按钮

---

#### 阶段 2：点击取消并验证不保存

| 步骤 | 操作 | 按钮/元素标识符 | 位置/说明 |
|------|------|----------------|-----------|
| 2.1 | 点击取消按钮 | "Cancel" / "取消" | 左上角 |
| 2.2 | 验证弹窗关闭 | `sheet` 消失 | - |
| 2.3 | 再次点击设置按钮 | `settingsButton` | 左上角 |
| 2.4 | 验证弹窗重新打开 | `sheet` 出现 | - |
| 2.5 | 检查 Gateway URL 输入框 | `gatewayUrlInput` | 应该是原始值 |
| 2.6 | 验证 URL 未保存 | `gatewayUrlInput.value == originalUrl` | - |
| 2.7 | 检查 Token 输入框 | `tokenInput` | 应该是原始值 |
| 2.8 | 验证 Token 未保存 | `tokenInput.value == originalToken` | - |

**代码示例：**
```swift
// 点击取消
app.buttons["Cancel"].firstMatch.forceTap()

// 重新打开设置
app.buttons["settingsButton"].firstMatch.forceTap()

// 验证值未改变
let currentUrl = app.textFields["gatewayUrlInput"].value as! String
let currentToken = app.secureTextFields["tokenInput"].value as! String

XCTAssertEqual(currentUrl, originalUrl, "取消后 URL 应该保持不变")
XCTAssertEqual(currentToken, originalToken, "取消后 Token 应该保持不变")
```

**验证：**
- ✅ 点击取消后弹窗关闭
- ✅ 重新打开后 URL 保持原始值
- ✅ 重新打开后 Token 保持原始值

---

#### 阶段 3：修改并保存（第二次修改）

| 步骤 | 操作 | 按钮/元素标识符 | 位置/说明 |
|------|------|----------------|-----------|
| 3.1 | 修改 Gateway URL | 输入："ws://new-host:99999" | `gatewayUrlInput` |
| 3.2 | 修改 Token | 输入："new-token-999" | `tokenInput` |
| 3.3 | 点击完成按钮 | "Done" / "完成" | 右上角 |
| 3.4 | 验证弹窗关闭 | `sheet` 消失 | - |

**代码示例：**
```swift
// 清空并输入新 URL
let urlField = app.textFields["gatewayUrlInput"]
urlField.tap()
urlField.typeText(XCUIKeyboardKey.delete)  // 清空
urlField.typeText("ws://new-host:99999")

// 清空并输入新 Token
let tokenField = app.secureTextFields["tokenInput"]
tokenField.tap()
tokenField.typeText(XCUIKeyboardKey.delete)  // 清空
tokenField.typeText("new-token-999")

// 点击 Done 保存
app.buttons["Done"].firstMatch.forceTap()
```

**验证：**
- ✅ 修改后可以点击 Done 保存
- ✅ 弹窗关闭

---

#### 阶段 4：验证保存成功

| 步骤 | 操作 | 按钮/元素标识符 | 位置/说明 |
|------|------|----------------|-----------|
| 4.1 | 再次点击设置按钮 | `settingsButton` | 左上角 |
| 4.2 | 验证弹窗打开 | `sheet` 出现 | - |
| 4.3 | 检查 Gateway URL | `gatewayUrlInput` | 应该是 "ws://new-host:99999" |
| 4.4 | 验证 URL 已保存 | `gatewayUrlInput.value == "ws://new-host:99999"` | - |
| 4.5 | 检查 Token | `tokenInput` | 应该是 "new-token-999" |
| 4.6 | 验证 Token 已保存 | `tokenInput.value == "new-token-999"` | - |
| 4.7 | 点击取消按钮 | "Cancel" | 左上角 |
| 4.8 | 关闭设置页面 | - | - |

**代码示例：**
```swift
// 重新打开设置
app.buttons["settingsButton"].firstMatch.forceTap()

// 验证保存后的值
let savedUrl = app.textFields["gatewayUrlInput"].value as! String
let savedToken = app.secureTextFields["tokenInput"].value as! String

XCTAssertEqual(savedUrl, "ws://new-host:99999", "URL 应该已保存")
XCTAssertEqual(savedToken, "new-token-999", "Token 应该已保存")

// 关闭设置
app.buttons["Cancel"].firstMatch.forceTap()
```

**验证：**
- ✅ URL 已保存为新值
- ✅ Token 已保存为新值

---

### 按钮标识符汇总

| 按钮/元素 | Identifier | 类型 | 位置 |
|----------|-----------|------|------|
| 设置按钮 | `settingsButton` | Button | 左上角 |
| 新建会话 | `NewSessionButton` | Button | 右上角 |
| 排序按钮 | `SortButton` | Button | 右上角 |
| 发送按钮 | `sendButton` | Button | 输入框右侧 |
| 消息输入框 | `messageInput` | TextField | 底部 |
| 删除按钮 | `deleteSessionButton` | Button | 详情页底部 |
| Gateway URL 输入框 | `gatewayUrlInput` | TextField | 设置弹窗 |
| Token 输入框 | `tokenInput` | SecureTextField | 设置弹窗 |
| 取消按钮 | "Cancel" / "取消" | Button | 设置弹窗左上角 |
| 完成按钮 | "Done" / "完成" | Button | 设置弹窗右上角 |
| Apply & Reconnect | "Apply & Reconnect" | Button | 设置弹窗 |
| 拖拽手柄 | `line.3.horizontal` | Image | 排序弹窗 |
| 会话按钮 | 包含 "Session" | Button | 会话列表 |

---

### 流程 3：同步功能流程

**测试文件：** `SyncButtonUITests.swift`  
**测试方法：** `testSyncAndConflict()`

> 💡 **说明：** 测试 Cloudflare KV 同步和冲突处理。

**流程步骤：**
- [ ] 点击同步按钮
- [ ] 验证同步确认弹窗
- [ ] 点击确定开始同步
- [ ] 验证同步进度显示
- [ ] 验证同步完成提示

**同步冲突处理：**
- [ ] 检测到同步冲突
- [ ] 显示冲突解决选项
- [ ] 选择使用本地数据
- [ ] 选择使用云端数据
- [ ] 选择取消同步

---

### 流程 4：应用启动流程

**测试文件：** `AppLaunchUITests.swift`  
**测试方法：** `testAppLaunchAndResume()`

> 💡 **说明：** 测试应用冷启动和后台恢复。

**流程步骤：**
- [ ] 冷启动应用
- [ ] 验证启动时间
- [ ] 验证自动连接（有保存凭证时）
- [ ] 验证欢迎界面（无保存凭证时）
- [ ] 从后台恢复应用
- [ ] 验证自动重连

---

## 测试用例映射表

| 流程 | 测试文件 | 测试方法 | 状态 |
|------|---------|---------|------|
| 完整会话生命周期 | SessionManagementUITests.swift | testCompleteSessionLifecycle() | 🔄 待实现 |
| 设置页面完整流程 | SettingsUITests.swift | testSettingsCompleteFlow() | 🔄 待实现 |
| 同步功能 | SyncButtonUITests.swift | testSyncAndConflict() | ✅ |
| 应用启动 | AppLaunchUITests.swift | testAppLaunchAndResume() | ✅ |

> ✅ = 已有测试 | 🔄 = 待实现/优化

---

## 测试运行命令

```bash
# 运行所有 UI 测试
bash script/run_ui_tests.sh macos

# 运行特定测试文件
xcodebuild test \
  -scheme openclaw-deck-swift \
  -destination 'platform=macOS' \
  -only-testing:openclaw-deck-swiftUITests/SessionManagementUITests

# 运行特定测试方法
xcodebuild test \
  -scheme openclaw-deck-swift \
  -destination 'platform=macOS' \
  -only-testing:openclaw-deck-swiftUITests/SessionManagementUITests/testCompleteSessionLifecycle
```

---

## 常见问题

### Q: 测试失败如何调试？
A: 查看测试日志 `build/ui_tests/test_output.log`

### Q: 如何添加新的测试用例？
A: 在对应测试文件中添加新方法，命名格式：`test[功能]_[场景]_[预期结果]()`

### Q: 测试运行太慢怎么办？
A: 确保设置了 `UITESTING=YES` 和 `--disable-animations`

### Q: 为什么无法完全删除所有会话？
A: 系统会自动保留至少 1 个会话，这是预期行为。测试时应验证"只剩 1 个会话"而非"列表为空"。

### Q: 设置页面的 Token 输入框找不到？
A: Token 输入框是 `secureTextFields` 类型，不是 `textFields`。使用 `app.secureTextFields["tokenInput"]` 访问。

---

**维护说明：**
- 每次添加新功能时，更新此文档并添加对应测试
- 测试流程变更时，同步更新文档
- 定期审查测试覆盖率，确保核心功能都有测试
