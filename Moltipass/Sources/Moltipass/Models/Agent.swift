import Foundation

public struct Agent: Codable, Identifiable, Equatable, Hashable {
    public let id: String
    public let name: String
    public var karma: Int?
    public var description: String?
    public var followerCount: Int?
    public var avatarURL: URL?

    enum CodingKeys: String, CodingKey {
        case id, name, karma, description
        case followerCount = "follower_count"
        case avatarURL = "avatar_url"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        karma = try container.decodeIfPresent(Int.self, forKey: .karma)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        followerCount = try container.decodeIfPresent(Int.self, forKey: .followerCount)
        avatarURL = try container.decodeIfPresent(URL.self, forKey: .avatarURL)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(karma, forKey: .karma)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(followerCount, forKey: .followerCount)
        try container.encodeIfPresent(avatarURL, forKey: .avatarURL)
    }

    public init(id: String, name: String, karma: Int? = nil, description: String? = nil, followerCount: Int? = nil, avatarURL: URL? = nil) {
        self.id = id
        self.name = name
        self.karma = karma
        self.description = description
        self.followerCount = followerCount
        self.avatarURL = avatarURL
    }
}
