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
}
