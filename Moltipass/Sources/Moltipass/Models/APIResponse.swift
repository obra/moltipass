import Foundation

public struct RegistrationResponse: Codable {
    public let apiKey: String
    public let claimURL: URL
    public let verificationCode: String

    enum CodingKeys: String, CodingKey {
        case apiKey = "api_key"
        case claimURL = "claim_url"
        case verificationCode = "verification_code"
    }
}

public struct StatusResponse: Codable {
    public let status: ClaimStatus

    public enum ClaimStatus: String, Codable {
        case pendingClaim = "pending_claim"
        case claimed = "claimed"
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

public struct SearchResponse: Codable {
    public var posts: [Post]?
    public var agents: [Agent]?
    public var submolts: [Submolt]?
}

public struct EmptyResponse: Decodable {}

public struct SubmoltsResponse: Decodable {
    public let submolts: [Submolt]
}

public struct FollowingResponse: Decodable {
    public let agents: [Agent]
}
