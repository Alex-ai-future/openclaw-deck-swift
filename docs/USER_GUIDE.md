# OpenClaw Deck Swift - 用户指南

**版本：** 1.5  
**最后更新：** 2026-02-28  
**适用平台：** macOS, iPadOS, iOS (iPhone, iPad, iPod touch)

---

## 目录

1. [5 分钟快速上手](#quick-start)
2. [iOS 设备连接 Gateway](#ios-connection) 
3. [核心功能](#core-features)
4. [Cloudflare 多设备同步](#cloudflare-sync) 
5. [故障排除](#troubleshooting) 
6. [常见问题](#faq)

---

## 5 分钟快速上手 {#quick-start}

### 1.1 安装

**推荐方式：一键安装脚本**

```bash
# macOS / Linux / WSL2
curl -fsSL https://openclaw.ai/install.sh | bash
```

安装完成后，运行 `openclaw start` 启动 Gateway。

**可选：跳过设置向导**
```bash
curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard
```

**备选方式：从源码编译**
```bash
cd ~/Projects
git clone https://github.com/Alex-ai-future/openclaw-deck-swift.git
open openclaw-deck-swift/openclaw-deck-swift.xcodeproj
# Xcode 中 Cmd+R 运行
```

### 1.2 配置 Gateway

**OpenClaw Deck Swift 需要连接 OpenClaw Gateway 才能工作。**

> 📚 **官方文档：** 详细的 Gateway 配置说明请查看 [OpenClaw Gateway 文档](https://docs.openclaw.ai)
> - 安装指南：https://docs.openclaw.ai/getting-started/installation
> - 快速入门：https://docs.openclaw.ai/getting-started/quickstart

**步骤 1：安装 Gateway**

```bash
# 推荐：使用安装脚本（见 1.1 节）
curl -fsSL https://openclaw.ai/install.sh | bash

# 启动 Gateway
openclaw start
```

**备选：从源码运行**
```bash
# 克隆 OpenClaw 项目
git clone https://github.com/openclaw/openclaw.git
cd openclaw
pnpm install
pnpm start
```

**步骤 2：配置连接**

1. 打开应用
2. 点击工具栏 ⚙️ 图标
3. 输入 Gateway URL: `ws://127.0.0.1:18789`
4. 点击 "Apply & Reconnect"

**步骤 3：验证连接**

- ✅ 绿色状态 = 已连接
- ⚠️ 橙色状态 = 连接中
- ❌ 红色状态 = 连接失败

---

## iOS 设备连接 Gateway {#ios-connection} 

> 📚 **官方文档：** 详细的移动设备连接说明请查看 [OpenClaw 移动设备连接指南](https://docs.openclaw.ai/guides/mobile-connection)

**适用设备：**
- iPhone (所有型号)
- iPad (所有型号)
- iPod touch

### 2.1 获取 Gateway 设备的 IP 地址

**在 Gateway 所在的设备上执行：**

```bash
# macOS
ipconfig getifaddr en0
# 输出示例：192.168.1.100

# Linux
hostname -I
# 输出示例：192.168.1.100

# Windows
ipconfig
# 输出示例：192.168.1.100
```

**记录这个 IP 地址（例如：192.168.1.100）**

---

### 2.2 配置 Gateway 允许 iOS 设备连接

**编辑 Gateway 配置文件：**

```bash
# 添加 iOS 设备到允许列表
allowed_origins = [
  "192.168.1.100",  # Gateway 设备的 IP
  "192.168.1.*"     # 允许同一网段的所有设备
]
```

⚠️ **注意：** 生产环境不要使用 `*`，应该指定具体 IP

---

### 2.3 在 iOS 设备上配置连接

1. **打开 OpenClaw Deck Swift 应用**

2. **进入设置页面**
   - 点击工具栏 ⚙️ 图标

3. **输入 Gateway URL**
   ```
   ws://192.168.1.100:18789
   ```
   （替换为你的 Gateway IP 地址）

4. **输入 Token（如果需要）**
   - 如果 Gateway 配置了认证
   - 输入 Token

5. **点击 "Apply & Reconnect"**

---

### 2.4 配对操作

**在 iOS 设备上：**
- 显示 "等待配对" 或橙色状态

**在 Gateway 设备上执行：**

```bash
# 1. 查看待配对设备
openclaw pairing list

# 输出示例：
# Pending devices:
#   - device-id-123 (iOS Device)

# 2. 同意配对
openclaw pairing approve device-id-123

# 3. 验证配对成功
openclaw pairing list
# 应该显示 "No pending devices"
```

**在 iOS 设备上验证：**
- ✅ 状态指示器变绿色 = 配对成功
- ✅ 可以开始发送消息

---

### 2.5 测试连接

**在 iOS 设备上：**
1. 点击顶部 `+` 创建 Session
2. 输入 "Hello from iOS"
3. 点击发送
4. 收到 AI 回复 = 连接正常

---

### 2.6 常见问题

#### Q: 配对后仍然连接失败？

**A: 检查防火墙设置**

**macOS:**
```
系统设置 → 网络 → 防火墙
→ 允许 Node.js 入站连接
```

**Linux:**
```bash
sudo ufw allow 18789/tcp
```

**Windows:**
```
控制面板 → Windows Defender 防火墙
→ 允许应用通过防火墙
→ 添加 Node.js
```

---

#### Q: iOS 设备找不到 Gateway？

**A: 检查网络**

1. **确认在同一 WiFi 网络**
   - Gateway 设备和 iOS 设备必须在同一局域网

2. **检查 IP 地址是否正确**
   - 确认 Gateway IP 没有变化
   - 使用静态 IP 或 DHCP 保留

3. **测试网络连通性**
   ```bash
   # 在 iOS 设备上用 Safari 访问
   http://192.168.1.100:18789
   ```

---

#### Q: 配对信息保存在哪里？

**A: 配对信息持久化保存**

- **Gateway 端：** 保存在 `~/.openclaw/paired_devices.json`
- **iOS 端：** 保存在 UserDefaults
- **下次连接：** 自动使用已配对的设备身份，无需重新配对

**清除配对：**
- iOS 设置 → "Reset Device Identity"
- Gateway 端删除 `paired_devices.json`

---

### 1.3 发送第一条消息

1. 点击顶部 `+` 创建 Session
2. 在输入框输入 "Hello"
3. 点击发送按钮（→）
4. 等待 AI 回复

---

## 核心功能 {#core-features}

### 3.1 发送消息

**方式 1：输入框发送**
1. 输入消息
2. 点击输入框右侧发送按钮（→）

**方式 2：底部快速发送**
1. 选中 Session（蓝色底条）
2. 输入消息
3. 点击右下角发送按钮（↑）

**方式 3：快速 OK**
1. 选中 Session（蓝色底条）
2. 点击右下角 OK 按钮
3. 自动发送 "OK"

**方式 4：语音输入**
1. 点击麦克风图标
2. 说话
3. 自动转为文字并发送

**方式 5：/new 快速发送** 
1. 选中 Session（底部蓝色底条）
2. 输入 `/new 消息内容`（例如：`/new 帮我写个 Python 脚本`）
3. 点击发送
4. 自动创建新 Session 并发送消息

### 3.2 管理多个对话

**创建 Session：**
- 点击顶部 `+` 按钮

**切换 Session：**
- 横向滚动
- 点击任意 Session

**查看 Session 详情：** 
- **iPhone：** 点击 NavigationBar 中间的对话名字按钮
- **iPad：** 点击 Session 列顶部的对话名字按钮
- **长按：** 弹出菜单（消息数量、最后活动时间、删除等）

**删除 Session：**
1. 点击对话名字按钮（或长按）
2. 选择 "Delete Session"

**拖拽排序：**
1. 点击顶部排序按钮（↕️）
2. 拖拽 Session 调整顺序
3. 点击 "Done" 保存

### 3.3 快速操作按钮

**位置：** 聊天界面右下角

| 按钮 | 图标 | 功能 | 显示条件 |
|------|------|------|---------|
| 滚动 | ↡ | 滚动到最新消息 | 始终显示 |
| OK | OK | 发送 "OK" | 选中时 |
| 发送 | ↑ | 发送输入框内容 | 选中时 |

**设计说明：**
- 快速操作按钮只在选中的 Session 显示
- 底部蓝色底条 = 当前选中的 Session
- 避免多个 Session 同时显示按钮

### 3.4 会话状态指示器 

**状态颜色：**
- 🟠 **橘黄色** = 处理中（AI 正在回复）
- 🟢 **绿色** = 有新消息（未读）
- 🔵 **蓝色** = 正常（已读）

**位置：**
- iPhone：NavigationBar 中间的对话名字按钮
- iPad：每个 Session 列顶部的对话名字按钮

**自动刷新：**
- 每 30 秒自动同步会话状态
- 确保状态始终准确
- 即使错过事件也能正确显示

---

## Cloudflare 多设备同步 {#cloudflare-sync} 

**功能说明：**
- 在多个设备间同步 Session 列表和顺序
- 完全免费，不需要 Apple 开发者账号
- 自动冲突解决（最新修改优先）

### 免费额度

| 操作 | 免费额度 | 实际使用 |
|------|---------|---------|
| 读取 | 10 万次/天 | 每天打开 10 次 = 够用 27 年 |
| 写入 | 1000 次/天 | 每天修改 100 次 = 够用 10 天 |
| 存储 | 1GB | 可存 50 万个 Session |

---

### 4.1 配置 Cloudflare（5 分钟搞定）

**步骤 1：注册 Cloudflare 账号**
1. 访问 https://dash.cloudflare.com/sign-up
2. 免费注册（不需要信用卡）
3. 验证邮箱

---

**步骤 2：创建 KV Namespace**
1. 登录 Cloudflare Dashboard
2. 左侧菜单：**Workers & Pages** → **KV**
3. 点击 **Create a namespace**
4. 命名：`openclaw-sessions`
5. 点击 **Add**

---

**步骤 3：获取 3 个关键信息**

| 信息 | 获取位置 | 示例 |
|------|---------|------|
| **Account ID** | Dashboard 首页右侧 | `abc123xyz...`（32 位） |
| **Namespace ID** | Workers & Pages → KV → 点击你的 namespace | `ns_xyz789...`（32 位） |
| **API Token** | 头像 → My Profile → API Tokens → Create Token | 见下方 |

**创建 API Token：**
1. 点击右上角头像 → **My Profile** → **API Tokens**
2. 点击 **Create Token**
3. 选择 **Edit Cloudflare Workers** 模板
4. 点击 **Continue to summary** → **Create Token**
5. **立即复制 Token**（只显示一次！）

---

**步骤 4：在 App 中配置**
1. 打开 OpenClaw Deck Swift
2. 进入 **设置**（⚙️）→ 滚动到 **Cloudflare KV 同步**
3. 填写配置：

| 字段 | 填写内容 |
|------|---------|
| **User ID** | 自定义唯一标识（推荐用邮箱） |
| **Account ID** | 步骤 3 获取 |
| **Namespace ID** | 步骤 3 获取 |
| **API Token** | 步骤 3 获取 |

4. 点击 **保存**（自动验证）

---

### 4.2 使用同步功能

**自动同步：**
- 每次 Session 列表变化时自动同步到云端
- 包括：创建、删除、排序

**手动同步：**
- 设置 → Cloudflare 同步
- 点击 "Sync Now" 按钮

**多设备使用：**
1. **设备 A**（例如 iPhone）：配置 Cloudflare，创建 Session
2. **设备 B**（例如 iPad）：配置**相同的 User ID**
3. 设备 B 启动时自动从云端加载 Session 列表

⚠️ **关键：** 多设备必须使用**相同的 User ID** 才能同步！

---

### 4.3 常见问题

#### Q: 测试连接失败？

**检查清单：**
- [ ] Account ID 是否正确（32 位字符）
- [ ] Namespace ID 是否正确（32 位字符）
- [ ] API Token 是否完整复制
- [ ] 网络连接是否正常

---

#### Q: 多设备不同步？

**解决方法：**
1. 检查多设备是否使用**相同的 User ID**
2. 在每个设备上点击 **测试连接**
3. 等待几秒让同步完成
4. 重启 App

---

#### Q: 同步冲突怎么办？

**什么是冲突：** 多个设备同时修改 Session 列表

**系统自动处理：**
- 大多数情况：自动合并，保留最新版本
- 无法自动解决时：弹窗让你选择（保留本地/使用云端）

**最佳实践：**
- ✅ 避免在多个设备上同时管理 Session
- ✅ 在一台设备上完成批量操作后再切换设备

---

#### Q: 如何清除配置？

**方法：**
1. 设置 → Cloudflare KV 同步
2. 点击 **清除配置**
3. 或者删除 App 重装

---

**安全说明：**
- 🔒 API Token 存储在系统 Keychain（加密）
- 🔒 只同步 Session 列表，不同步聊天内容
- 🔒 聊天内容存储在 Gateway/本地

---

## 故障排除 {#troubleshooting} 

### 5.1 连接问题

#### ❌ 无法连接 Gateway

**症状：**
- 显示 "连接失败"
- 状态指示器为红色

**检查步骤：**

1. **Gateway 是否启动？**
   ```bash
   ps aux | grep openclaw
   ```
   应该看到 `node` 进程

2. **地址是否正确？**
   - 默认：`ws://127.0.0.1:18789`
   - 检查大小写和空格

3. **端口是否被占用？**
   ```bash
   lsof -i :18789
   ```

**解决方法：**

1. **重启 Gateway**
   ```bash
   cd openclaw
   pnpm start
   ```

2. **检查防火墙**
   - 系统设置 → 网络 → 防火墙
   - 允许 Node.js 入站连接

3. **重启应用**
   - 完全退出（Cmd+Q）
   - 重新打开

---

#### ❌ 连接后断开

**症状：**
- 连接成功后突然断开
- 状态指示器变红

**可能原因：**
1. Gateway 崩溃
2. 网络不稳定
3. Token 过期

**解决方法：**

1. **检查 Gateway 日志**
   ```bash
   # 查看 Gateway 输出
   # 应该看到 "Server listening on port 18789"
   ```

2. **重新连接**
   - 点击 ⚙️ 设置
   - 点击 "Apply & Reconnect"

3. **检查 Token**
   - 如果 Gateway 需要认证
   - 在设置中重新输入 Token

---

#### ❌ Token 无效

**症状：**
- 显示 "认证失败"
- 无法建立连接

**解决方法：**

1. **检查 Token 格式**
   - 不应该有空格
   - 区分大小写

2. **重新生成 Token**
   ```bash
   cd openclaw
   openclaw token generate
   ```

3. **清除设备身份**
   - 设置 → Reset Device Identity
   - 重新输入 Token

---

### 4.2 发送失败

#### ❌ 消息发送失败

**症状：**
- 点击发送后无响应
- 消息不显示

**检查步骤：**

1. **是否已连接？**
   - 查看状态指示器（应为绿色）

2. **是否选中 Session？**
   - 底部应为蓝色底条

3. **输入框是否有内容？**
   - 空消息不会发送

**解决方法：**

1. **重新连接**
   - ⚙️ → Apply & Reconnect

2. **切换 Session**
   - 点击其他 Session
   - 再点击回来

3. **刷新页面**
   - Cmd+R 重新加载

---

#### ❌ 收不到回复

**症状：**
- 消息发送成功
- AI 没有回复

**可能原因：**
1. Gateway 配置问题
2. Agent 未启动
3. 网络延迟

**解决方法：**

1. **检查 Gateway 日志**
   ```bash
   # 查看 Gateway 输出
   # 应该看到 "Agent processing message..."
   ```

2. **等待 30 秒**
   - 可能是网络延迟
   - AI 正在生成回复

3. **重新发送**
   - 发送 "OK" 测试
   - 如果收到回复，说明正常

---

#### ❌ 重复发送

**症状：**
- 同一条消息发送多次
- AI 收到多条相同消息

**解决方法：**

1. **不要连续点击发送**
   - 点击一次后等待
   - 发送按钮会短暂禁用

2. **检查网络**
   - 网络不稳定可能导致重发
   - 使用稳定的网络连接

3. **重启应用**
   - 完全退出
   - 重新打开

---

### 5.4 Session 问题

#### ❌ Session 不显示

**症状：**
- 创建的 Session 不显示
- 列表为空

**解决方法：**

1. **横向滚动**
   - Session 可能在右侧
   - 左右滑动查看

2. **刷新连接**
   - ⚙️ → Apply & Reconnect
   - 重新加载 Session 列表

3. **创建新 Session**
   - 点击 `+` 创建
   - 如果成功，说明系统正常

---

#### ❌ 会话状态不更新

**症状：**
- 一直显示处理中（橘黄色）
- 状态长时间不变

**可能原因：**
1. 网络断开
2. Gateway 未响应
3. 状态同步失败

**解决方法：**

1. **检查连接**
   - 查看状态指示器（应为绿色）
   - 如果红色，重新连接

2. **等待自动同步**
   - 系统每 30 秒自动同步状态
   - 等待下一次同步

3. **手动刷新**
   - ⚙️ → Apply & Reconnect
   - 重新加载所有状态

---

---

#### ❌ 消息历史丢失

**症状：**
- 之前的消息不见了
- Session 是空的

**可能原因：**
1. 切换到不同 Session
2. Gateway 数据未加载
3. 本地缓存清除

**解决方法：**

1. **检查 Session Key**
   - 点击顶部菜单（⋮）
   - 查看 Session Key
   - 确认是正确的 Session

2. **重新加载**
   - ⚙️ → Apply & Reconnect
   - 从 Gateway 加载历史

3. **检查 Gateway**
   ```bash
   # 查看 Gateway 存储
   # 消息应该还在
   ```

---

#### ❌ 排序混乱

**症状：**
- Session 顺序错乱
- 拖拽后不保存

**解决方法：**

1. **重新排序**
   - 点击 ↕️ 排序按钮
   - 拖拽调整
   - 点击 "Done" 保存

2. **检查保存**
   - 关闭排序视图
   - 重新打开
   - 顺序应该保持

3. **清除缓存**
   - 完全退出应用
   - 重新打开

---

### 5.6 其他问题

#### ❌ 语音输入不工作

**症状：**
- 点击麦克风无响应
- 显示 "不可用"

**解决方法：**

1. **检查权限**
   - 系统设置 → 隐私与安全 → 麦克风
   - 允许应用访问麦克风

2. **检查设备**
   - 系统设置 → 声音 → 输入
   - 确认麦克风正常工作

3. **重启应用**
   - 完全退出
   - 重新打开

---

#### ❌ 应用崩溃

**症状：**
- 应用突然关闭
- 无法启动

**解决方法：**

1. **重启应用**
   - 完全退出（Cmd+Q）
   - 重新打开

2. **清除缓存**
   ```bash
   rm -rf ~/Library/Containers/Alex.openclaw-deck-swift
   ```

3. **重新编译**
   ```bash
   cd openclaw-deck-swift
   xcodebuild clean
   ```

4. **检查日志**
   ```bash
   # 查看系统日志
   log show --predicate 'process == "openclaw-deck-swift"' --last 1h
   ```

---

## 常见问题 {#faq}

### Q: Gateway 地址是什么？

**A:** 默认是 `ws://127.0.0.1:18789`

- 本地运行：`ws://127.0.0.1:18789`
- 远程服务器：`ws://服务器 IP:18789`

### Q: 需要 Token 吗？

**A:** 通常不需要。

- 本地 Gateway：不需要 Token
- 远程 Gateway：可能需要，咨询管理员

### Q: 消息存储在哪里？

**A:** 所有消息存储在 Gateway。

- 本地：只缓存当前显示的消息
- Gateway：永久存储所有消息
- 删除 Session：只删除本地显示，Gateway 仍保留

### Q: 支持多少个 Session？

**A:** 理论上无限制。

- 建议：10 个以内（便于管理）
- 性能：100 个以内流畅运行

### Q: 可以自定义 AI 吗？

**A:** 可以，在 Gateway 配置。

- OpenClaw 支持多种 Agent
- 参考：[OpenClaw 文档](https://docs.openclaw.ai)

### Q: 数据会同步吗？

**A:** 会，通过 Gateway 同步。

- 多设备登录同一 Gateway
- 消息自动同步
- Session 列表同步

### Q: 离线能用吗？

**A:** 不能。

- 必须连接 Gateway
- 所有计算在 Gateway 进行
- 本地只是界面

---

## 附录

### 系统要求

- **macOS:** 15.0+
- **iPadOS:** 18.0+
- **Xcode:** 16.0+（编译需要）

### 相关链接

- [GitHub 仓库](https://github.com/Alex-ai-future/openclaw-deck-swift)
- [OpenClaw 文档](https://docs.openclaw.ai)
- [技术架构](introduction.html)


---

## 📚 相关文档

- [使用样例](USAGE_EXAMPLES.html) - 实际场景示例
- [技术架构](introduction.html) - 开发者文档
- [隐私政策](PRIVACY.html) - 数据隐私说明
---
