# 🌊 XFlow

**Immersive Twitter Danmaku for Your Desktop**

[English](#-overview) • [中文说明](#-概览)

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![Platform](https://img.shields.io/badge/Platform-macOS%2014%2B-lightgrey.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

---

## 🌌 Overview

XFlow transforms your Twitter feed into a **danmaku** (弹幕) experience—tweets float across your screen like video comments. Stay updated with real-time market signals, social updates, and crypto intel without breaking your workflow.

> [!TIP]
> **BYOK Model**: Bring Your Own Key. No subscription fees, no central server. Your data stays yours.

## 🚀 Key Features

- 📡 **Multi-Source Aggregation**: User handles, Lists, Communities, Search queries, and Home Timeline
- 🔑 **Multi-API Key Rotation**: Add multiple RapidAPI keys with automatic failover when one is exhausted
- 🐊 **Memecoin CA Detection**: Auto-detects Solana contract addresses and one-click jumps to [GMGN.ai](https://gmgn.ai)
- ✅ **Verified Badge Display**: Shows blue checkmarks for verified accounts
- 🎛️ **Bento-Style Dashboard**: Beautiful grid-based control panel
- ⚡ **Non-Intrusive**: Click-through background, hover to pause and inspect
- 🌐 **Bilingual UI**: English and 中文 interface

## 🛠️ Quick Start

### Prerequisites
- macOS 14.0 (Sonoma) or later
- Swift 5.9+ / Xcode 15+

### Installation

```bash
# Clone the repository
git clone https://github.com/haocheng0919/xflow.git
cd xflow

# Build and run
swift run
```

### Environment Setup (Optional)
Create a `.env` file to preload your API keys:

```bash
cp .env.example .env
```

```env
# RapidAPI (Recommended)
RAPIDAPI_KEY=your_key_here

# Or Official Twitter API
BEARER_TOKEN=your_bearer_token
```

## 🔑 Multi-Key Support

XFlow supports **multiple RapidAPI keys** with automatic rotation:

1. Click the **+** button next to "RapidAPI Keys" to add more keys
2. A green dot indicates the currently active key
3. When a key hits rate limits (429), XFlow automatically switches to the next key
4. Remove keys with the **-** button

> [!NOTE]
> Keys are stored locally in UserDefaults and never sent to any third-party server.

## 📜 License

MIT License - See [LICENSE](LICENSE) for details.

---

# 🌊 XFlow

**桌面沉浸式推特弹幕流**

[English](#-overview) • [中文说明](#-概览)

---

## 🌌 概览

XFlow 将你的 Twitter 信息流转化为**弹幕**体验——推文像视频评论一样飘过屏幕。实时获取市场信号、社交动态和加密货币情报，无需打断工作流程。

> [!TIP]
> **自带密钥模式 (BYOK)**：无订阅费，无中心服务器。你的数据由你掌控。

## 🚀 核心功能

- 📡 **多源聚合**：用户账号、列表、社区、搜索关键词、主页时间线
- 🔑 **多 API Key 轮换**：添加多个 RapidAPI 密钥，额度耗尽时自动切换
- 🐊 **Memecoin CA 检测**：自动识别 Solana 合约地址，一键跳转 [GMGN.ai](https://gmgn.ai) 分析
- ✅ **认证徽章显示**：蓝 V 认证账号清晰标识
- 🎛️ **Bento 风格仪表盘**：精美的网格化控制面板
- ⚡ **无干扰体验**：背景可穿透点击，悬停暂停查看详情
- 🌐 **双语界面**：English / 中文 随心切换

## 🛠️ 快速开始

### 系统要求
- macOS 14.0 (Sonoma) 或更高版本
- Swift 5.9+ / Xcode 15+

### 安装

```bash
# 克隆仓库
git clone https://github.com/haocheng0919/xflow.git
cd xflow

# 构建并运行
swift run
```

### 环境配置（可选）
创建 `.env` 文件预加载 API 密钥：

```bash
cp .env.example .env
```

```env
# RapidAPI（推荐）
RAPIDAPI_KEY=你的密钥

# 或 Twitter 官方 API
BEARER_TOKEN=你的 Bearer Token
```

## 🔑 多密钥支持

XFlow 支持**多个 RapidAPI 密钥**自动轮换：

1. 点击 "RapidAPI 密钥" 旁的 **+** 按钮添加更多密钥
2. 绿色圆点表示当前激活的密钥
3. 当密钥触发限流 (429)，XFlow 自动切换到下一个密钥
4. 使用 **-** 按钮移除密钥

> [!NOTE]
> 密钥存储在本地 UserDefaults，绝不会发送到任何第三方服务器。

## 📜 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE)