import SwiftUI
import Combine

@MainActor
class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    
    // API Keys - using AppStorage to avoid Keychain password prompts
    @Published var rapidApiKey: String {
        didSet { UserDefaults.standard.set(rapidApiKey, forKey: "rapidApiKey") }
    }
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
    @AppStorage("initialCount") var initialCount: Int = 20
    
    // Filters
    @AppStorage("filterVerified") var filterVerified: Bool = false
    @AppStorage("filterMinFollowersEnabled") var filterMinFollowersEnabled: Bool = false
    @AppStorage("filterMinFollowers") var filterMinFollowers: Int = 0
    @AppStorage("filterMaxFollowersEnabled") var filterMaxFollowersEnabled: Bool = false
    @AppStorage("filterMaxFollowers") var filterMaxFollowers: Int = 1000000000
    
    // History
    @AppStorage("historySortNewest") var historySortNewest: Bool = true
    @AppStorage("isFiltersEnabled") var isFiltersEnabled: Bool = false
    
    // Update Frequency
    @Published var updateInterval: Double {
        didSet { UserDefaults.standard.set(updateInterval, forKey: "updateInterval") }
    }
    @Published var updateUnit: String { // s, m, h
        didSet { UserDefaults.standard.set(updateUnit, forKey: "updateUnit") }
    }
    
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
        let interval = UserDefaults.standard.double(forKey: "updateInterval")
        self.updateInterval = interval == 0 ? 30.0 : interval
        self.updateUnit = UserDefaults.standard.string(forKey: "updateUnit") ?? "s"
        self.rapidApiKey = UserDefaults.standard.string(forKey: "rapidApiKey") ?? ""
        
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
