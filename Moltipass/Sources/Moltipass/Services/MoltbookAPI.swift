import Foundation
import os.log

private let logger = Logger(subsystem: "com.moltipass", category: "api")

@MainActor
public final class MoltbookAPI: ObservableObject {
    private let baseURL = "https://www.moltbook.com/api/v1"
    private var apiKey: String?
    private let session: URLSession
    private let decoder: JSONDecoder

    @Published public var isAuthenticated = false

    public init(apiKey: String? = nil, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.isAuthenticated = apiKey != nil
        logger.info("MoltbookAPI initialized, authenticated: \(apiKey != nil)")
    }

    public func setAPIKey(_ key: String) {
        self.apiKey = key
        self.isAuthenticated = true
    }

    public func clearAPIKey() {
        self.apiKey = nil
        self.isAuthenticated = false
    }

    public func buildRequest(endpoint: String, method: String, body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: URL(string: baseURL + endpoint)!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = body
        }

        return request
    }

    public func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let endpoint = request.url?.path ?? "unknown"
        let method = request.httpMethod ?? "GET"
        logger.info("API \(method) \(endpoint)")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("API \(endpoint): Invalid response type")
            throw APIError(error: "invalid_response")
        }

        logger.info("API \(endpoint): HTTP \(httpResponse.statusCode), \(data.count) bytes")

        switch httpResponse.statusCode {
        case 200...299:
            do {
                let result = try decoder.decode(T.self, from: data)
                logger.info("API \(endpoint): Decoded successfully")
                return result
            } catch {
                logger.error("API \(endpoint): Decode failed - \(error)")
                // Log raw response for debugging
                if let rawString = String(data: data.prefix(500), encoding: .utf8) {
                    logger.error("API \(endpoint): Raw response: \(rawString)")
                }
                throw error
            }
        case 401:
            logger.error("API \(endpoint): Unauthorized")
            throw APIError(error: "unauthorized", message: "Invalid or expired API key")
        case 404:
            logger.error("API \(endpoint): Not found")
            throw APIError(error: "not_found", message: "Resource not found")
        case 429:
            logger.warning("API \(endpoint): Rate limited")
            let errorResponse = try? decoder.decode(APIError.self, from: data)
            throw errorResponse ?? APIError(error: "rate_limited")
        default:
            logger.error("API \(endpoint): HTTP \(httpResponse.statusCode)")
            if let rawString = String(data: data.prefix(500), encoding: .utf8) {
                logger.error("API \(endpoint): Response: \(rawString)")
            }
            let errorResponse = try? decoder.decode(APIError.self, from: data)
            throw errorResponse ?? APIError(error: "unknown", message: "HTTP \(httpResponse.statusCode)")
        }
    }

    public struct RegisterRequest: Encodable, Sendable {
        public let name: String
        public let description: String
    }

    public func register(name: String, description: String) async throws -> RegistrationResponse {
        let payload = RegisterRequest(name: name, description: description)
        let data = try JSONEncoder().encode(payload)
        let request = buildRequest(endpoint: "/agents/register", method: "POST", body: data)
        return try await perform(request)
    }

    public func checkStatus() async throws -> StatusResponse {
        let request = buildRequest(endpoint: "/agents/status", method: "GET")
        return try await perform(request)
    }

    // MARK: - Feed & Posts

    public func getFeed(sort: FeedSort = .hot, cursor: String? = nil) async throws -> FeedResponse {
        var endpoint = "/posts?sort=\(sort.rawValue)"
        if let cursor = cursor {
            endpoint += "&cursor=\(cursor)"
        }
        let request = buildRequest(endpoint: endpoint, method: "GET")
        return try await perform(request)
    }

    public func getPost(id: String) async throws -> PostDetailResponse {
        let request = buildRequest(endpoint: "/posts/\(id)", method: "GET")
        return try await perform(request)
    }

    public func createPost(title: String, content: String?, url: String?, submolt: String) async throws -> Post {
        let payload = CreatePostRequest(title: title, content: content, url: url, submolt: submolt)
        let data = try JSONEncoder().encode(payload)
        let request = buildRequest(endpoint: "/posts", method: "POST", body: data)
        let response: CreatePostResponse = try await perform(request)
        guard let post = response.post else {
            throw APIError(error: "invalid_response", message: response.message ?? "No post returned")
        }
        return post
    }

    public func deletePost(id: String) async throws {
        let request = buildRequest(endpoint: "/posts/\(id)", method: "DELETE")
        let _: EmptyResponse = try await perform(request)
    }

    // MARK: - Comments

    public func getComments(postId: String, sort: CommentSort = .top) async throws -> CommentsResponse {
        let request = buildRequest(endpoint: "/posts/\(postId)/comments?sort=\(sort.rawValue)", method: "GET")
        return try await perform(request)
    }

    public func createComment(postId: String, content: String, parentId: String? = nil) async throws -> Comment {
        let payload = CreateCommentRequest(content: content, parentId: parentId)
        let data = try JSONEncoder().encode(payload)
        let request = buildRequest(endpoint: "/posts/\(postId)/comments", method: "POST", body: data)
        let response: CreateCommentResponse = try await perform(request)
        guard let comment = response.comment else {
            throw APIError(error: "invalid_response", message: response.message ?? "No comment returned")
        }
        return comment
    }

    // MARK: - Voting

    public func votePost(id: String, direction: Int) async throws {
        let endpoint = direction > 0 ? "/posts/\(id)/upvote" : "/posts/\(id)/downvote"
        let request = buildRequest(endpoint: endpoint, method: "POST")
        let _: EmptyResponse = try await perform(request)
    }

    public func voteComment(id: String, direction: Int) async throws {
        let endpoint = direction > 0 ? "/comments/\(id)/upvote" : "/comments/\(id)/downvote"
        let request = buildRequest(endpoint: endpoint, method: "POST")
        let _: EmptyResponse = try await perform(request)
    }

    // MARK: - Submolts

    public func getSubmolts() async throws -> SubmoltsResponse {
        let request = buildRequest(endpoint: "/submolts", method: "GET")
        return try await perform(request)
    }

    /// Get submolt details including posts - uses submolt name not ID
    public func getSubmoltDetail(name: String) async throws -> SubmoltDetailResponse {
        let request = buildRequest(endpoint: "/submolts/\(name)", method: "GET")
        return try await perform(request)
    }

    /// Subscribe to a submolt - uses submolt name not ID
    public func subscribe(submoltName: String) async throws {
        let request = buildRequest(endpoint: "/submolts/\(submoltName)/subscribe", method: "POST")
        let _: SubscribeResponse = try await perform(request)
    }

    /// Unsubscribe from a submolt - uses submolt name not ID
    public func unsubscribe(submoltName: String) async throws {
        let request = buildRequest(endpoint: "/submolts/\(submoltName)/unsubscribe", method: "POST")
        let _: SubscribeResponse = try await perform(request)
    }

    // MARK: - Search

    public func search(query: String, scope: SearchScope) async throws -> SearchResponse {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let request = buildRequest(endpoint: "/search?q=\(encodedQuery)&scope=\(scope.rawValue)", method: "GET")
        return try await perform(request)
    }

    // MARK: - Profile

    public func getMyProfile() async throws -> ProfileResponse {
        let request = buildRequest(endpoint: "/agents/me", method: "GET")
        return try await perform(request)
    }

    /// Get agent profile by name - includes recentPosts
    public func getAgentProfile(name: String) async throws -> ProfileResponse {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let request = buildRequest(endpoint: "/agents/profile?name=\(encodedName)", method: "GET")
        return try await perform(request)
    }

    // MARK: - Following

    public func getFollowing() async throws -> FollowingResponse {
        let request = buildRequest(endpoint: "/agents/me/following", method: "GET")
        return try await perform(request)
    }

    public func follow(agentId: String) async throws {
        let request = buildRequest(endpoint: "/agents/\(agentId)/follow", method: "POST")
        let _: EmptyResponse = try await perform(request)
    }

    public func unfollow(agentId: String) async throws {
        let request = buildRequest(endpoint: "/agents/\(agentId)/unfollow", method: "POST")
        let _: EmptyResponse = try await perform(request)
    }
}

public enum FeedSort: String, Sendable {
    case hot, new, top, rising
}

public struct CreatePostRequest: Encodable, Sendable {
    public let title: String
    public let content: String?
    public let url: String?
    public let submolt: String
}

public enum CommentSort: String, Sendable {
    case top, new, controversial
}

public struct CreateCommentRequest: Encodable, Sendable {
    public let content: String
    public let parentId: String?

    enum CodingKeys: String, CodingKey {
        case content
        case parentId = "parent_id"
    }
}

public enum SearchScope: String, Sendable {
    case posts, agents, submolts
}

public struct UpdateProfileRequest: Encodable, Sendable {
    public let name: String?
    public let bio: String?
}
