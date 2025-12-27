import Foundation
import Twift
import SwiftUI
import Combine

@MainActor
class TwitterService: ObservableObject {
    static let shared = TwitterService()
    
    @Published var tweets: [XFlowTweet] = []
    @Published var isRunning: Bool = false
    @Published var errorMessage: String?
    
    private var client: Twift?
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Per-source last fetched ID to ensure incremental updates
    private var lastFetchedIdMap: [String: String] = [:]
    private var isFirstFetch = true
    private var currentKeyIndex = 0
    private init() {
        // Initialize if token exists
        let token = SettingsStore.shared.bearerToken
        if !token.isEmpty {
            self.client = Twift(appOnlyBearerToken: token)
        }
        
        // Observe settings changes to restart polling if necessary
        SettingsStore.shared.$updateInterval
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.handleSettingsChange() }
            .store(in: &cancellables)
            
        SettingsStore.shared.$updateUnit
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.handleSettingsChange() }
            .store(in: &cancellables)
            
        SettingsStore.shared.$rapidAPIKeys
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in 
                self?.handleSettingsChange() 
            }
            .store(in: &cancellables)
    }
    
    private func handleSettingsChange() {
        if isRunning {
            stopPolling()
            startPolling()
        }
    }
    
    func startPolling() {
        guard !isRunning else { return }
        
        let settings = SettingsStore.shared
        let hasRapidKey = !settings.activeRapidAPIKey.isEmpty
        let hasBearer = !settings.bearerToken.isEmpty
        
        // Refresh client from settings if Bearer is available
        if hasBearer {
            self.client = Twift(appOnlyBearerToken: settings.bearerToken)
        }
        
        // Ensure at least one service is configured
        guard hasRapidKey || client != nil else {
            errorMessage = "API Key not configured"
            return
        }
        
        isRunning = true
        errorMessage = nil
        isFirstFetch = true // Reset on manual start
        
        // Clear history for a fresh start
        self.tweets = []
        
        // Initial fetch
        Task {
            await fetchTweets()
        }
        
        // Poll with dynamic interval
        let interval = settings.updateIntervalSeconds
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchTweets()
            }
        }
    }
    
    func stopPolling() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func fetchTweets() async {
        let settings = SettingsStore.shared
        
        do {
            let allNewTweets = try await fetchSourceTweets(settings: settings)
            
            // Handle error message reset
            if errorMessage != nil && !allNewTweets.isEmpty {
                errorMessage = nil
            }
            
            // Apply advanced filters (Blue Verified, Followers)
            let filteredNewTweets = filterTweets(allNewTweets, settings: settings)
            
            // First deduplicate the new items from this fetch (across different sources)
            var seenIds = Set<String>()
            let uniqueNewInBatch = filteredNewTweets.filter { tweet in
                guard !seenIds.contains(tweet.id) else { return false }
                seenIds.insert(tweet.id)
                return true
            }

            // Then filter against existing stored tweets to avoid duplicates in the UI
            let uniqueNewTweets = uniqueNewInBatch.filter { newTweet in
                !self.tweets.contains(where: { $0.id == newTweet.id })
            }
            if !uniqueNewTweets.isEmpty {
                // Sort by creation date DESCENDING to get newest first
                var sortedTweets = uniqueNewTweets.sorted { 
                    ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast)
                }
                
                // If it's the first fetch, respect the initialCount strictly across all sources
                if isFirstFetch {
                    let limit = settings.initialCount
                    if sortedTweets.count > limit {
                        sortedTweets = Array(sortedTweets.prefix(limit))
                    }
                }
                
                // Update last fetchedIdMap with the newest tweet from this whole batch
                // (Note: Per-source tracking is also implemented in fetchSourceTweets)
                if let newest = sortedTweets.first {
                    lastFetchedIdMap["global"] = newest.id
                }
                
                // For danmaku display, we want to queue them oldest to newest
                let displayBatch = sortedTweets.reversed()
                self.tweets.append(contentsOf: displayBatch)
            }
            
            isFirstFetch = false
            
        } catch {
            if let apiError = error as? RapidAPIError {
                switch apiError {
                case .invalidKey, .quotaExhausted:
                    // Try to rotate key and retry once if we have more keys
                    if SettingsStore.shared.rotateToNextKey() {
                        print("[API] Key exhausted, rotated to next key")
                        await fetchTweets() // Retry
                        return
                    }
                default: break
                }
            }
            self.errorMessage = error.localizedDescription
        }
    }
    
    private func fetchSourceTweets(settings: SettingsStore) async throws -> [XFlowTweet] {
        if settings.apiType == .rapid {
            return try await fetchRapidAPITweets(settings: settings)
        } else {
            return try await fetchOfficialXAPITweets(settings: settings)
        }
    }
    
    private func fetchRapidAPITweets(settings: SettingsStore) async throws -> [XFlowTweet] {
        let rapidKey = settings.activeRapidAPIKey
        guard !rapidKey.isEmpty else {
            throw RapidAPIError.apiError("Please enter RapidAPI Key".localized())
        }
        
        let count = isFirstFetch ? settings.initialCount : 10
        var allTweets: [XFlowTweet] = []
        
        // User Handles
        if settings.useUserHandles {
            let userHandles = settings.userHandles
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                
            for handle in userHandles {
                let username = handle.hasPrefix("@") ? String(handle.dropFirst()) : handle
                let sourceKey = "rapid:user:\(username)"
                
                if username == "mock" {
                    let local = try await RapidAPIService.shared.loadLocalTweets()
                    allTweets.append(contentsOf: local)
                } else {
                    let userId = try await RapidAPIService.shared.getUserID(username: username, apiKey: rapidKey)
                    let fetched = try await RapidAPIService.shared.getUserTweets(userId: userId, apiKey: rapidKey, count: count)
                    if let newest = fetched.first {
                        lastFetchedIdMap[sourceKey] = newest.id
                    }
                    allTweets.append(contentsOf: fetched)
                }
            }
        }
        
        // Search
        if settings.useSearchQuery {
            let searchQuery = settings.searchQuery.trimmingCharacters(in: .whitespaces)
            if !searchQuery.isEmpty {
                let sourceKey = "rapid:search:\(searchQuery)"
                let fetched = try await RapidAPIService.shared.searchTweets(query: searchQuery, apiKey: rapidKey, count: count)
                if let newest = fetched.first {
                    lastFetchedIdMap[sourceKey] = newest.id
                }
                allTweets.append(contentsOf: fetched)
            }
        }
        
        // Lists
        if settings.useTwitterLists {
            let listIds = settings.twitterLists
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            for listId in listIds {
                let sourceKey = "rapid:list:\(listId)"
                let fetched = try await RapidAPIService.shared.getListTimeline(listId: String(listId), apiKey: rapidKey, count: count)
                if let newest = fetched.first {
                    lastFetchedIdMap[sourceKey] = newest.id
                }
                allTweets.append(contentsOf: fetched)
            }
        }
        
        // Communities
        if settings.useCommunities {
            let communityIds = settings.communities
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            for communityId in communityIds {
                let sourceKey = "rapid:community:\(communityId)"
                let fetched = try await RapidAPIService.shared.getCommunityTimeline(topicId: String(communityId), apiKey: rapidKey, count: count)
                if let newest = fetched.first {
                    lastFetchedIdMap[sourceKey] = newest.id
                }
                allTweets.append(contentsOf: fetched)
            }
        }
        
        return allTweets
    }

    private func fetchOfficialXAPITweets(settings: SettingsStore) async throws -> [XFlowTweet] {
        let apiKey = settings.officialApiKey.trimmingCharacters(in: .whitespaces)
        let apiSecret = settings.officialApiSecret.trimmingCharacters(in: .whitespaces)
        
        guard !apiKey.isEmpty && !apiSecret.isEmpty else {
            throw OfficialXAPIError.apiError("Please enter Official X API Key & Secret".localized())
        }
        
        let count = isFirstFetch ? settings.initialCount : 10
        var allTweets: [XFlowTweet] = []
        
        // User Handles
        if settings.useUserHandles {
            let userHandles = settings.userHandles
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                
            for handle in userHandles {
                let username = handle.hasPrefix("@") ? String(handle.dropFirst()) : handle
                let sourceKey = "official:user:\(username)"
                
                let userId = try await OfficialXAPIService.shared.getUserID(username: username, apiKey: apiKey, apiSecret: apiSecret)
                let fetched = try await OfficialXAPIService.shared.getUserTweets(userId: userId, apiKey: apiKey, apiSecret: apiSecret, count: count)
                if let newest = fetched.first {
                    lastFetchedIdMap[sourceKey] = newest.id
                }
                allTweets.append(contentsOf: fetched)
            }
        }
        
        // Lists
        if settings.useTwitterLists {
            let listIds = settings.twitterLists
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            for listId in listIds {
                let sourceKey = "official:list:\(listId)"
                let fetched = try await OfficialXAPIService.shared.getListTweets(listId: String(listId), apiKey: apiKey, apiSecret: apiSecret, count: count)
                if let newest = fetched.first {
                    lastFetchedIdMap[sourceKey] = newest.id
                }
                allTweets.append(contentsOf: fetched)
            }
        }
        
        // Search
        if settings.useSearchQuery {
            let searchQuery = settings.searchQuery.trimmingCharacters(in: .whitespaces)
            if !searchQuery.isEmpty {
                let sourceKey = "official:search:\(searchQuery)"
                let fetched = try await OfficialXAPIService.shared.searchRecent(query: searchQuery, apiKey: apiKey, apiSecret: apiSecret, count: count)
                if let newest = fetched.first {
                    lastFetchedIdMap[sourceKey] = newest.id
                }
                allTweets.append(contentsOf: fetched)
            }
        }
        
        // Home Timeline
        if settings.useHomeTimeline {
            let handle = settings.timelineHandle.trimmingCharacters(in: .whitespaces)
            if !handle.isEmpty {
                let accessToken = settings.officialAccessToken.trimmingCharacters(in: .whitespaces)
                let accessTokenSecret = settings.officialAccessTokenSecret.trimmingCharacters(in: .whitespaces)
                
                if accessToken.isEmpty || accessTokenSecret.isEmpty {
                    throw OfficialXAPIError.apiError("Home Timeline requires Access Token and Token Secret".localized())
                }
                
                let username = handle.hasPrefix("@") ? String(handle.dropFirst()) : handle
                let sourceKey = "official:timeline:\(username)"
                
                let userId = try await OfficialXAPIService.shared.getUserID(username: username, apiKey: apiKey, apiSecret: apiSecret)
                let fetched = try await OfficialXAPIService.shared.getReverseChronologicalTimeline(
                    userId: userId,
                    apiKey: apiKey,
                    apiSecret: apiSecret,
                    accessToken: accessToken,
                    accessTokenSecret: accessTokenSecret,
                    count: count
                )
                if let newest = fetched.first {
                    lastFetchedIdMap[sourceKey] = newest.id
                }
                allTweets.append(contentsOf: fetched)
            }
        }
        
        return allTweets
    }
    
    private func filterTweets(_ tweets: [XFlowTweet], settings: SettingsStore) -> [XFlowTweet] {
        // If master toggle is OFF, bypass all advanced filtering
        if !settings.isFiltersEnabled {
            return tweets
        }
        
        return tweets.filter { tweet in
            // Verified Filter
            if settings.filterVerified {
                if tweet.isVerified != true { return false }
            }
            
            // Follower Count Filter
            if settings.filterMinFollowersEnabled || settings.filterMaxFollowersEnabled {
                if let count = tweet.followersCount {
                    if settings.filterMinFollowersEnabled && count < settings.filterMinFollowers { return false }
                    if settings.filterMaxFollowersEnabled && count > settings.filterMaxFollowers { return false }
                } else {
                    // If we have a follower requirement but no count (e.g. mock), exclude it
                    return false
                }
            }
            
            return true
        }
    }
}
