import SwiftUI

enum Language: String, CaseIterable, Identifiable {
    case en = "en"
    case zh = "zh"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .en: return "English"
        case .zh: return "中文"
        }
    }
    
    var localized: String {
        switch self {
        case .en: return "English"
        case .zh: return "中文"
        }
    }
}

struct Strings {
    static func localized(_ key: String, lang: String) -> String {
        let isZh = lang == "zh"
        
        switch key {
        // Status
        case "Running": return isZh ? "运行中" : "Running"
        case "Paused": return isZh ? "已暂停" : "Paused"
        case "API Connection": return isZh ? "API 连接" : "API Connection"
        case "Error": return isZh ? "错误" : "Error"
        case "Not Configured": return isZh ? "未配置" : "Not Configured"
        case "Connected": return isZh ? "已连接" : "Connected"
        case "Update Frequency": return isZh ? "更新频率" : "Update Frequency"
        case "Connection Status": return isZh ? "连接状态" : "Connection Status"
        case "Stopped": return isZh ? "已停止" : "Stopped"
        case " (With Errors)": return isZh ? " (包含错误)" : " (With Errors)"
        case "All systems nominal": return isZh ? "系统运行正常" : "All systems nominal"
        case "MultiKeyStatus": return isZh ? "正在按顺序使用 %d 个密钥" : "Using %d keys sequentially"
        case "Please enter RapidAPI Key": return isZh ? "请输入 RapidAPI 密钥" : "Please enter RapidAPI Key"
        case "RapidAPI": return "RapidAPI"
        case "Official": return isZh ? "官方接口" : "Official X API"
        case "API Service Provider": return isZh ? "API 服务商" : "API Service"
        
        // Menu & Panel
        case "Stop Flow": return isZh ? "停止流水" : "Stop Flow"
        case "Start Flow": return isZh ? "开始流水" : "Start Flow"
        case "Dashboard": return isZh ? "仪表盘" : "Dashboard"
        case "Quit": return isZh ? "退出" : "Quit"
        case "XFlow Dashboard": return isZh ? "XFlow 仪表盘" : "XFlow Dashboard"
        case "s": return isZh ? "秒" : "s"
        case "m": return isZh ? "分" : "m"
        case "h": return isZh ? "时" : "h"
        
        // Visuals
        case "Visuals": return isZh ? "视觉设置" : "Visuals"
        case "Speed": return isZh ? "弹幕速度" : "Speed"
        case "Opacity": return isZh ? "透明度" : "Opacity"
        case "Size": return isZh ? "文字大小" : "Size"
        case "Max Width": return isZh ? "最大宽度" : "Max Width"
        case "Initial Count": return isZh ? "初始数量" : "Initial Count"
        case "Display Zones": return isZh ? "显示区域" : "Display Zones"
        case "Top": return isZh ? "顶部" : "Top"
        case "Mid": return isZh ? "中部" : "Mid"
        case "Bot": return isZh ? "底部" : "Bot"
        
        // Web3
        case "Web3": return isZh ? "Web3 支持" : "Web3"
        case "DEX": return isZh ? "去中心化交易所" : "DEX"
        case "Auto-detects CAs": return isZh ? "自动检测 Solana & EVM 合约" : "Auto-detects Solana & EVM CAs"
        
        // Data Sources
        case "Data Sources": return isZh ? "数据源" : "Data Sources"
        case "RapidAPI Key": return isZh ? "RapidAPI 密钥" : "RapidAPI Key"
        case "User Handles": return isZh ? "用户账号" : "User Handles"
        case "Token Warning": return isZh ? "⚠️ 每个账号消耗1个额度" : "⚠️ 1 token per handle"
        case "Handle Info": return isZh ? "以英文逗号分隔的推特账号" : "Comma-separated user handles"
        case "Please enter handles": return isZh ? "请输入推特账号" : "Please enter handles"
        case "Twitter Lists": return isZh ? "推特列表 (IDs)" : "Twitter Lists (IDs)"
        case "List Token Warning": return isZh ? "⚠️ 每个列表消耗1个额度" : "⚠️ 1 token per list"
        case "List Info": return isZh ? "请输入推特列表 ID" : "Enter Twitter List IDs"
        case "Please enter List IDs": return isZh ? "请输入列表 ID" : "Please enter List IDs"
        case "Communities": return isZh ? "推特社群 (IDs)" : "Communities (IDs)"
        case "Comm Token Warning": return isZh ? "⚠️ 每个社群消耗1个额度" : "⚠️ 1 token per community"
        case "Comm Info": return isZh ? "请输入推特社群 ID" : "Enter Twitter Community IDs"
        case "Please enter Community IDs": return isZh ? "请输入社群 ID" : "Please enter Community IDs"
        case "Search Query": return isZh ? "搜索关键词" : "Search Query"
        case "Please enter search query": return isZh ? "请输入搜索词" : "Please enter search query"
        case "Official X API Token": return isZh ? "官方 X API 令牌" : "Official X API Token"
        case "OfficialTokenInfo": return isZh ? "输入 API 密钥和密匙；Timeline 需要用户令牌" : "Enter API Key & Secret; Timeline needs User Token"
        case "Home Timeline": return isZh ? "个人主页流" : "Home Timeline"
        case "Please enter Official X API Token": return isZh ? "请输入官方 X API 令牌" : "Please enter Official X API Token"
        case "Unauthorized Error": return isZh ? "授权失败：请检查你的令牌或密钥" : "Unauthorized: Check your tokens/keys"
        case "Forbidden Error": return isZh ? "权限拒绝 (403)：%@" : "Forbidden (403): %@"
        case "Rate Limit Error": return isZh ? "X API 达到速率限制" : "X API Rate Limit Exceeded"
        case "Not Found Error": return isZh ? "%@ 未找到" : "%@ not found"
        case "Home Timeline requires Access Token and Token Secret": return isZh ? "主页流需要访问令牌 (Access Token) 和密匙 (Token Secret)" : "Home Timeline requires Access Token and Token Secret"
        case "Unauthorized: Check your tokens/keys": return isZh ? "授权失败：请检查你的 Token 或 Key" : "Unauthorized: Check your tokens/keys"
        case "Forbidden (403): ": return isZh ? "权限拒绝 (403)：" : "Forbidden (403): "
        case "X API Rate Limit Exceeded": return isZh ? "X API 达到速率限制" : "X API Rate Limit Exceeded"
        case "X API Error": return isZh ? "X API 错误" : "X API Error"
        case "Official API Key": return isZh ? "官方 API 密钥 (Key)" : "Official API Key"
        case "Official API Secret": return isZh ? "官方 API 密匙 (Secret)" : "Official API Secret"
        case "Access Token": return isZh ? "访问令牌 (Access Token)" : "Access Token"
        case "Access Token Secret": return isZh ? "访问令牌密匙 (Token Secret)" : "Access Token Secret"
        case "Timeline Auth (OAuth 1.0a)": return isZh ? "Timeline 认证 (OAuth 1.0a)" : "Timeline Auth (OAuth 1.0a)"
        case "Please enter Official X API Key & Secret": return isZh ? "请输入官方 API 密钥和密匙" : "Please enter Official X API Key & Secret"
        case "Home Timeline requires User Access Token": return isZh ? "主页流需要用户访问令牌" : "Home Timeline requires User Access Token"
        
        // Filters
        case "Advanced Filters": return isZh ? "高级筛选" : "Advanced Filters"
        case "Only Verified": return isZh ? "仅显示认证账号" : "Only Verified"
        case "Force Verified Mock": return isZh ? "强制显示认证标识 (Mock)" : "Force Verified Mock"
        case "Follower Filter": return isZh ? "粉丝数筛选" : "Follower Count Filter"
        case "Min": return isZh ? "最小" : "Min"
        case "Max": return isZh ? "最大" : "Max"
        
        // History
        case "History": return isZh ? "历史记录" : "History"
        case "Newest First": return isZh ? "最新优先" : "Newest First"
        case "Oldest First": return isZh ? "最早优先" : "Oldest First"
        case "tweets": return isZh ? "条推文" : "tweets"
        case "Click Info": return isZh ? "点击推文在 Chrome 中打开" : "Click a tweet to open in Chrome"
        
        // Language
        case "Language": return isZh ? "语言设置" : "Language"
        
        // Web3 Buttons
        case "Axiom": return "Axiom"
        case "GMGN": return "GMGN"
        case "Memecoin CA": return isZh ? "Memecoin CA" : "Memecoin CA"
        
        default: return key
        }
    }
}

extension String {
    func localized() -> String {
        let lang = UserDefaults.standard.string(forKey: "language") ?? "en"
        return Strings.localized(self, lang: lang)
    }
}

// Optimization: Pre-cache assets to avoid disk I/O in render loops
@MainActor
enum AppAssets {
    static let verifiedBadge: NSImage? = {
        if let url = Bundle.module.url(forResource: "verified_badge", withExtension: "webp") {
            return NSImage(contentsOf: url)
        }
        if let url = Bundle.module.url(forResource: "verified_badge", withExtension: "png") {
            return NSImage(contentsOf: url)
        }
        return nil
    }()
    
    static let gmgnLogo: NSImage? = {
        if let url = Bundle.module.url(forResource: "gmgn_logo", withExtension: "webp") {
            return NSImage(contentsOf: url)
        }
        if let url = Bundle.module.url(forResource: "gmgn_logo", withExtension: "png") {
            return NSImage(contentsOf: url)
        }
        return nil
    }()
}
