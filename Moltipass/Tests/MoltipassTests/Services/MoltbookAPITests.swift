import XCTest
@testable import Moltipass

final class MoltbookAPITests: XCTestCase {
    var mockSession: URLSession!

    override func setUp() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)
    }

    @MainActor
    func testBuildAuthenticatedRequest() {
        let api = MoltbookAPI(apiKey: "test_key", session: mockSession)
        let request = api.buildRequest(endpoint: "/posts", method: "GET")

        XCTAssertEqual(request.url?.absoluteString, "https://www.moltbook.com/api/v1/posts")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test_key")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    @MainActor
    func testBuildUnauthenticatedRequest() {
        let unauthApi = MoltbookAPI(apiKey: nil, session: mockSession)
        let request = unauthApi.buildRequest(endpoint: "/agents/register", method: "POST")

        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
    }

    @MainActor
    func testRegister() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: config)
        let api = MoltbookAPI(apiKey: nil, session: mockSession)

        let responseJSON = """
        {
            "success": true,
            "message": "Welcome to Moltbook!",
            "agent": {
                "id": "agent-123",
                "name": "TestBot",
                "api_key": "key_abc123",
                "claim_url": "https://moltbook.com/claim/xyz",
                "verification_code": "VERIFY-12345",
                "profile_url": "https://moltbook.com/u/TestBot",
                "created_at": "2026-01-30T12:00:00Z"
            },
            "status": "pending_claim"
        }
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/agents/register")
            XCTAssertEqual(request.httpMethod, "POST")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseJSON)
        }

        let result = try await api.register(name: "TestBot", description: "A test agent")
        XCTAssertEqual(result.apiKey, "key_abc123")
        XCTAssertEqual(result.verificationCode, "VERIFY-12345")
    }

    @MainActor
    func testCheckStatus() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: config)
        let api = MoltbookAPI(apiKey: "test_key", session: mockSession)

        let responseJSON = """
        {"status": "claimed"}
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/agents/status")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseJSON)
        }

        let result = try await api.checkStatus()
        XCTAssertEqual(result.status, .claimed)
    }

    @MainActor
    func testGetFeed() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: config)
        let api = MoltbookAPI(apiKey: "test_key", session: mockSession)

        let responseJSON = """
        {
            "posts": [{
                "id": "post_1",
                "title": "Test Post",
                "body": "Content",
                "url": null,
                "author": {"id": "agent_1", "name": "Bot"},
                "submolt": {"id": "submolt_1", "name": "general", "is_subscribed": true},
                "vote_count": 10,
                "comment_count": 2,
                "user_vote": null,
                "created_at": "2026-01-30T12:00:00Z"
            }],
            "next_cursor": "cursor123"
        }
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            XCTAssertTrue(request.url?.absoluteString.contains("/posts?sort=hot") ?? false)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseJSON)
        }

        let result = try await api.getFeed(sort: .hot)
        XCTAssertEqual(result.posts.count, 1)
        XCTAssertEqual(result.posts.first?.title, "Test Post")
        XCTAssertEqual(result.nextCursor, "cursor123")
    }
}
