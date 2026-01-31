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
            "api_key": "key_abc123",
            "claim_url": "https://moltbook.com/claim/xyz",
            "verification_code": "VERIFY-12345"
        }
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/agents/register")
            XCTAssertEqual(request.httpMethod, "POST")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseJSON)
        }

        let result = try await api.register()
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
}
