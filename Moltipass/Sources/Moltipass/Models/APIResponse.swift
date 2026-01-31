import Foundation

public struct RegistrationResponse: Codable {
    public let success: Bool
    public let message: String?
    public let agent: RegisteredAgent?
    public let status: String?

    // Convenience accessors
    public var apiKey: String { agent?.apiKey ?? "" }
    public var claimURL: URL? { agent?.claimURL }
    public var verificationCode: String { agent?.verificationCode ?? "" }
}

public struct RegisteredAgent: Codable {
    public let id: String
    public let name: String
    public let apiKey: String
    public let claimURL: URL
    public let verificationCode: String
    public let profileURL: URL?
    public let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case apiKey = "api_key"
        case claimURL = "claim_url"
        case verificationCode = "verification_code"
        case profileURL = "profile_url"
        case createdAt = "created_at"
    }
}

public struct StatusResponse: Codable {
    public let status: ClaimStatus
    public let claimURL: URL?
    public let message: String?
    public let hint: String?
    public let agent: StatusAgent?

    public struct StatusAgent: Codable {
        public let id: String
        public let name: String
    }

    public enum ClaimStatus: String, Codable {
        case pendingClaim = "pending_claim"
        case claimed = "claimed"
    }

    enum CodingKeys: String, CodingKey {
        case status, message, hint, agent
        case claimURL = "claim_url"
    }
}

public struct APIError: Codable, Error {
    public let error: String
    public var retryAfterMinutes: Int?
    public var message: String?

    enum CodingKeys: String, CodingKey {
        case error, message
        case retryAfterMinutes = "retry_after_minutes"
    }
}

public struct FeedResponse: Codable {
    public let posts: [Post]
    public var nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case posts
        case nextCursor = "next_cursor"
    }
}

public struct CommentsResponse: Codable {
    public let comments: [Comment]
}

public struct PostDetailResponse: Decodable {
    public let success: Bool
    public let post: Post
    public let comments: [Comment]
}

public struct SearchResponse: Codable {
    public var posts: [Post]?
    public var agents: [Agent]?
    public var submolts: [Submolt]?
}

public struct EmptyResponse: Decodable {}

public struct CreatePostResponse: Decodable {
    public let success: Bool
    public let post: Post?
    public let message: String?
}

public struct CreateCommentResponse: Decodable {
    public let success: Bool
    public let comment: Comment?
    public let message: String?
}

public struct SubmoltsResponse: Decodable {
    public let submolts: [Submolt]
}

public struct SubmoltDetailResponse: Decodable {
    public let success: Bool
    public let submolt: Submolt
    public let posts: [Post]
    public var yourRole: String?

    enum CodingKeys: String, CodingKey {
        case success, submolt, posts
        case yourRole = "your_role"
    }
}

public struct ProfileResponse: Decodable {
    public let success: Bool?
    public let agent: Agent?
    public var posts: [Post]?
    public var recentPosts: [Post]?

    // The API might return the agent directly or wrapped
    // This handles both cases
    private let id: String?
    private let name: String?
    private let karma: Int?
    private let description: String?
    private let followerCount: Int?

    enum CodingKeys: String, CodingKey {
        case success, agent, posts
        case recentPosts = "recentPosts"
        case id, name, karma, description
        case followerCount = "follower_count"
    }

    // Computed property to get the agent either from the wrapped response or direct fields
    public var resolvedAgent: Agent? {
        if let agent = agent {
            return agent
        }
        // If agent is nil but we have id/name, the response was the agent directly
        guard let id = id, let name = name else { return nil }
        return Agent(id: id, name: name, karma: karma, description: description, followerCount: followerCount)
    }

    // Get posts from either field
    public var resolvedPosts: [Post] {
        posts ?? recentPosts ?? []
    }
}

public struct FollowingResponse: Decodable {
    public let agents: [Agent]
}

public struct SubscribeResponse: Decodable {
    public let success: Bool
    public let message: String?
}
