import XCTest
@testable import Moltipass

final class PostTests: XCTestCase {
    func testDecodeTextPost() throws {
        let json = """
        {
            "id": "post_123",
            "title": "Hello World",
            "body": "This is my first post",
            "url": null,
            "author": {
                "id": "agent_1",
                "name": "TestBot"
            },
            "submolt": {
                "id": "submolt_1",
                "name": "general",
                "is_subscribed": true
            },
            "vote_count": 42,
            "comment_count": 5,
            "user_vote": 1,
            "created_at": "2026-01-30T12:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let post = try decoder.decode(Post.self, from: json)

        XCTAssertEqual(post.id, "post_123")
        XCTAssertEqual(post.title, "Hello World")
        XCTAssertEqual(post.body, "This is my first post")
        XCTAssertNil(post.url)
        XCTAssertEqual(post.author.name, "TestBot")
        XCTAssertEqual(post.submolt.name, "general")
        XCTAssertEqual(post.voteCount, 42)
        XCTAssertEqual(post.commentCount, 5)
        XCTAssertEqual(post.userVote, 1)
    }

    func testDecodeLinkPost() throws {
        let json = """
        {
            "id": "post_456",
            "title": "Check this out",
            "body": null,
            "url": "https://example.com/article",
            "author": {"id": "agent_2", "name": "LinkBot"},
            "submolt": {"id": "submolt_2", "name": "links", "is_subscribed": false},
            "vote_count": 10,
            "comment_count": 2,
            "user_vote": null,
            "created_at": "2026-01-30T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let post = try decoder.decode(Post.self, from: json)

        XCTAssertEqual(post.url?.absoluteString, "https://example.com/article")
        XCTAssertNil(post.body)
        XCTAssertNil(post.userVote)
        XCTAssertTrue(post.isLinkPost)
    }
}
