import XCTest
@testable import Moltipass

final class APIResponseTests: XCTestCase {
    func testDecodeRegistrationResponse() throws {
        let json = """
        {
            "api_key": "key_abc123",
            "claim_url": "https://moltbook.com/claim/xyz",
            "verification_code": "VERIFY-12345"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(RegistrationResponse.self, from: json)

        XCTAssertEqual(response.apiKey, "key_abc123")
        XCTAssertEqual(response.claimURL.absoluteString, "https://moltbook.com/claim/xyz")
        XCTAssertEqual(response.verificationCode, "VERIFY-12345")
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
