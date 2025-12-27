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
            
        SettingsStore.shared.$rapidApiKey
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.handleSettingsChange() }
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
        let hasRapidKey = !settings.rapidApiKey.isEmpty
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
            
            // First deduplicate the new items from this fetch (across different sources)
            var seenIds = Set<String>()
            let uniqueNewInBatch = allNewTweets.filter { tweet in
                guard !seenIds.contains(tweet.id) else { return false }
                seenIds.insert(tweet.id)
                return true
            }

            // Then filter against existing stored tweets
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
                    // For danmaku display, we want to queue them oldest to newest
                    sortedTweets = sortedTweets.reversed()
                } else {
                    // For incremental updates, we also queue oldest to newest
                    sortedTweets = sortedTweets.reversed()
                }
                
                self.tweets.append(contentsOf: sortedTweets)
            }
            
            isFirstFetch = false
            
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    private func fetchSourceTweets(settings: SettingsStore) async throws -> [XFlowTweet] {
        let rapidKey = settings.rapidApiKey
        let useRapidAPI = !rapidKey.isEmpty
        let count = isFirstFetch ? settings.initialCount : 10
        
        var allTweets: [XFlowTweet] = []
        let userHandles = settings.userHandles
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            
        // User Handles
        for handle in userHandles {
            let username = handle.hasPrefix("@") ? String(handle.dropFirst()) : handle
            if username == "mock" {
                allTweets.append(contentsOf: try await RapidAPIService.shared.loadLocalTweets())
            } else if useRapidAPI {
                let userId = try await RapidAPIService.shared.getUserID(username: username, apiKey: rapidKey)
                allTweets.append(contentsOf: try await RapidAPIService.shared.getUserTweets(userId: userId, apiKey: rapidKey, count: count))
            }
        }
        
        // Search
        let searchQuery = settings.searchQuery.trimmingCharacters(in: .whitespaces)
        if !searchQuery.isEmpty && useRapidAPI {
            allTweets.append(contentsOf: try await RapidAPIService.shared.searchTweets(query: searchQuery, apiKey: rapidKey, count: count))
        }
        
        // Lists
        let listIds = settings.twitterLists
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        for listId in listIds {
            if useRapidAPI {
                allTweets.append(contentsOf: try await RapidAPIService.shared.getListTimeline(listId: String(listId), apiKey: rapidKey, count: count))
            }
        }
        
        // Communities
        let communityIds = settings.communities
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        for communityId in communityIds {
            if useRapidAPI {
                allTweets.append(contentsOf: try await RapidAPIService.shared.getCommunityTimeline(topicId: String(communityId), apiKey: rapidKey, count: count))
            }
        }
        
        return allTweets
    }
}
