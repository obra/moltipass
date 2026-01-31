import XCTest
@testable import Moltipass

final class CommentTests: XCTestCase {
    func testDecodeComment() throws {
        let json = """
        {
            "id": "comment_123",
            "content": "Great post!",
            "author": {
                "id": "agent_1",
                "name": "Commenter"
            },
            "parent_id": null,
            "upvotes": 5,
            "downvotes": 0,
            "user_vote": 1,
            "created_at": "2026-01-30T14:00:00Z",
            "replies": []
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let comment = try decoder.decode(Comment.self, from: json)

        XCTAssertEqual(comment.id, "comment_123")
        XCTAssertEqual(comment.content, "Great post!")
        XCTAssertEqual(comment.author?.name, "Commenter")
        XCTAssertNil(comment.parentId)
        XCTAssertEqual(comment.voteCount, 5)
        XCTAssertTrue(comment.replies.isEmpty)
    }

    func testDecodeNestedComments() throws {
        let json = """
        {
            "id": "comment_1",
            "content": "Parent comment",
            "author": {"id": "a1", "name": "Parent"},
            "parent_id": null,
            "upvotes": 10,
            "downvotes": 0,
            "user_vote": null,
            "created_at": "2026-01-30T12:00:00Z",
            "replies": [
                {
                    "id": "comment_2",
                    "content": "Child reply",
                    "author": {"id": "a2", "name": "Child"},
                    "parent_id": "comment_1",
                    "upvotes": 3,
                    "downvotes": 0,
                    "user_vote": null,
                    "created_at": "2026-01-30T13:00:00Z",
                    "replies": []
                }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let comment = try decoder.decode(Comment.self, from: json)

        XCTAssertEqual(comment.replies.count, 1)
        XCTAssertEqual(comment.replies.first?.parentId, "comment_1")
    }

    func testDecodeCommentWithoutAuthor() throws {
        // Create comment response doesn't include author
        let json = """
        {
            "id": "comment_new",
            "content": "New comment",
            "parent_id": null,
            "upvotes": 0,
            "downvotes": 0,
            "created_at": "2026-01-30T14:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let comment = try decoder.decode(Comment.self, from: json)

        XCTAssertEqual(comment.id, "comment_new")
        XCTAssertNil(comment.author)
        XCTAssertEqual(comment.voteCount, 0)
    }
}
