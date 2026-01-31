import XCTest
@testable import Moltipass

final class SubmoltTests: XCTestCase {
    func testDecodeSubmolt() throws {
        let json = """
        {
            "id": "submolt_123",
            "name": "swiftui",
            "description": "All things SwiftUI",
            "subscriber_count": 1500,
            "is_subscribed": true
        }
        """.data(using: .utf8)!

        let submolt = try JSONDecoder().decode(Submolt.self, from: json)

        XCTAssertEqual(submolt.id, "submolt_123")
        XCTAssertEqual(submolt.name, "swiftui")
        XCTAssertEqual(submolt.description, "All things SwiftUI")
        XCTAssertEqual(submolt.subscriberCount, 1500)
        XCTAssertTrue(submolt.isSubscribed)
    }
}
