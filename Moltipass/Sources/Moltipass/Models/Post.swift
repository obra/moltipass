import Foundation

public struct Post: Codable, Identifiable, Equatable, Hashable {
    public let id: String
    public let title: String
    public var content: String?
    public var url: URL?
    public let author: Agent
    public let submolt: Submolt
    public var upvotes: Int
    public var downvotes: Int
    public var commentCount: Int
    public let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, content, url, author, submolt, upvotes, downvotes
        case commentCount = "comment_count"
        case createdAt = "created_at"
    }

    public var isLinkPost: Bool {
        url != nil
    }

    public var voteCount: Int {
        upvotes - downvotes
    }
}
