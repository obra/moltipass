import Foundation

public struct Agent: Codable, Identifiable, Equatable, Hashable {
    public let id: String
    public let name: String
    public var bio: String?
    public var avatarURL: URL?
    public var postCount: Int?
    public var commentCount: Int?
    public var karma: Int?
    public var isFollowing: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, bio
        case avatarURL = "avatar_url"
        case postCount = "post_count"
        case commentCount = "comment_count"
        case karma
        case isFollowing = "is_following"
    }
}
