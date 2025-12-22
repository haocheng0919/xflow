# Product Requirement Document (PRD): XFlow

| 项目信息 | 内容 |
| :--- | :--- |
| 产品名称 | XFlow |
| 版本 | v1.0 (Initial Release) |
| 平台 | macOS (Native App) |
| 开发语言 | Swift / SwiftUI |
| 开源协议 | MIT License |
| 核心理念 | 沉浸式信息流、高度定制化、Web3 交易辅助 |

## 1. 产品概述 (Product Overview)
XFlow 是一款 macOS 原生桌面应用，旨在利用屏幕空间提供“非侵入式”的 Twitter 信息流体验。它将推文以“弹幕 (Danmaku)”形式悬浮滚过屏幕，让用户无需切换窗口即可实时获取市场情报或社交动态。

**核心差异化：**
1.  **BYOK (Bring Your Own Key)**：纯客户端开源模式，用户管理自己的 API Key，无隐私担忧，无中心化订阅费。
2.  **Web3 交易增强**：原生集成合约地址 (CA) 识别，提供一键跳转 GMGN/Axiom 进行交易的能力。
3.  **极致视觉定制**：支持 Bento 风格的设置面板与 Vaporwave 美学的弹幕渲染。

## 2. 用户故事 (User Stories)
*   作为一名 Crypto 交易员，我希望在写代码或看K线时，屏幕上方能飘过我关注的 KOL 的最新推文，一旦出现新的合约地址 (CA)，我能点击直接跳转买入。
*   作为一名信息焦虑者，我希望无时无刻“刷推”，但不想频繁 Alt+Tab 切换窗口打断心流。
*   作为一名极客，我希望拥有一个开源的 Mac App，可以完全自定义字体、颜色和滚动速度，让我的桌面看起来很酷。

## 3. 功能需求 (Functional Requirements)

### 3.1 数据源与连接 (Data & Connection)
*   **API 配置 (BYOK)**：
    *   用户需在设置页输入 Twitter API Key / Bearer Token。
    *   支持设置自定义 Base URL（用于代理访问）。
    *   密钥需存储在 macOS Keychain 中，确保安全。
*   **多源支持 (Sources)**：用户可添加多个数据源，App 将轮询并在弹幕中混合展示：
    *   User Timeline：输入多个 Handle (e.g., @elonmusk, @donaldtrump)。
    *   List：输入 List ID。
    *   Community：输入 Community ID。
    *   Search：输入特定关键词或 Hashtag。
*   **获取策略**：
    *   冷启动回溯：点击“开始”时，获取过去 N 条推文（用户可设 0 - 50 条）。
    *   刷新频率：用户可设轮询间隔（例如：每 10s, 30s, 60s）。

### 3.2 弹幕渲染系统 (Danmaku Rendering)
*   **滚动逻辑**：
    *   文字从屏幕右侧生成，向左平滑滚动直至消失。
    *   防碰撞：自动计算轨道，尽量避免文字重叠。
*   **视觉定制 (Preferences)**：
    *   字体：支持系统字体及用户安装的自定义字体。
    *   字号：滑块调节 (12pt - 36pt)。
    *   颜色：支持自定义 HEX 颜色。
    *   透明度：整体透明度调节 (10% - 100%)。
    *   速度：像素/秒调节 (慢/正常/快/极速)。
*   **区域控制 (Zones)**：
    *   提供 Top / Middle / Bottom 三个复选框。
    *   用户可多选（例如：仅在 Top 和 Bottom 滚动，留出中间工作区）。
*   **密度与长度限制**：
    *   最大同屏数：限制屏幕上同时存在的弹幕数量。
    *   最大长度：超过 N 个字符自动截断（以省略号显示），防止长推文遮挡屏幕。

### 3.3 交互与智能悬停 (Interaction & Smart Hover)
*   **穿透模式 (Passthrough)**：
    *   默认情况下，鼠标点击弹幕之间的空白区域，事件应穿透 XFlow，直接作用于后方的应用（如浏览器、IDE）。
*   **智能悬停 (Smart Hover)**：
    *   当鼠标移动到某条弹幕文字上时：
        1.  暂停：该条弹幕立即停止滚动。
        2.  高亮：背景色加深或边框高亮。
        3.  展示全文：若内容被截断，悬浮 Popover 展示完整推文。
*   **点击动作**：
    *   点击弹幕文字：调用默认浏览器打开该条推文链接。
    *   点击 CA Logo：触发 Web3 交易跳转。

### 3.4 Web3 智能增强 (Crypto Features)
*   **CA 自动识别**：
    *   使用 Regex 自动检测推文中的 Solana 地址 (Base58) 和 EVM 地址 (0x...)。
*   **Logo 注入**：
    *   检测到 CA 后，在弹幕尾部自动追加 GMGN 或 Axiom 的微型 Logo 图标。
*   **自动路由**：
    *   在设置页，用户可选择默认交易终端（GMGN / Axiom / Photon 等）。
    *   点击 Logo 时，根据 CA 类型自动拼接 URL 并跳转（例如：`https://gmgn.ai/sol/token/[CA_ADDRESS]`）。

## 4. 用户界面设计 (UI/UX)

### 4.1 主控制面板 (Dashboard)
*   **风格**：Bento Grid (便当盒) 布局。模块化、圆角矩形卡片、清晰的层级。
*   **布局结构**：
    *   Grid 1 (Status)：当前运行状态（Running/Paused）、API 连通性指示灯。
    *   Grid 2 (Sources)：数据源列表管理（添加/删除/启用/禁用）。
    *   Grid 3 (Visuals)：字体、速度、透明度、区域的滑块与开关。
    *   Grid 4 (Web3)：CA 识别开关及首选交易平台选择。
    *   Grid 5 (History)：一个滚动的 List，按时间倒序展示抓取到的所有推文（用于回看）。

### 4.2 菜单栏图标 (Menu Bar Extra)
*   常驻 macOS 顶部菜单栏。
*   点击弹出下拉菜单：
    *   Toggle Start/Stop (开始/停止)。
    *   Quick Preset (快速切换预设：工作模式/摸鱼模式)。
    *   Open Dashboard (打开主面板)。
    *   Quit (退出)。

## 5. 技术架构 (Technical Architecture)

| 模块 | 技术选型 | 关键说明 |
| :--- | :--- | :--- |
| UI 框架 | SwiftUI | 构建 Bento 风格主面板，现代化且美观。 |
| 窗口管理 | AppKit (NSPanel) | NSPanel + .floating 层级 + clear 背景实现透明置顶。 |
| 交互核心 | HitTest Override | 重写 hitTest 方法，实现“鼠标穿透背景”但“拦截文字点击”。 |
| 网络层 | URLSession | 处理 Twitter API 请求。 |
| 数据存储 | SwiftData | 本地存储用户设置、API Key（加密字段）和历史推文。 |
| 动画引擎 | CoreAnimation | 保证弹幕滚动的 FPS 稳定，低 CPU 占用。 |

## 6. 开发路线图 (Roadmap)

### Phase 1: MVP (最小可行性产品)
* [ ] 完成 Twitter API (User Timeline) 的数据获取。
* [ ] 实现透明置顶窗口，支持简单的文字从右向左滚动。
* [ ] 实现“鼠标穿透”但“悬停暂停”的核心交互。
* [ ] 基础设置：API Key 输入、速度调节、透明度调节。

### Phase 2: Bento UI & 高级设置
* [ ] 设计并实现 Bento Grid 主面板。
* [ ] 增加多数据源支持 (Lists, Search)。
* [ ] 实现区域控制 (Top/Mid/Bot) 和字号颜色设置。
* [ ] 实现历史推文列表视图。

### Phase 3: Web3 Alpha
* [ ] 正则匹配 CA 逻辑。
* [ ] 自动注入 GMGN/Axiom Logo。
* [ ] 实现 URL Scheme 跳转交易。

## 7. 附录：非功能性需求
*   **性能**：后台运行时 CPU 占用率应低于 5%。
*   **安全**：绝不上传用户的 API Key 到任何服务器；所有请求直接从用户本机发往 Twitter。
*   **兼容性**：支持 macOS Sonoma (14.0) 及以上版本。

---

## 8. 技术实现参考 (Technical Implementation)

### 8.1 核心架构与窗口管理
*   **Transparent-Window**：NSPanel 子类，.borderless, .marketing, .nonactivatingPanel。
*   **LaunchAtLogin**：集成 LaunchAtLogin 库。
*   **KeyboardShortcuts**：全局快捷键支持。

### 8.2 数据获取
*   **Twift**：Recommended for Twitter API v2.
*   **Kingfisher**：Image caching.

### 8.3 弹幕渲染
*   **DanmakuKit** (iOS adapted) or **CoreAnimation**.

### 8.4 Web3
*   **Solana Regex**: `/[1-9A-HJ-NP-Za-km-z]{32,44}/g`
*   **EVM Regex**: `/^0x[a-fA-F0-9]{40}$/g`
