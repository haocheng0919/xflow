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
        let rapidKey = settings.rapidApiKey
        let useRapidAPI = !rapidKey.isEmpty
        
        var allNewTweets: [XFlowTweet] = []
        
        // Parse multi-source inputs
        let userHandles = settings.userHandles
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        let searchQuery = settings.searchQuery.trimmingCharacters(in: .whitespaces)
        
        do {
            // 1. Fetch from User Handles
            for handle in userHandles {
                let username = handle.hasPrefix("@") ? String(handle.dropFirst()) : handle
                
                if username == "mock" {
                    let mockTweets = try await RapidAPIService.shared.loadLocalTweets()
                    allNewTweets.append(contentsOf: mockTweets)
                    continue
                }
                
                if useRapidAPI {
                    // RapidAPI Path
                    let userId = try await RapidAPIService.shared.getUserID(username: username, apiKey: rapidKey)
                    let tweets = try await RapidAPIService.shared.getUserTweets(userId: userId, apiKey: rapidKey, count: settings.tweetLimit)
                    allNewTweets.append(contentsOf: tweets)
                } else {
                    // Twift Path
                    guard let client = client else {
                        errorMessage = "Twitter Bearer Token Missing"
                        continue
                    }
                    
                    let userResponse = try await client.getUserBy(username: username)
                    let userId = userResponse.data.id
                    
                    let response = try await client.userTimeline(
                        userId,
                        fields: [\.createdAt, \.authorId, \.text],
                        expansions: [
                            .authorId(userFields: [\.name, \.username, \.profileImageUrl])
                        ],
                        maxResults: 10
                    )
                    
                    let tweets = response.data.map { tweet in
                        var xTweet = XFlowTweet(from: tweet)
                        if let authorId = tweet.authorId,
                           let users = response.includes?.users,
                           let user = users.first(where: { $0.id == authorId }) {
                            xTweet.authorName = user.name
                            xTweet.authorUsername = user.username
                            xTweet.authorProfileImageUrl = user.profileImageUrl
                        }
                        return xTweet
                    }
                    allNewTweets.append(contentsOf: tweets)
                }
            }
            
            // 2. Fetch from Search Query
            if !searchQuery.isEmpty {
                if useRapidAPI {
                    let tweets = try await RapidAPIService.shared.searchTweets(query: searchQuery, apiKey: rapidKey, count: settings.tweetLimit)
                    allNewTweets.append(contentsOf: tweets)
                } else {
                    guard let client = client else {
                        errorMessage = "Twitter Bearer Token Missing"
                        return
                    }
                    
                    let response = try await client.searchRecentTweets(
                        query: searchQuery,
                        fields: [\.createdAt, \.authorId, \.text],
                        expansions: [
                            .authorId(userFields: [\.name, \.username, \.profileImageUrl])
                        ],
                        maxResults: 10
                    )
                    
                    let tweets = response.data.map { tweet -> XFlowTweet in
                        var xTweet = XFlowTweet(from: tweet)
                        if let authorId = tweet.authorId,
                           let users = response.includes?.users,
                           let user = users.first(where: { $0.id == authorId }) {
                            xTweet.authorName = user.name
                            xTweet.authorUsername = user.username
                            xTweet.authorProfileImageUrl = user.profileImageUrl
                        }
                        return xTweet
                    }
                    allNewTweets.append(contentsOf: tweets)
                }
            }
            
            // 3. Fetch from Lists
            if useRapidAPI {
                let listIds = settings.twitterLists
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                
                for listId in listIds {
                    let tweets = try await RapidAPIService.shared.getListTimeline(listId: listId, apiKey: rapidKey, count: settings.tweetLimit)
                    allNewTweets.append(contentsOf: tweets)
                }
            }
            
            // 4. Fetch from Communities
            if useRapidAPI {
                let communityIds = settings.communities
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                
                for communityId in communityIds {
                    let tweets = try await RapidAPIService.shared.getCommunityTimeline(topicId: communityId, apiKey: rapidKey, count: settings.tweetLimit)
                    allNewTweets.append(contentsOf: tweets)
                }
            }
            
            // Filter out existing
            let uniqueNewTweets = allNewTweets.filter { newTweet in
                !self.tweets.contains(where: { $0.id == newTweet.id })
            }
            
            if !uniqueNewTweets.isEmpty {
                // Sort by creation date before appending (oldest first for danmaku queueing)
                let sortedTweets = uniqueNewTweets.sorted { 
                    ($0.createdAt ?? Date.distantPast) < ($1.createdAt ?? Date.distantPast)
                }
                self.tweets.append(contentsOf: sortedTweets)
            }
            
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
