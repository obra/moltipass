import Foundation

public struct Comment: Codable, Identifiable, Equatable, Hashable {
    public let id: String
    public let content: String
    public var author: Agent?  // Optional - not present in create response
    public var parentId: String?
    public var upvotes: Int
    public var downvotes: Int
    public var userVote: Int?
    public let createdAt: Date
    public var replies: [Comment]

    public var voteCount: Int { upvotes - downvotes }

    enum CodingKeys: String, CodingKey {
        case id, content, author, replies, upvotes, downvotes
        case parentId = "parent_id"
        case userVote = "user_vote"
        case createdAt = "created_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        author = try container.decodeIfPresent(Agent.self, forKey: .author)
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        upvotes = try container.decodeIfPresent(Int.self, forKey: .upvotes) ?? 0
        downvotes = try container.decodeIfPresent(Int.self, forKey: .downvotes) ?? 0
        userVote = try container.decodeIfPresent(Int.self, forKey: .userVote)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        replies = try container.decodeIfPresent([Comment].self, forKey: .replies) ?? []
    }
}
