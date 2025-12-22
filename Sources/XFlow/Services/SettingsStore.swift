import SwiftUI
import Combine

@MainActor
class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    
    // API Keys - using AppStorage to avoid Keychain password prompts
    @AppStorage("rapidApiKey") var rapidApiKey: String = ""
    @AppStorage("bearerToken") var bearerToken: String = ""
    
    @AppStorage("danmakuSpeed") var speed: Double = 3.0
    @AppStorage("danmakuOpacity") var opacity: Double = 1.0
    @AppStorage("danmakuSize") var fontSize: Double = 20.0
    @AppStorage("showTop") var showTop: Bool = true
    @AppStorage("showMiddle") var showMiddle: Bool = true
    @AppStorage("showBottom") var showBottom: Bool = true
    @AppStorage("isCryptoEnabled") var isCryptoEnabled: Bool = false
    @AppStorage("selectedDex") var selectedDex: String = "GMGN"
    @AppStorage("maxItemWidth") var maxItemWidth: Double = 400.0
    
    // Update Frequency
    @AppStorage("updateInterval") var updateInterval: Double = 30.0
    @AppStorage("updateUnit") var updateUnit: String = "s" // s, m, h
    
    var updateIntervalSeconds: TimeInterval {
        switch updateUnit {
        case "m": return updateInterval * 60
        case "h": return updateInterval * 3600
        default: return updateInterval
        }
    }
    
    // Multi-Source Data
    @AppStorage("userHandles") var userHandles: String = "" // comma-separated, NO DEFAULT
    @AppStorage("twitterLists") var twitterLists: String = "" // comma-separated
    @AppStorage("communities") var communities: String = "" // comma-separated
    @AppStorage("searchQuery") var searchQuery: String = ""
    
    private init() {
        // Load from environment if available
        if let envToken = ProcessInfo.processInfo.environment["BEARER_TOKEN"], !envToken.isEmpty {
            if bearerToken.isEmpty {
                bearerToken = envToken
            }
        }
        if let envRapidKey = ProcessInfo.processInfo.environment["RAPIDAPI_KEY"], !envRapidKey.isEmpty {
            if rapidApiKey.isEmpty {
                rapidApiKey = envRapidKey
            }
        }
    }
}
