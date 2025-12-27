<div align="center">
  <img src="assets/icon.png" width="128" height="128" alt="XFlow Icon" />
  <h1>XFlow</h1>
  <p>
    <strong>A Desktop Floating Danmaku Client for X (Twitter)</strong>
  </p>
  <p>
    Turn your desktop into a real-time information stream. <br/>
    Monitor Crypto Trends, KOLs, and News without switching windows.
  </p>

  <p>
    <a href="#-english">English</a> • <a href="#-中文">中文</a>
  </p>

  <img src="assets/github_readme.gif" alt="XFlow Demo" width="800" />
</div>

<hr />

<h2 id="-english">🍃 English</h2>

**XFlow** is a native macOS application that displays real-time tweets as floating "Danmaku" (bullet comments) on your screen. It is designed for crypto traders, researchers, and power users who need to stay updated without interrupting their workflow.

### ✨ Key Features

| Feature | Description |
| :--- | :--- |
| **🌊 Floating Danmaku** | Tweets fly across your screen as non-intrusive overlays. Click-through by default, interactive on hover. |
| **🚀 Multi-Source** | Aggregate data from **User Handles**, **Twitter Lists**, **Communities**, and **Search Queries**. |
| **💎 Web3 Integration** | Auto-detects **Solana & EVM** contract addresses (CAs). One-click redirect to **GMGN**, **DexScreener**, etc. |
| **🔑 Smart API** | Supports **Official X API** and **RapidAPI**. Built-in **Key Rotation** system to bypass rate limits automatically. |
| **🧹 Smart Filters** | Filter by **Verified Blue Badge**, **Follower Count**, and **Deduplication** (never see the same tweet twice). |
| **🎨 Customization** | Adjust speed, opacity, font size, and display zones (Top/Mid/Bot) to fit your setup. |

### 🛠 Installation

1.  Download the latest `.zip` from the [Releases](https://github.com/haochengwang/xflow/releases) page.
2.  Unzip and drag `XFlow.app` to your **Applications** folder.
3.  Launch the app. look for the **X** icon in your menu bar.

### ⚙️ Configuration

XFlow supports two data sources. You can configure them in the **Dashboard**.

#### Option A: RapidAPI (Recommended for cheap/free access)
1.  Go to [RapidAPI](https://rapidapi.com/) and subscribe to a Twitter API service (e.g., *Twitter Data API*).
2.  Copy your `X-RapidAPI-Key`.
3.  In XFlow Dashboard, select **RapidAPI**.
4.  Paste your key. You can add **multiple keys**; XFlow will automatically rotate to the next key if one is exhausted.

#### Option B: Official X API
1.  Apply for access at the [X Developer Portal](https://developer.twitter.com/).
2.  Enter your `API Key` and `API Secret`.
3.  (Optional) Enter `Access Token` and `Secret` for Home Timeline support.

### 🧩 Web3 Features
*   **Ca Detection**: XFlow automatically scans every tweet for contract addresses (e.g., `$PIMP`, `0x...`).
*   **Quick Trade**: When a CA is found, a **GMGN logo** (or text) appears on the danmaku. Clicking it opens the chart directly.
*   **Vanity Support**: Supports standard addresses and vanity addresses (e.g., ending in `pump`).

---

<h2 id="-中文">🐼 中文</h2>

**XFlow** 是一款 macOS 桌面应用，它将 X (Twitter) 的实时推文以“弹幕”的形式悬浮展示在屏幕上。专为加密货币交易者、投研人员和极客设计，让你在专注于工作的同时不错过任何重要信息。

### ✨ 核心功能

| 功能 | 说明 |
| :--- | :--- |
| **🌊 桌面弹幕** | 推文像弹幕一样飞过屏幕。默认鼠标穿透，不影响工作；悬停即可交互。 |
| **🚀 多源聚合** | 支持同时监控 **用户**, **列表 (Lists)**, **社群 (Communities)** 和 **搜索关键词**。 |
| **💎 Web3 集成** | 自动识别推文中的 **Solana & EVM** 合约地址 (CA)。一键直达 **GMGN** K线图。 |
| **🔑 智能 API** | 支持 **官方 X API** 和 **RapidAPI**。内置 **多密钥轮询**，自动处理速率限制，永不掉线。 |
| **🧹 智能过滤** | 支持过滤 **蓝标认证**, **粉丝数量**，并且拥有智能 **去重机制**，拒绝垃圾信息。 |
| **🎨 高度定制** | 调节速度、透明度、字体大小以及显示区域（顶部/中部/底部），完美融入你的桌面。 |

### 🛠 安装指南

1.  在 [Releases](https://github.com/haochengwang/xflow/releases) 页面下载最新的 `.zip` 压缩包。
2.  解压并将 `XFlow.app` 拖入 **应用程序 (Applications)** 文件夹。
3.  启动应用，在顶部菜单栏找到 **X** 图标即可使用。

### ⚙️ 配置说明

XFlow 支持两种数据源，请在 **仪表盘 (Dashboard)** 中配置。

#### 方案 A: RapidAPI (推荐，成本低)
1.  前往 [RapidAPI](https://rapidapi.com/) 订阅任意 Twitter API 服务。
2.  复制你的 `X-RapidAPI-Key`。
3.  在 XFlow 仪表盘选择 **RapidAPI**。
4.  粘贴密钥。支持添加 **多个密钥**，当一个密钥额度耗尽时，XFlow 会自动切换到下一个。

#### 方案 B: 官方 X API
1.  在 [X Developer Portal](https://developer.twitter.com/) 申请开发者权限。
2.  输入 `API Key` 和 `API Secret`。
3.  (可选) 输入 `Access Token` 和 `Secret` 以支持获取“推荐/关注”流。

### 🧩 Web3 特性
*   **合约检测**: 自动扫描每条推文中的代币合约 (如 `$PIMP`, `0x...`)。
*   **极速看线**: 识别到 CA 后，弹幕上会显示 **GMGN 按钮**，点击直接跳转对应 K 线。
*   **Vanity 支持**: 完美支持各类 Solana 地址格式（如以 `pump` 结尾的地址）。


