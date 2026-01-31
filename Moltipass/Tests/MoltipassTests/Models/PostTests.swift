import XCTest
@testable import Moltipass

final class PostTests: XCTestCase {
    func testDecodeTextPost() throws {
        // Test with actual API response format
        let json = """
        {
            "id": "post_123",
            "title": "Hello World",
            "content": "This is my first post",
            "url": null,
            "author": {
                "id": "agent_1",
                "name": "TestBot"
            },
            "submolt": {
                "id": "submolt_1",
                "name": "general",
                "display_name": "General",
                "is_subscribed": true
            },
            "upvotes": 50,
            "downvotes": 8,
            "comment_count": 5,
            "created_at": "2026-01-30T12:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let post = try decoder.decode(Post.self, from: json)

        XCTAssertEqual(post.id, "post_123")
        XCTAssertEqual(post.title, "Hello World")
        XCTAssertEqual(post.content, "This is my first post")
        XCTAssertNil(post.url)
        XCTAssertEqual(post.author.name, "TestBot")
        XCTAssertEqual(post.submolt.name, "general")
        XCTAssertEqual(post.submolt.displayName, "General")
        XCTAssertEqual(post.upvotes, 50)
        XCTAssertEqual(post.downvotes, 8)
        XCTAssertEqual(post.voteCount, 42) // 50 - 8
        XCTAssertEqual(post.commentCount, 5)
        XCTAssertFalse(post.isLinkPost)
    }

    func testDecodeLinkPost() throws {
        let json = """
        {
            "id": "post_456",
            "title": "Check this out",
            "content": null,
            "url": "https://example.com/article",
            "author": {"id": "agent_2", "name": "LinkBot"},
            "submolt": {"id": "submolt_2", "name": "links"},
            "upvotes": 10,
            "downvotes": 0,
            "comment_count": 2,
            "created_at": "2026-01-30T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let post = try decoder.decode(Post.self, from: json)

        XCTAssertEqual(post.url?.absoluteString, "https://example.com/article")
        XCTAssertNil(post.content)
        XCTAssertTrue(post.isLinkPost)
        XCTAssertEqual(post.voteCount, 10)
    }

    func testDecodeRealAPIResponse() throws {
        // Test with actual response from Moltbook API
        let json = """
        {
            "id": "cbd6474f-8478-4894-95f1-7b104a73bcd5",
            "title": "Test Post Title",
            "content": "Post content here",
            "url": null,
            "upvotes": 22178,
            "downvotes": 5,
            "comment_count": 1932,
            "created_at": "2026-01-30T05:39:05.821605+00:00",
            "author": {
                "id": "7e33c519-8140-4370-b274-b4a9db16f766",
                "name": "eudaemon_0"
            },
            "submolt": {
                "id": "29beb7ee-ca7d-4290-9c2f-09926264866f",
                "name": "general",
                "display_name": "General"
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let post = try decoder.decode(Post.self, from: json)

        XCTAssertEqual(post.id, "cbd6474f-8478-4894-95f1-7b104a73bcd5")
        XCTAssertEqual(post.upvotes, 22178)
        XCTAssertEqual(post.downvotes, 5)
        XCTAssertEqual(post.voteCount, 22173)
        XCTAssertEqual(post.author.name, "eudaemon_0")
        XCTAssertEqual(post.submolt.title, "General")
    }
}
