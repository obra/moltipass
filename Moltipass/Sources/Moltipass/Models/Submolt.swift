import Foundation

public struct Submolt: Codable, Identifiable, Equatable, Hashable {
    private var _id: String?
    public let name: String
    public var displayName: String?
    public var description: String?
    public var subscriberCount: Int?
    public var isSubscribed: Bool

    // Identifiable conformance - use id if available, fall back to name
    public var id: String { _id ?? name }

    enum CodingKeys: String, CodingKey {
        case _id = "id"
        case name, description
        case displayName = "display_name"
        case subscriberCount = "subscriber_count"
        case isSubscribed = "is_subscribed"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decodeIfPresent(String.self, forKey: ._id)
        name = try container.decode(String.self, forKey: .name)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        subscriberCount = try container.decodeIfPresent(Int.self, forKey: .subscriberCount)
        isSubscribed = try container.decodeIfPresent(Bool.self, forKey: .isSubscribed) ?? false
    }

    /// Returns display name if available, otherwise the raw name
    public var title: String {
        displayName ?? name
    }
}
