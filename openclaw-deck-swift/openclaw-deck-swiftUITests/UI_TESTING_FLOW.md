# UI 测试流程文档

**文档目的：** 记录 OpenClaw Deck Swift 的界面测试流程，确保所有核心功能都有对应的自动化测试覆盖。

**最后更新：** 2026-03-03

---

## 测试环境配置

### 启动参数
```bash
# 测试模式
launchEnvironment["UITESTING"] = "YES"

# 禁用动画（加速测试）
launchArguments.append("--disable-animations")
```

### 测试数据
- 使用 Mock 数据
- 不依赖真实 Gateway 服务器
- 会话和消息数据预加载

---

## 核心测试流程

### 1. 首次启动和连接流程

**测试文件：** `SettingsUITests.swift`

**流程步骤：**
- [ ] 应用启动，显示欢迎界面
- [ ] 验证 Logo 和标题显示
- [ ] 验证首次安装引导卡片显示
- [ ] 验证登录引导卡片显示
- [ ] 点击右上角设置按钮
- [ ] 验证设置页面打开
- [ ] 输入 Gateway URL
- [ ] 输入 Token（可选）
- [ ] 点击连接按钮
- [ ] 验证连接成功/失败提示
- [ ] 验证配置保存

**边界情况：**
- [ ] URL 格式错误时的错误提示
- [ ] 连接失败时的错误显示
- [ ] 点击取消不保存配置
- [ ] 点击确定保存配置

---

### 2. 会话管理流程

**测试文件：** `SessionManagementUITests.swift`

**流程步骤：**
- [ ] 验证会话列表显示
- [ ] 点击创建新会话按钮
- [ ] 输入会话名称
- [ ] 验证新会话创建成功
- [ ] 点击切换会话
- [ ] 验证会话切换成功
- [ ] 删除会话
- [ ] 验证删除确认弹窗
- [ ] 验证会话删除成功

**排序功能：**
- [ ] 点击排序按钮
- [ ] 选择排序方式（按时间/按名称）
- [ ] 验证排序结果

---

### 3. 消息发送流程

**测试文件：** `SendMessageUITests.swift`

**流程步骤：**
- [ ] 选中会话
- [ ] 在输入框输入消息
- [ ] 点击发送按钮（或按回车）
- [ ] 验证消息显示在对话中
- [ ] 验证发送按钮状态变化

**边界情况：**
- [ ] 空消息不允许发送
- [ ] 发送失败时的错误提示
- [ ] 重试发送功能

---

### 4. 同步功能流程

**测试文件：** `SyncButtonUITests.swift`

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

### 5. 设置页面流程

**测试文件：** `SettingsUITests.swift`

**流程步骤：**
- [ ] 打开设置页面
- [ ] 验证连接状态显示
- [ ] 修改 Gateway URL
- [ ] 修改 Token
- [ ] 点击 Apply & Reconnect
- [ ] 验证重新连接
- [ ] 语言选择
- [ ] 通知开关
- [ ] Cloudflare KV 同步配置
- [ ] 重置设备身份
- [ ] 断开连接

---

### 6. 应用启动流程

**测试文件：** `AppLaunchUITests.swift`

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
| 应用启动 | AppLaunchUITests.swift | testAppLaunch() | ✅ |
| 连接流程 | SettingsUITests.swift | testConnectionFlow() | ✅ |
| 创建会话 | SessionManagementUITests.swift | testCreateSession() | ✅ |
| 切换会话 | SessionManagementUITests.swift | testSwitchSession() | ✅ |
| 删除会话 | SessionManagementUITests.swift | testDeleteSession() | ✅ |
| 发送消息 | SendMessageUITests.swift | testSendMessage() | ✅ |
| 同步功能 | SyncButtonUITests.swift | testSync() | ✅ |
| 同步冲突 | SyncButtonUITests.swift | testSyncConflict() | ✅ |

---

## 待补充流程

请在下方添加新的测试流程：

### X. [流程名称]

**测试文件：** `[文件名].swift`

**流程步骤：**
- [ ] 步骤 1
- [ ] 步骤 2

**边界情况：**
- [ ] 情况 1
- [ ] 情况 2

---

## 测试运行命令

```bash
# 运行所有 UI 测试
bash script/run_ui_tests.sh macos

# 运行特定测试文件
xcodebuild test \
  -scheme openclaw-deck-swift \
  -destination 'platform=macOS' \
  -only-testing:openclaw-deck-swiftUITests/SendMessageUITests

# 运行特定测试方法
xcodebuild test \
  -scheme openclaw-deck-swift \
  -destination 'platform=macOS' \
  -only-testing:openclaw-deck-swiftUITests/SendMessageUITests/testSendMessage
```

---

## 常见问题

### Q: 测试失败如何调试？
A: 查看测试日志 `build/ui_tests/test_output.log`

### Q: 如何添加新的测试用例？
A: 在对应测试文件中添加新方法，命名格式：`test[功能]_[场景]_[预期结果]()`

### Q: 测试运行太慢怎么办？
A: 确保设置了 `UITESTING=YES` 和 `--disable-animations`

---

**维护说明：**
- 每次添加新功能时，更新此文档并添加对应测试
- 测试流程变更时，同步更新文档
- 定期审查测试覆盖率，确保核心功能都有测试

