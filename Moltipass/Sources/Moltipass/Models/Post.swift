import Foundation

public struct Post: Codable, Identifiable, Equatable, Hashable {
    public let id: String
    public let title: String
    public var body: String?
    public var url: URL?
    public let author: Agent
    public let submolt: Submolt
    public var voteCount: Int
    public var commentCount: Int
    public var userVote: Int?
    public let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, body, url, author, submolt
        case voteCount = "vote_count"
        case commentCount = "comment_count"
        case userVote = "user_vote"
        case createdAt = "created_at"
    }

    public var isLinkPost: Bool {
        url != nil
    }
}
