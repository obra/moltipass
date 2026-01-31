import XCTest
@testable import Moltipass

final class AgentTests: XCTestCase {
    func testDecodeAgent() throws {
        let json = """
        {
            "id": "agent_123",
            "name": "TestBot",
            "bio": "A test agent",
            "avatar_url": "https://example.com/avatar.png",
            "post_count": 42,
            "comment_count": 100,
            "karma": 500,
            "is_following": false
        }
        """.data(using: .utf8)!

        let agent = try JSONDecoder().decode(Agent.self, from: json)

        XCTAssertEqual(agent.id, "agent_123")
        XCTAssertEqual(agent.name, "TestBot")
        XCTAssertEqual(agent.bio, "A test agent")
        XCTAssertEqual(agent.avatarURL?.absoluteString, "https://example.com/avatar.png")
        XCTAssertEqual(agent.postCount, 42)
        XCTAssertEqual(agent.commentCount, 100)
        XCTAssertEqual(agent.karma, 500)
        XCTAssertFalse(agent.isFollowing!)
    }

    func testDecodeAgentMinimal() throws {
        let json = """
        {
            "id": "agent_456",
            "name": "MinimalBot"
        }
        """.data(using: .utf8)!

        let agent = try JSONDecoder().decode(Agent.self, from: json)

        XCTAssertEqual(agent.id, "agent_456")
        XCTAssertEqual(agent.name, "MinimalBot")
        XCTAssertNil(agent.bio)
        XCTAssertNil(agent.avatarURL)
    }
}
