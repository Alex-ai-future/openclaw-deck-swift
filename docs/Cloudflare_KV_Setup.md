# Cloudflare KV 多设备同步配置指南

## 📋 概述

使用 Cloudflare KV 实现 OpenClaw Deck Swift 的多设备 Session 同步，完全免费，不需要 Apple 开发者账号。

### 免费额度

| 操作 | 免费额度 | 实际使用 |
|------|---------|---------|
| 读取 | 10 万次/天 | 每天打开 10 次 = 够用 27 年 |
| 写入 | 1000 次/天 | 每天修改 100 次 = 够用 10 天 |
| 存储 | 1GB | 可存 50 万个 Session |

---

## 🔧 配置步骤

### 步骤 1：注册 Cloudflare 账号

1. 访问 https://dash.cloudflare.com/sign-up
2. 免费注册（不需要信用卡）
3. 验证邮箱

---

### 步骤 2：创建 KV Namespace

1. 登录 Cloudflare Dashboard
2. 左侧菜单：**Workers & Pages** → **KV**
3. 点击 **Create a namespace**
4. 命名：`openclaw-sessions`
5. 点击 **Add**

---

### 步骤 3：获取 Account ID

1. 在 Dashboard 首页右侧找到 **Account ID**
2. 点击复制按钮
3. 保存（后面要用）

---

### 步骤 4：获取 Namespace ID

1. 进入 **Workers & Pages** → **KV**
2. 点击你刚创建的 `openclaw-sessions`
3. 复制 **Namespace ID**
4. 保存（后面要用）

---

### 步骤 5：创建 API Token

1. 点击右上角头像 → **My Profile**
2. 切换到 **API Tokens** 标签
3. 点击 **Create Token**
4. 选择 **Edit Cloudflare Workers** 模板（或者自定义）
5. 权限配置：
   - **Account** → **Workers KV Storage** → **Edit**
6. 点击 **Continue to summary**
7. 点击 **Create Token**
8. **立即复制 Token**（只显示一次！）

---

### 步骤 6：在 App 中配置

1. 打开 OpenClaw Deck Swift
2. 进入 **设置** → **Cloudflare KV 同步**
3. 填写配置：

| 字段 | 填写内容 | 示例 |
|------|---------|------|
| **User ID** | 自定义唯一标识（推荐用邮箱） | `alex@example.com` |
| **Account ID** | 步骤 3 获取的 Account ID | `abc123xyz...` |
| **Namespace ID** | 步骤 4 获取的 Namespace ID | `ns_xyz789...` |
| **API Token** | 步骤 5 创建的 Token | `Bearer_xxxxx...` |

4. 点击 **测试连接** 验证配置
5. 点击 **保存**

---

## 🔄 同步逻辑

### 智能双向同步

- **App 启动时**：自动比较本地和云端数据，保留最新的
- **修改 Session 时**：自动同步到云端
- **多设备**：每个设备启动时自动同步

### 冲突处理

- 比较 `lastUpdated` 时间戳
- 总是保留最新的数据
- 自动同步到另一边

---

## 📱 多设备使用

### 设备 A（iPhone）

1. 配置 Cloudflare KV
2. 创建/修改 Session
3. 数据自动同步到云端

### 设备 B（iPad）

1. 配置相同的 Cloudflare KV（**相同的 User ID**）
2. App 启动时自动从云端加载
3. Session 列表与设备 A 一致

---

## ⚠️ 注意事项

1. **User ID 必须相同** - 多设备使用相同的 User ID 才能同步
2. **API Token 保密** - 只存储在本地 Keychain，不会上传
3. **网络依赖** - 同步需要网络连接，离线时使用本地数据
4. **首次同步** - 新设备首次启动会下载云端数据

---

## 🐛 故障排除

### 问题：测试连接失败

**检查清单：**
- [ ] Account ID 是否正确（32 位字符）
- [ ] Namespace ID 是否正确（32 位字符）
- [ ] API Token 是否完整复制
- [ ] 网络连接是否正常
- [ ] KV Namespace 是否已创建

### 问题：多设备不同步

**解决方法：**
1. 检查多设备是否使用**相同的 User ID**
2. 在每个设备上点击 **测试连接**
3. 等待几秒让同步完成
4. 重启 App

### 问题：清除配置

**方法：**
1. 设置 → Cloudflare KV 同步
2. 点击 **清除配置**
3. 或者删除 App 重装

---

## 🔒 安全说明

- **API Token** 存储在系统 Keychain（加密）
- **Session ID** 不敏感（只是标识符，不是聊天内容）
- **聊天内容** 存储在 Gateway/本地，不在 KV
- **Cloudflare** 有基础的 API 限流和监控

---

## 📚 技术实现

详见代码：
- `Services/CloudflareKV.swift` - 核心同步逻辑
- `Views/CloudflareSettingsView.swift` - 配置界面
- `ViewModels/DeckViewModel.swift` - 集成同步

---

**最后更新：** 2026-02-27
