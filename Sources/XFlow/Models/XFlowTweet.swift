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
    
    init(from tweet: Tweet) {
        self.id = tweet.id
        self.text = tweet.text
        self.authorId = tweet.authorId
        self.createdAt = tweet.createdAt
    }
    
    init(id: String, text: String, authorName: String?, authorUsername: String?, authorProfileImageUrl: String?, createdAt: Date) {
        self.id = id
        self.text = text
        self.authorId = nil // Not strictly needed if we have name/username
        self.authorName = authorName
        self.authorUsername = authorUsername
        if let urlString = authorProfileImageUrl {
            self.authorProfileImageUrl = URL(string: urlString)
        } else {
            self.authorProfileImageUrl = nil
        }
        self.createdAt = createdAt
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
}
