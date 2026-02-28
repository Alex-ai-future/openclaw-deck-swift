# OpenClaw Deck Swift - 用户指南

**版本：** 1.5  
**最后更新：** 2026-02-28  
**适用平台：** macOS, iPadOS, iOS (iPhone, iPad, iPod touch)

---

## 目录

1. [5 分钟快速上手](#1-5-分钟快速上手)
2. [iOS 设备连接 Gateway](#2-ios-设备连接-gateway) ⭐⭐⭐⭐⭐
3. [核心功能](#3-核心功能)
4. [Cloudflare 多设备同步](#4-cloudflare-多设备同步) ⭐ NEW
5. [故障排除](#5-故障排除) ⭐⭐⭐⭐⭐
6. [常见问题](#6-常见问题)

---

## 1. 5 分钟快速上手

### 1.1 安装

```bash
cd ~/Projects
git clone https://github.com/Alex-ai-future/openclaw-deck-swift.git
open openclaw-deck-swift/openclaw-deck-swift.xcodeproj
# Xcode 中 Cmd+R 运行
```

### 1.2 配置 Gateway

**OpenClaw Deck Swift 需要连接 OpenClaw Gateway 才能工作。**

**步骤 1：安装 Gateway**

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

## 2. iOS 设备连接 Gateway ⭐⭐⭐⭐⭐

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

## 3. 核心功能

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

**方式 5：/new 快速发送** ⭐ NEW
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

**查看 Session 详情：** ⭐ NEW
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

### 3.4 会话状态指示器 ⭐ NEW

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

## 4. Cloudflare 多设备同步 ⭐ NEW

**功能说明：**
- 在多个设备间同步 Session 列表和顺序
- 自动冲突解决（最新修改优先）
- 支持手动同步

### 4.1 配置 Cloudflare KV

**前提条件：**
- Cloudflare 账号（免费）
- 已创建 KV Namespace

**步骤：**

1. **获取 Cloudflare 凭证**
   - Account ID：Cloudflare Dashboard → 概述
   - KV Namespace ID：Workers & Pages → KV → 命名空间 ID
   - API Token：用户个人资料 → API 令牌 → 创建令牌（编辑 Cloudflare KV 权限）

2. **在应用中配置**
   - 打开应用 → 设置（⚙️）
   - 滚动到 "Cloudflare 同步" 部分
   - 输入 Account ID、Namespace ID、API Token
   - 开启同步开关

3. **验证配置**
   - 配置后自动保存
   - 状态显示 "已配置"

---

### 4.2 使用同步功能

**自动同步：**
- 每次 Session 列表变化时自动同步
- 包括：创建、删除、排序

**手动同步：**
- 设置 → Cloudflare 同步
- 点击 "Sync Now" 按钮
- 等待同步完成提示

**多设备使用：**
1. 设备 A：配置 Cloudflare，创建 Session
2. 设备 B：配置相同 Cloudflare，开启同步
3. 自动加载设备 A 的 Session 列表

---

### 4.3 同步冲突解决

**什么是同步冲突？**

当多个设备同时修改 Session 列表时，会产生冲突。例如：
- 设备 A 创建了新 Session
- 设备 B 同时删除了另一个 Session
- 两个设备几乎同时同步到 Cloudflare

**冲突解决原理：**

1. **自动合并（大多数情况）**
   - 系统会比较本地和云端的时间戳
   - 最新修改优先
   - Session 列表自动合并（不会丢失任何 Session）

2. **冲突弹窗（无法自动解决时）**
   - 当系统无法确定哪个版本更新
   - 会显示同步冲突弹窗
   - 你可以选择：
     - **保留本地版本** - 使用当前设备的 Session 列表
     - **使用云端版本** - 从 Cloudflare 下载其他设备的列表
     - **手动合并** - 稍后手动调整

3. **Session 内容不受影响**
   - Cloudflare 只同步 Session 列表和顺序
   - 消息内容始终存储在 Gateway
   - 无论选择哪个版本，聊天记录都不会丢失

**最佳实践：**
- ✅ 避免在多个设备上同时管理 Session
- ✅ 在一台设备上完成批量操作后再切换设备
- ✅ 定期手动同步确保一致性

**注意：**
- Cloudflare 只同步 Session 列表和顺序
- 消息内容存储在 Gateway，不受影响

---

## 5. 故障排除 ⭐⭐⭐⭐⭐

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

## 6. 常见问题

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
- [技术架构](introduction.md)

---

**需要帮助？** 提交 Issue: [GitHub Issues](https://github.com/Alex-ai-future/openclaw-deck-swift/issues)
