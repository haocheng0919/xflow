import Foundation

enum RapidAPIError: Error {
    case invalidURL
    case noData
    case decodingError(Error)
    case apiError(String)
}

actor RapidAPIService {
    static let shared = RapidAPIService()
    private let host = "twitter241.p.rapidapi.com"
    
    private init() {}
    
    private func headers(apiKey: String) -> [String: String] {
        return [
            "X-RapidAPI-Key": apiKey,
            "X-RapidAPI-Host": host
        ]
    }
    
    // MARK: - User Lookup
    
    func getUserID(username: String, apiKey: String) async throws -> String {
        var components = URLComponents(string: "https://\(host)/user")!
        components.queryItems = [URLQueryItem(name: "username", value: username)]
        
        guard let url = components.url else { throw RapidAPIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers(apiKey: apiKey)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Parse: result.data.user.result.rest_id
        let decoded = try JSONDecoder().decode(UserRootResponse.self, from: data)
        return decoded.result.data.user.result.rest_id
    }
    
    // MARK: - Timeline
    
    func getUserTweets(userId: String, apiKey: String) async throws -> [XFlowTweet] {
        // Check if we should use local mock data
        if apiKey == "MOCK_MODE" {
            return try await loadLocalTweets()
        }

        var components = URLComponents(string: "https://\(host)/user-tweets")!
        components.queryItems = [
            URLQueryItem(name: "user", value: userId),
            URLQueryItem(name: "count", value: "20")
        ]
        
        guard let url = components.url else { throw RapidAPIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers(apiKey: apiKey)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let decoded = try JSONDecoder().decode(TimelineRootResponse.self, from: data)
        return try parseTweets(from: decoded.result.timeline.instructions)
    }

    func loadLocalTweets() async throws -> [XFlowTweet] {
        let url = URL(fileURLWithPath: "response.json")
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(TimelineRootResponse.self, from: data)
        return try parseTweets(from: decoded.result.timeline.instructions)
    }
    
    // MARK: - Parsing Helper
    
    private func parseTweets(from instructions: [Instruction]) throws -> [XFlowTweet] {
        var tweets: [XFlowTweet] = []
        
        for instruction in instructions {
            if let entries = instruction.entries {
                for entry in entries {
                    if let result = entry.content.itemContent?.tweet_results?.result {
                         if let tweet = convert(result: result) {
                             tweets.append(tweet)
                         }
                    }
                }
            } else if let entry = instruction.entry { // Pinned tweet
                if let result = entry.content.itemContent?.tweet_results?.result {
                    if let tweet = convert(result: result) {
                        tweets.append(tweet)
                    }
                }
            }
        }
        
        return tweets
    }
    
    private func convert(result: TweetResult) -> XFlowTweet? {
        // Handle both direct Tweet and TweetWithVisibilityResults
        let tweetData: TweetData
        if let directTweet = result.legacy, let directCore = result.core {
            tweetData = TweetData(legacy: directTweet, core: directCore)
        } else if let visibilityTweet = result.tweet {
            tweetData = TweetData(legacy: visibilityTweet.legacy, core: visibilityTweet.core)
        } else {
            return nil
        }

        let legacy = tweetData.legacy
        let userLegacy = tweetData.core.user_results.result.legacy
        
        // Date Format: "Tue Jun 02 20:12:29 +0000 2009"
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let date = formatter.date(from: legacy.created_at) ?? Date()
        
        return XFlowTweet(
            id: legacy.id_str,
            text: legacy.full_text,
            authorName: userLegacy?.name ?? "Unknown",
            authorUsername: userLegacy?.screen_name ?? "unknown",
            authorProfileImageUrl: userLegacy?.profile_image_url_https,
            createdAt: date
        )
    }
    
    // MARK: - Search
    
    func searchTweets(query: String, apiKey: String, count: Int = 20) async throws -> [XFlowTweet] {
        // Try v3 first, then fall back to v2 if needed
        do {
            return try await searchTweetsV3(query: query, apiKey: apiKey, count: count)
        } catch {
            print("V3 search failed, trying V2: \(error)")
            return try await searchTweetsV2(query: query, apiKey: apiKey, count: count)
        }
    }
    
    private func searchTweetsV3(query: String, apiKey: String, count: Int) async throws -> [XFlowTweet] {
        var components = URLComponents(string: "https://\(host)/search-v3")!
        components.queryItems = [
            URLQueryItem(name: "type", value: "Top"),
            URLQueryItem(name: "count", value: "\(count)"),
            URLQueryItem(name: "query", value: query)
        ]
        
        guard let url = components.url else { throw RapidAPIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers(apiKey: apiKey)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(TimelineRootResponse.self, from: data)
        
        return try parseTweets(from: decoded.result.timeline.instructions)
    }
    
    private func searchTweetsV2(query: String, apiKey: String, count: Int) async throws -> [XFlowTweet] {
        var components = URLComponents(string: "https://\(host)/search-v2")!
        components.queryItems = [
            URLQueryItem(name: "type", value: "Top"),
            URLQueryItem(name: "count", value: "\(count)"),
            URLQueryItem(name: "query", value: query)
        ]
        
        guard let url = components.url else { throw RapidAPIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers(apiKey: apiKey)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(TimelineRootResponse.self, from: data)
        
        return try parseTweets(from: decoded.result.timeline.instructions)
    }
    
    // MARK: - List Timeline
    
    func getListTimeline(listId: String, apiKey: String) async throws -> [XFlowTweet] {
        var components = URLComponents(string: "https://\(host)/list-timeline")!
        components.queryItems = [URLQueryItem(name: "listId", value: listId)]
        
        guard let url = components.url else { throw RapidAPIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers(apiKey: apiKey)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(TimelineRootResponse.self, from: data)
        
        return try parseTweets(from: decoded.result.timeline.instructions)
    }
    
    // MARK: - Community Timeline
    
    func getCommunityTimeline(topicId: String, apiKey: String) async throws -> [XFlowTweet] {
        var components = URLComponents(string: "https://\(host)/explore-community-timeline")!
        components.queryItems = [URLQueryItem(name: "topicId", value: topicId)]
        
        guard let url = components.url else { throw RapidAPIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers(apiKey: apiKey)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(TimelineRootResponse.self, from: data)
        
        return try parseTweets(from: decoded.result.timeline.instructions)
    }
}

// Helper to unify tweet data
struct TweetData {
    let legacy: TweetLegacy
    let core: TweetCore
}

// MARK: - Decodable Structs

struct UserRootResponse: Decodable {
    let result: UserResponseResult
}
struct UserResponseResult: Decodable {
    let data: UserData
}
struct UserData: Decodable {
    let user: UserContainer
}
struct UserContainer: Decodable {
    let result: UserDetail
}
struct UserDetail: Decodable {
    let rest_id: String
    let legacy: UserLegacy
}
struct UserLegacy: Decodable {
    let name: String?
    let screen_name: String?
    let profile_image_url_https: String?
}

// Timeline
struct TimelineRootResponse: Decodable {
    let result: TimelineResult
}
struct TimelineResult: Decodable {
    let timeline: TimelineData
}
struct TimelineData: Decodable {
    let instructions: [Instruction]
}
struct Instruction: Decodable {
    let type: String
    let entries: [Entry]? // For TimelineAddEntries
    let entry: Entry? // For TimelinePinEntry
}
struct Entry: Decodable {
    let content: EntryContent
}
struct EntryContent: Decodable {
    let itemContent: ItemContent?
}
struct ItemContent: Decodable {
    let tweet_results: TweetResults?
}
struct TweetResults: Decodable {
    let result: TweetResult
}
struct TweetResult: Decodable {
    let __typename: String
    // For direct Tweet
    let legacy: TweetLegacy?
    let core: TweetCore?
    // For TweetWithVisibilityResults
    let tweet: VisibilityTweet?
}
struct VisibilityTweet: Decodable {
    let legacy: TweetLegacy
    let core: TweetCore
}
struct TweetLegacy: Decodable {
    let full_text: String
    let created_at: String
    let id_str: String
}
struct TweetCore: Decodable {
    let user_results: UserResultContainer
}
struct UserResultContainer: Decodable {
    let result: UserResult
}
struct UserResult: Decodable {
    let __typename: String
    let rest_id: String?
    let legacy: UserLegacy?
}
