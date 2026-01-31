import XCTest
@testable import Moltipass

final class KeychainServiceTests: XCTestCase {
    let service = KeychainService()
    let testKey = "test_api_key"

    override func tearDown() {
        service.delete(key: testKey)
    }

    func testSaveAndRetrieve() {
        let saved = service.save(key: testKey, value: "secret123")
        XCTAssertTrue(saved)

        let retrieved = service.retrieve(key: testKey)
        XCTAssertEqual(retrieved, "secret123")
    }

    func testRetrieveNonexistent() {
        let retrieved = service.retrieve(key: "nonexistent")
        XCTAssertNil(retrieved)
    }

    func testDelete() {
        service.save(key: testKey, value: "secret")
        let deleted = service.delete(key: testKey)
        XCTAssertTrue(deleted)
        XCTAssertNil(service.retrieve(key: testKey))
    }
}
