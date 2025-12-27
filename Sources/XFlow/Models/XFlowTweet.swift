import Foundation
import Twift

struct XFlowTweet: Identifiable, Equatable {
    let id: String
    let text: String
    let authorId: String?
    let createdAt: Date?
    
    // Additional fields populated from expansions
    var authorName: String?
    var authorUsername: String?
    var authorProfileImageUrl: URL?
    var isVerified: Bool?
    var followersCount: Int?
    
    init(from tweet: Tweet) {
        self.id = tweet.id
        self.text = tweet.text
        self.authorId = tweet.authorId
        self.createdAt = tweet.createdAt
        self.isVerified = nil
        self.followersCount = nil
    }
    
    init(id: String, text: String, authorName: String?, authorUsername: String?, authorProfileImageUrl: String?, createdAt: Date, isVerified: Bool? = nil, followersCount: Int? = nil) {
        self.id = id
        self.text = text
        self.authorId = nil 
        self.authorName = authorName
        self.authorUsername = authorUsername
        if let urlString = authorProfileImageUrl {
            self.authorProfileImageUrl = URL(string: urlString)
        } else {
            self.authorProfileImageUrl = nil
        }
        self.createdAt = createdAt
        self.isVerified = isVerified
        self.followersCount = followersCount
    }
    
    var relativeTimestamp: String {
        guard let createdAt = createdAt else { return "" }
        let now = Date()
        let diff = Int(now.timeIntervalSince(createdAt))
        
        if diff < 60 {
            return "\(max(1, diff))s"
        } else if diff < 3600 {
            return "\(diff / 60)m"
        } else if diff < 86400 {
            return "\(diff / 3600)h"
        } else {
            return "\(diff / 86400)d"
        }
    }
    
    var solanaCA: String? {
        let pattern = "[1-9A-HJ-NP-Za-km-z]{32,44}(?:pump|blv|bonk|bags)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let nsString = text as NSString
        let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        return results.first.map { nsString.substring(with: $0.range) }
    }
}
