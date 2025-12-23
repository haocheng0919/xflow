# XFlow

**您的桌面沉浸式信息流。**

XFlow 是一款 macOS 原生应用程序，它将 Twitter/X 动态以“弹幕”形式直接呈现在您的桌面上。它让您可以在不打断工作流程的情况下，保持对实时市场情报、社交动态和加密货币信号的关注。

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![Platform](https://img.shields.io/badge/Platform-macOS%2014%2B-lightgrey.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

## 功能特性

- **BYOK (自带密钥)**：您掌控自己的数据。无订阅费，无中心化服务器。通过 RapidAPI 或官方 Twitter API 直接连接 Twitter。
- **非侵入式弹幕**：推文像视频评论流一样漂浮在您的屏幕上。
    - **智能悬停**：鼠标悬停在推文上可暂停并查看详情。
    - **点击穿透**：点击文字背景区域可与后方的窗口进行交互。
- **Web3 增强**：自动检测 Solana 和 EVM 链的合约地址 (CA)。
    - 一键跳转至 GMGN, Axiom, 或 Photon 等交易终端。
- **Bento 风格仪表盘**：美观的网格化控制面板，用于管理来源和设置。
- **高度可定制**：调整速度、透明度、字体和屏幕区域（顶部/中部/底部）。

## 安装

###以此为前提
- macOS 14.0 (Sonoma) 或更高版本。
- Xcode 15+ (如果需要从源码构建)。

### 从源码构建
1. 克隆仓库：
   ```bash
   git clone https://github.com/haocheng0919/xflow.git
   cd xflow
   ```

2. 在 Xcode 中打开项目或通过 swift 构建：
   ```bash
   swift build -c release
   ```

3. 运行应用程序：
   ```bash
   swift run
   ```

## 配置

XFlow 使用 **BYOK (自带密钥)** 模式。您需要 API 访问权限来获取推文。

### 1. 环境设置 (推荐)
在根目录下创建一个 `.env` 文件来预加载您的密钥：

```bash
cp .env.example .env
```

编辑 `.env` 并添加您的密钥：
```env
# 选项 1: RapidAPI (推荐，成本低/易用)
RAPIDAPI_KEY=your_rapidapi_key_here

# 选项 2: Twitter 官方 API
BEARER_TOKEN=your_twitter_bearer_token_here
```

### 2. 仪表盘设置
或者，您也可以直接在应用仪表盘的“Inputs & Keys”下输入您的密钥。

## 使用方法

- **仪表盘**：点击菜单栏中的仪表盘按钮或使用全局快捷键（默认：`,`）打开设置网格。
- **来源**：添加 Twitter 列表、用户句柄或搜索查询（例如，"$BTC", "#SwiftUI"）。
- **控制**：从菜单栏切换信息流的 开始/停止。

## 安全性

- **本地执行**：所有逻辑都在您的机器上本地运行。
- **密钥安全**：API 密钥存储在您的本地 UserDefaults 中（或运行时从 `.env` 加载），除了 API 提供商 (Twitter/RapidAPI) 外，绝不会发送到任何第三方服务器。

## 许可证

本项目基于 MIT 许可证开源。
