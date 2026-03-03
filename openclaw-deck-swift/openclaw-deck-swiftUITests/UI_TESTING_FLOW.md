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

> 💡 **说明：** 此流程覆盖了会话创建、消息发送、排序、删除等核心功能。

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

**验证标准：**
- ✅ `XCTAssertTrue(sessionButtons.count >= 1)` - 至少有一个会话
- ✅ 删除操作必须成功，否则测试失败

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

**验证标准：**
- ✅ `XCTAssertTrue(newSessionButton.exists)` - 新建按钮必须存在
- ✅ `XCTAssertTrue(sheet.exists)` - 弹窗必须出现
- ✅ `XCTAssertEqual(sessionCount, 4)` - 必须有 4 个会话（1+3）
- ❌ 失败则测试终止，不继续执行

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

**验证标准：**
- ✅ `XCTAssertTrue(alert.exists)` - 连接失败弹窗必须出现
- ✅ `XCTAssertTrue(cancelButton.exists)` - 取消按钮必须存在

---

#### 阶段 3：记录当前顺序

**操作：**
```swift
let sessions = app.buttons.matching(
    NSPredicate(format: "identifier CONTAINS 'Session'")
).allElementsBoundByIndex

let order = sessions.map { $0.identifier }
print("当前顺序：\(order)")
```

**验证标准：**
- ✅ `XCTAssertGreaterThanOrEqual(sessions.count, 4)` - 至少有 4 个会话

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

**验证标准：**
- ✅ `XCTAssertTrue(sortButton.exists)` - 排序按钮必须存在
- ✅ `XCTAssertTrue(sortSheet.exists)` - 排序弹窗必须打开
- ✅ `XCTAssertEqual(sessions[0].label, "测试会话 3")` - 顺序必须反转

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
- ✅ `XCTAssertEqual(finalCount, 1)` - 必须只剩 1 个系统保留会话

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

**验证标准：**
- ✅ `XCTAssertTrue(settingsButton.exists)` - 设置按钮必须存在
- ✅ `XCTAssertTrue(settingsSheet.exists)` - 设置弹窗必须打开

---

#### 阶段 1：记录并修改输入框内容（第一次）

**验证标准：**
- ✅ `XCTAssertTrue(gatewayUrlInput.exists)` - URL 输入框必须存在
- ✅ `XCTAssertTrue(tokenInput.exists)` - Token 输入框必须存在
- ✅ `XCTAssertTrue(applyButton.exists)` - 修改后 Apply 按钮必须出现

---

#### 阶段 2：点击取消并验证不保存

**验证标准：**
- ✅ `XCTAssertFalse(settingsSheet.exists)` - 取消后弹窗必须关闭
- ✅ `XCTAssertEqual(currentUrl, originalUrl)` - URL 必须保持原值
- ✅ `XCTAssertEqual(currentToken, originalToken)` - Token 必须保持原值

---

#### 阶段 3：修改并保存（第二次修改）

**验证标准：**
- ✅ `XCTAssertTrue(doneButton.exists)` - Done 按钮必须存在
- ✅ `XCTAssertFalse(settingsSheet.exists)` - 保存后弹窗必须关闭

---

#### 阶段 4：验证保存成功

**验证标准：**
- ✅ `XCTAssertEqual(savedUrl, "ws://new-host:99999")` - URL 必须已保存
- ✅ `XCTAssertEqual(savedToken, "new-token-999")` - Token 必须已保存

---

### 流程 3：应用启动流程

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

**验证标准：**
- ✅ `XCTAssertTrue(mainWindow.exists)` - 主窗口必须在 30 秒内加载
- ✅ `XCTAssertLessThanOrEqual(launchTime, 5.0)` - 启动时间不超过 5 秒

---

## 按钮标识符汇总

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

## 测试用例映射表

| 流程 | 测试文件 | 测试方法 | 状态 |
|------|---------|---------|------|
| 完整会话生命周期 | SessionManagementUITests.swift | testCompleteSessionLifecycle() | 🔄 待实现 |
| 设置页面完整流程 | SettingsUITests.swift | testSettingsCompleteFlow() | 🔄 待实现 |
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

### Q: 为什么测试会中途终止？
A: 这是预期行为。任何 `XCTAssert` 失败都会立即终止测试，确保问题不被忽略。

### Q: 如何添加新的测试用例？
A: 在对应测试文件中添加新方法，命名格式：`test[功能]_[场景]_[预期结果]()`

### Q: 测试运行太慢怎么办？
A: 确保设置了 `UITESTING=YES` 和 `--disable-animations`

### Q: 为什么无法完全删除所有会话？
A: 系统会自动保留至少 1 个会话，这是预期行为。测试时应验证"只剩 1 个会话"而非"列表为空"。

### Q: 设置页面的 Token 输入框找不到？
A: Token 输入框是 `secureTextFields` 类型，不是 `textFields`。使用 `app.secureTextFields["tokenInput"]` 访问。

---

## 测试代码编写规范

### 强制验证原则

**❌ 错误做法 - 使用 if 检查跳过：**
```swift
if button.exists {
    button.tap()
} else {
    print("按钮不存在，跳过")
    return  // 测试提前结束，不报错
}
```

**✅ 正确做法 - 使用 XCTAssert 强制验证：**
```swift
XCTAssertTrue(button.exists, "按钮必须存在")
button.tap()  // 如果不存在，测试会在这里失败并报错
```

### 验证标准

1. **每个关键步骤都必须有 XCTAssert 验证**
2. **失败必须报错，不能跳过或忽略**
3. **错误信息必须清晰，说明期望和实际结果**
4. **测试要么完全通过，要么明确失败，没有中间状态**

### 示例对比

**❌ 弱验证：**
```swift
let button = app.buttons["test"]
if button.exists {
    button.tap()
    print("点击成功")
}
```

**✅ 强验证：**
```swift
let button = app.buttons["test"]
XCTAssertTrue(button.waitForExistence(timeout: 5), 
              "测试按钮必须在 5 秒内出现")
button.tap()
XCTAssertTrue(resultView.exists, 
              "点击后结果视图必须显示")
```

---

**维护说明：**
- 每次添加新功能时，更新此文档并添加对应测试
- 测试流程变更时，同步更新文档
- 定期审查测试覆盖率，确保核心功能都有测试
- 所有新测试必须遵循"强制验证原则"
