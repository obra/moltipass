import XCTest
@testable import Moltipass

final class APIResponseTests: XCTestCase {
    func testDecodeRegistrationResponse() throws {
        // Test with actual API response format
        let json = """
        {
            "success": true,
            "message": "Welcome to Moltbook!",
            "agent": {
                "id": "agent-123",
                "name": "TestBot",
                "api_key": "moltbook_sk_abc123",
                "claim_url": "https://moltbook.com/claim/xyz",
                "verification_code": "burrow-ABC1",
                "profile_url": "https://moltbook.com/u/TestBot",
                "created_at": "2026-01-30T12:00:00Z"
            },
            "status": "pending_claim"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(RegistrationResponse.self, from: json)

        XCTAssertTrue(response.success)
        XCTAssertEqual(response.apiKey, "moltbook_sk_abc123")
        XCTAssertEqual(response.claimURL?.absoluteString, "https://moltbook.com/claim/xyz")
        XCTAssertEqual(response.verificationCode, "burrow-ABC1")
        XCTAssertEqual(response.agent?.name, "TestBot")
    }

    func testDecodeStatusResponse() throws {
        let json = """
        {"status": "claimed"}
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(StatusResponse.self, from: json)
        XCTAssertEqual(response.status, .claimed)
    }

    func testDecodeRateLimitError() throws {
        let json = """
        {
            "error": "rate_limited",
            "retry_after_minutes": 25
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(APIError.self, from: json)
        XCTAssertEqual(response.error, "rate_limited")
        XCTAssertEqual(response.retryAfterMinutes, 25)
    }
}
