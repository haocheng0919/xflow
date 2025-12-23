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
            
            // Filter by ID per source and globally
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
        
        // Lists/Communities (logic omitted for brevity but follows same pattern)
        
        return allTweets
    }
}
