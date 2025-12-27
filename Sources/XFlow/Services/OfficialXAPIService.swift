import Foundation
import CommonCrypto

enum OfficialXAPIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case apiError(String)
    case rateLimitExceeded
    case unauthorized
    case forbidden(String)
    case notFound(String)
    
    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Unauthorized Error".localized()
        case .forbidden(let detail): 
            return String(format: "Forbidden Error".localized(), detail)
        case .rateLimitExceeded: return "Rate Limit Error".localized()
        case .notFound(let resource): return String(format: "Not Found Error".localized(), resource)
        case .apiError(let msg): return msg
        default: return "General API Error".localized()
        }
    }
}

actor OfficialXAPIService {
    static let shared = OfficialXAPIService()
    private let baseURL = "https://api.x.com/2"
    
    private var cachedBearerToken: String?
    private var userIdCache: [String: String] = [:]
    
    private func getBearerToken(apiKey: String, apiSecret: String) async throws -> String {
        if let cached = cachedBearerToken { return cached }
        
        let credentials = "\(apiKey):\(apiSecret)".data(using: .utf8)!.base64EncodedString()
        var request = URLRequest(url: URL(string: "https://api.x.com/oauth2/token")!)
        request.httpMethod = "POST"
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = "grant_type=client_credentials".data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OfficialXAPIError.unauthorized
        }
        
        let decoded = try JSONDecoder().decode(OauthTokenResponse.self, from: data)
        self.cachedBearerToken = decoded.access_token
        return decoded.access_token
    }
    
    private func headers(token: String) -> [String: String] {
        return [
            "Authorization": "Bearer \(token.trimmingCharacters(in: .whitespaces))",
            "Content-Type": "application/json"
        ]
    }
    
    private func performRequest<T: Decodable>(url: URL, token: String) async throws -> T {
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers(token: token)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OfficialXAPIError.noData
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw OfficialXAPIError.decodingError(error)
            }
        case 401:
            throw OfficialXAPIError.unauthorized
        case 403:
            var details = "Access Denied"
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let detail = errorJson["detail"] as? String {
                    details = detail
                } else if let title = errorJson["title"] as? String {
                    details = title
                } else if let errors = errorJson["errors"] as? [[String: Any]],
                          let first = errors.first,
                          let msg = first["message"] as? String {
                    details = msg
                }
            }
            throw OfficialXAPIError.forbidden(details)
        case 429:
            var details = "X API Rate Limit Exceeded".localized()
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let detail = errorJson["detail"] as? String {
                    details = detail
                } else if let title = errorJson["title"] as? String {
                    details = title
                }
            }
            throw OfficialXAPIError.apiError(details)
        case 404:
            throw OfficialXAPIError.notFound(url.lastPathComponent)
        default:
            // Parse error message if possible
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let errors = errorJson["errors"] as? [[String: Any]],
                   let firstError = errors.first,
                   let message = firstError["message"] as? String {
                    throw OfficialXAPIError.apiError(message)
                } else if let detail = errorJson["detail"] as? String {
                    throw OfficialXAPIError.apiError(detail)
                }
            }
            throw OfficialXAPIError.apiError("HTTP \(httpResponse.statusCode)")
        }
    }
    
    // MARK: - Endpoints
    
    func getUserID(username: String, apiKey: String, apiSecret: String) async throws -> String {
        let cleanUsername = username.hasPrefix("@") ? String(username.dropFirst()) : username.lowercased()
        if let cached = userIdCache[cleanUsername] { return cached }
        
        let token = try await getBearerToken(apiKey: apiKey, apiSecret: apiSecret)
        guard let url = URL(string: "\(baseURL)/users/by/username/\(cleanUsername)") else {
            throw OfficialXAPIError.invalidURL
        }
        
        let response: XUserResponse = try await performRequest(url: url, token: token)
        userIdCache[cleanUsername] = response.data.id
        return response.data.id
    }
    
    func getUserTweets(userId: String, apiKey: String, apiSecret: String, count: Int = 20) async throws -> [XFlowTweet] {
        let token = try await getBearerToken(apiKey: apiKey, apiSecret: apiSecret)
        var components = URLComponents(string: "\(baseURL)/users/\(userId)/tweets")!
        components.queryItems = [
            URLQueryItem(name: "max_results", value: "\(max(5, min(100, count)))"),
            URLQueryItem(name: "tweet.fields", value: "created_at,author_id,entities"),
            URLQueryItem(name: "expansions", value: "author_id"),
            URLQueryItem(name: "user.fields", value: "name,username,profile_image_url,verified")
        ]
        
        guard let url = components.url else { throw OfficialXAPIError.invalidURL }
        let response: XTimelineResponse = try await performRequest(url: url, token: token)
        return mapToXFlowTweets(response)
    }
    
    func getListTweets(listId: String, apiKey: String, apiSecret: String, count: Int = 20) async throws -> [XFlowTweet] {
        let token = try await getBearerToken(apiKey: apiKey, apiSecret: apiSecret)
        var components = URLComponents(string: "\(baseURL)/lists/\(listId)/tweets")!
        components.queryItems = [
            URLQueryItem(name: "max_results", value: "\(max(5, min(100, count)))"),
            URLQueryItem(name: "tweet.fields", value: "created_at,author_id,entities"),
            URLQueryItem(name: "expansions", value: "author_id"),
            URLQueryItem(name: "user.fields", value: "name,username,profile_image_url,verified")
        ]
        
        guard let url = components.url else { throw OfficialXAPIError.invalidURL }
        let response: XTimelineResponse = try await performRequest(url: url, token: token)
        return mapToXFlowTweets(response)
    }
    
    func searchRecent(query: String, apiKey: String, apiSecret: String, count: Int = 20) async throws -> [XFlowTweet] {
        let token = try await getBearerToken(apiKey: apiKey, apiSecret: apiSecret)
        var components = URLComponents(string: "\(baseURL)/tweets/search/recent")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "max_results", value: "\(max(10, min(100, count)))"),
            URLQueryItem(name: "tweet.fields", value: "created_at,author_id,entities"),
            URLQueryItem(name: "expansions", value: "author_id"),
            URLQueryItem(name: "user.fields", value: "name,username,profile_image_url,verified")
        ]
        
        guard let url = components.url else { throw OfficialXAPIError.invalidURL }
        let response: XTimelineResponse = try await performRequest(url: url, token: token)
        return mapToXFlowTweets(response)
    }
    
    func getReverseChronologicalTimeline(userId: String, apiKey: String, apiSecret: String, accessToken: String, accessTokenSecret: String, count: Int = 20) async throws -> [XFlowTweet] {
        let urlString = "\(baseURL)/users/\(userId)/timelines/reverse_chronological"
        var components = URLComponents(string: urlString)!
        let queryItems = [
            URLQueryItem(name: "max_results", value: "\(max(5, min(100, count)))"),
            URLQueryItem(name: "tweet.fields", value: "created_at,author_id,entities"),
            URLQueryItem(name: "expansions", value: "author_id"),
            URLQueryItem(name: "user.fields", value: "name,username,profile_image_url,verified")
        ]
        components.queryItems = queryItems
        
        guard let url = components.url else { throw OfficialXAPIError.invalidURL }
        
        // OAuth 1.0a Signing
        let oauthHeaders = OAuth1Signer.generateHeader(
            method: "GET",
            url: urlString,
            queryItems: queryItems,
            apiKey: apiKey,
            apiSecret: apiSecret,
            accessToken: accessToken,
            accessTokenSecret: accessTokenSecret
        )
        
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = [
            "Authorization": oauthHeaders,
            "Content-Type": "application/json"
        ]
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OfficialXAPIError.noData
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoded: XTimelineResponse = try JSONDecoder().decode(XTimelineResponse.self, from: data)
                return mapToXFlowTweets(decoded)
            } catch {
                throw OfficialXAPIError.decodingError(error)
            }
        case 401, 403:
            // Parse error for more details
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = errorJson["detail"] as? String {
                throw OfficialXAPIError.forbidden(detail)
            }
            throw OfficialXAPIError.forbidden("HTTP \(httpResponse.statusCode)")
        default:
            throw OfficialXAPIError.apiError("HTTP \(httpResponse.statusCode)")
        }
    }
    
    // MARK: - Mapping
    
    private func mapToXFlowTweets(_ response: XTimelineResponse) -> [XFlowTweet] {
        guard let data = response.data else { return [] }
        let users = response.includes?.users ?? []
        let userMap = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })
        
        let formatter = ISO8601DateFormatter()
        
        return data.map { tweetData in
            let user = userMap[tweetData.author_id]
            let date = tweetData.created_at.flatMap { formatter.date(from: $0) } ?? Date()
            
            return XFlowTweet(
                id: tweetData.id,
                text: tweetData.text,
                authorName: user?.name ?? "Unknown",
                authorUsername: user?.username ?? "unknown",
                authorProfileImageUrl: user?.profile_image_url,
                createdAt: date,
                isVerified: user?.verified,
                followersCount: nil // v2 users/lookup doesn't always include this unless requested explicitly in fields
            )
        }
    }
}

struct OauthTokenResponse: Decodable {
    let access_token: String
}

// MARK: - Models

struct XUserResponse: Decodable {
    let data: XUser
}

struct XUser: Decodable {
    let id: String
    let name: String
    let username: String
    let profile_image_url: String?
    let verified: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, name, username, verified
        case profile_image_url = "profile_image_url"
    }
}

struct XTimelineResponse: Decodable {
    let data: [XTweet]?
    let includes: XIncludes?
}

struct XTweet: Decodable {
    let id: String
    let text: String
    let author_id: String
    let created_at: String?
    
    enum CodingKeys: String, CodingKey {
        case id, text
        case author_id = "author_id"
        case created_at = "created_at"
    }
}

struct XIncludes: Decodable {
    let users: [XUser]?
}

// MARK: - OAuth 1.0 Signer

struct OAuth1Signer {
    static func generateHeader(
        method: String,
        url: String,
        queryItems: [URLQueryItem],
        apiKey: String,
        apiSecret: String,
        accessToken: String,
        accessTokenSecret: String
    ) -> String {
        let nonce = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let timestamp = String(Int(Date().timeIntervalSince1970))
        
        var parameters: [String: String] = [
            "oauth_consumer_key": apiKey,
            "oauth_nonce": nonce,
            "oauth_signature_method": "HMAC-SHA1",
            "oauth_timestamp": timestamp,
            "oauth_token": accessToken,
            "oauth_version": "1.0"
        ]
        
        for item in queryItems {
            if let value = item.value {
                parameters[item.name.urlEncoded] = value.urlEncoded
            }
        }
        
        let sortedKeys = parameters.keys.sorted()
        let parameterString = sortedKeys.map { "\($0)=\(parameters[$0]!)" }.joined(separator: "&")
        
        let baseString = "\(method.uppercased())&\(url.urlEncoded)&\(parameterString.urlEncoded)"
        let signingKey = "\(apiSecret.urlEncoded)&\(accessTokenSecret.urlEncoded)"
        
        let signature = hmacSha1(signingKey: signingKey, baseString: baseString)
        
        let oauthParams: [String: String] = [
            "oauth_consumer_key": apiKey.urlEncoded,
            "oauth_nonce": nonce.urlEncoded,
            "oauth_signature": signature.urlEncoded,
            "oauth_signature_method": "HMAC-SHA1",
            "oauth_timestamp": timestamp.urlEncoded,
            "oauth_token": accessToken.urlEncoded,
            "oauth_version": "1.0"
        ]
        
        let headerString = oauthParams.keys.sorted().map { "\($0)=\"\(oauthParams[$0]!)\"" }.joined(separator: ", ")
        return "OAuth \(headerString)"
    }
    
    private static func hmacSha1(signingKey: String, baseString: String) -> String {
        let keyData = signingKey.data(using: .utf8)!
        let baseData = baseString.data(using: .utf8)!
        
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        keyData.withUnsafeBytes { keyBytes in
            baseData.withUnsafeBytes { baseBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), keyBytes.baseAddress, keyData.count, baseBytes.baseAddress, baseData.count, &digest)
            }
        }
        
        return Data(digest).base64EncodedString()
    }
}

extension String {
    var urlEncoded: String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        return self.addingPercentEncoding(withAllowedCharacters: allowed) ?? self
    }
}
