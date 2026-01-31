# Moltipass iOS App Implementation Plan

> **For Claude:** REQUIRED: Use superpowers:subagent-driven-development to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native iOS app for humans to interact with Moltbook social network.

**Architecture:** SwiftUI app with tab-based navigation. MoltbookAPI service handles all network calls. Keychain stores credentials securely. Models are Codable structs for JSON parsing.

**Tech Stack:** SwiftUI, iOS 17+, URLSession, Keychain Services

**Spec:** `docs/specs/2026-01-30-moltipass-ios-app-design.md`

---

## Chunk 1: Project Setup & Foundation

### Task 1.1: Create Xcode Project

**Files:**
- Create: `Moltipass.xcodeproj`
- Create: `Moltipass/MoltipassApp.swift`
- Create: `MoltipassTests/MoltipassTests.swift`

- [ ] **Step 1: Create Xcode project in Xcode**

Open Xcode and create a new project:
1. File → New → Project
2. Select "App" under iOS
3. Settings:
   - Product Name: `Moltipass`
   - Organization Identifier: `com.moltipass`
   - Interface: SwiftUI
   - Language: Swift
   - Include Tests: ✅ (Unit Tests only)
4. Save to: `/Users/jesse/Documents/GitHub/moltipass/.worktrees/ios-app/`

- [ ] **Step 2: Configure project settings**

In Xcode project settings:
1. Set iOS Deployment Target to 17.0
2. Set Bundle Identifier to `com.moltipass.app`

- [ ] **Step 3: Create folder structure**

In Xcode, create groups (folders) to match our architecture:
- `App/` (move MoltipassApp.swift here)
- `Models/`
- `Services/`
- `Views/`
- `Utilities/`

- [ ] **Step 4: Verify project builds**

```bash
cd /Users/jesse/Documents/GitHub/moltipass/.worktrees/ios-app
xcodebuild -scheme Moltipass -destination 'platform=iOS Simulator,name=iPhone 15' build
```
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Verify tests run**

```bash
xcodebuild test -scheme Moltipass -destination 'platform=iOS Simulator,name=iPhone 15'
```
Expected: TEST SUCCEEDED (placeholder tests pass)

- [ ] **Step 6: Commit**

```bash
git add .
git commit -m "feat: initial Xcode project setup"
```

### Task 1.2: Keychain Service

**Files:**
- Create: `Moltipass/Services/KeychainService.swift`
- Create: `MoltipassTests/Services/KeychainServiceTests.swift`

- [ ] **Step 1: Write failing test for save/retrieve**

```swift
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme Moltipass -destination 'platform=iOS Simulator,name=iPhone 15'`
Expected: FAIL - KeychainService not found

- [ ] **Step 3: Implement KeychainService**

```swift
import Foundation
import Security

final class KeychainService {
    private let serviceName = "com.moltipass.app"

    @discardableResult
    func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    @discardableResult
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme Moltipass -destination 'platform=iOS Simulator,name=iPhone 15'`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Moltipass/Services/KeychainService.swift MoltipassTests/
git commit -m "feat: add KeychainService for secure credential storage"
```

### Task 1.3: Date Formatting Extension

**Files:**
- Create: `Moltipass/Utilities/Extensions.swift`
- Create: `MoltipassTests/Utilities/ExtensionsTests.swift`

- [ ] **Step 1: Write failing test for relative time**

```swift
import XCTest
@testable import Moltipass

final class ExtensionsTests: XCTestCase {
    func testRelativeTimeJustNow() {
        let date = Date()
        XCTAssertEqual(date.relativeTime, "just now")
    }

    func testRelativeTimeMinutesAgo() {
        let date = Date().addingTimeInterval(-180) // 3 minutes ago
        XCTAssertEqual(date.relativeTime, "3m ago")
    }

    func testRelativeTimeHoursAgo() {
        let date = Date().addingTimeInterval(-7200) // 2 hours ago
        XCTAssertEqual(date.relativeTime, "2h ago")
    }

    func testRelativeTimeDaysAgo() {
        let date = Date().addingTimeInterval(-172800) // 2 days ago
        XCTAssertEqual(date.relativeTime, "2d ago")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL - relativeTime not found

- [ ] **Step 3: Implement Date extension**

```swift
import Foundation

extension Date {
    var relativeTime: String {
        let seconds = Int(-timeIntervalSinceNow)

        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            return "\(seconds / 60)m ago"
        } else if seconds < 86400 {
            return "\(seconds / 3600)h ago"
        } else {
            return "\(seconds / 86400)d ago"
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Moltipass/Utilities/ MoltipassTests/Utilities/
git commit -m "feat: add Date.relativeTime extension"
```

---

## Chunk 2: Models

### Task 2.1: Agent Model

**Files:**
- Create: `Moltipass/Models/Agent.swift`
- Create: `MoltipassTests/Models/AgentTests.swift`

- [ ] **Step 1: Write failing test for JSON decoding**

```swift
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
        XCTAssertFalse(agent.isFollowing)
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
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL - Agent not found

- [ ] **Step 3: Implement Agent model**

```swift
import Foundation

struct Agent: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    var bio: String?
    var avatarURL: URL?
    var postCount: Int?
    var commentCount: Int?
    var karma: Int?
    var isFollowing: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, bio
        case avatarURL = "avatar_url"
        case postCount = "post_count"
        case commentCount = "comment_count"
        case karma
        case isFollowing = "is_following"
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Moltipass/Models/Agent.swift MoltipassTests/Models/
git commit -m "feat: add Agent model"
```

### Task 2.2: Submolt Model

**Files:**
- Create: `Moltipass/Models/Submolt.swift`
- Create: `MoltipassTests/Models/SubmoltTests.swift`

- [ ] **Step 1: Write failing test**

```swift
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
```

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Implement Submolt model**

```swift
import Foundation

struct Submolt: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    var description: String?
    var subscriberCount: Int?
    var isSubscribed: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case subscriberCount = "subscriber_count"
        case isSubscribed = "is_subscribed"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        subscriberCount = try container.decodeIfPresent(Int.self, forKey: .subscriberCount)
        isSubscribed = try container.decodeIfPresent(Bool.self, forKey: .isSubscribed) ?? false
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add Moltipass/Models/Submolt.swift MoltipassTests/Models/SubmoltTests.swift
git commit -m "feat: add Submolt model"
```

### Task 2.3: Post Model

**Files:**
- Create: `Moltipass/Models/Post.swift`
- Create: `MoltipassTests/Models/PostTests.swift`

- [ ] **Step 1: Write failing test**

```swift
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
            "author": {
                "id": "agent_2",
                "name": "LinkBot"
            },
            "submolt": {
                "id": "submolt_2",
                "name": "links",
                "is_subscribed": false
            },
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
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Implement Post model**

```swift
import Foundation

struct Post: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    var body: String?
    var url: URL?
    let author: Agent
    let submolt: Submolt
    var voteCount: Int
    var commentCount: Int
    var userVote: Int? // 1 = upvote, -1 = downvote, nil = no vote
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, body, url, author, submolt
        case voteCount = "vote_count"
        case commentCount = "comment_count"
        case userVote = "user_vote"
        case createdAt = "created_at"
    }

    var isLinkPost: Bool {
        url != nil
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add Moltipass/Models/Post.swift MoltipassTests/Models/PostTests.swift
git commit -m "feat: add Post model"
```

### Task 2.4: Comment Model

**Files:**
- Create: `Moltipass/Models/Comment.swift`
- Create: `MoltipassTests/Models/CommentTests.swift`

- [ ] **Step 1: Write failing test**

```swift
import XCTest
@testable import Moltipass

final class CommentTests: XCTestCase {
    func testDecodeComment() throws {
        let json = """
        {
            "id": "comment_123",
            "body": "Great post!",
            "author": {
                "id": "agent_1",
                "name": "Commenter"
            },
            "parent_id": null,
            "vote_count": 5,
            "user_vote": 1,
            "created_at": "2026-01-30T14:00:00Z",
            "replies": []
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let comment = try decoder.decode(Comment.self, from: json)

        XCTAssertEqual(comment.id, "comment_123")
        XCTAssertEqual(comment.body, "Great post!")
        XCTAssertEqual(comment.author.name, "Commenter")
        XCTAssertNil(comment.parentId)
        XCTAssertEqual(comment.voteCount, 5)
        XCTAssertTrue(comment.replies.isEmpty)
    }

    func testDecodeNestedComments() throws {
        let json = """
        {
            "id": "comment_1",
            "body": "Parent comment",
            "author": {"id": "a1", "name": "Parent"},
            "parent_id": null,
            "vote_count": 10,
            "user_vote": null,
            "created_at": "2026-01-30T12:00:00Z",
            "replies": [
                {
                    "id": "comment_2",
                    "body": "Child reply",
                    "author": {"id": "a2", "name": "Child"},
                    "parent_id": "comment_1",
                    "vote_count": 3,
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
}
```

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Implement Comment model**

```swift
import Foundation

struct Comment: Codable, Identifiable, Equatable {
    let id: String
    let body: String
    let author: Agent
    var parentId: String?
    var voteCount: Int
    var userVote: Int?
    let createdAt: Date
    var replies: [Comment]

    enum CodingKeys: String, CodingKey {
        case id, body, author, replies
        case parentId = "parent_id"
        case voteCount = "vote_count"
        case userVote = "user_vote"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        body = try container.decode(String.self, forKey: .body)
        author = try container.decode(Agent.self, forKey: .author)
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
        userVote = try container.decodeIfPresent(Int.self, forKey: .userVote)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        replies = try container.decodeIfPresent([Comment].self, forKey: .replies) ?? []
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add Moltipass/Models/Comment.swift MoltipassTests/Models/CommentTests.swift
git commit -m "feat: add Comment model with nested replies"
```

### Task 2.5: API Response Wrappers

**Files:**
- Create: `Moltipass/Models/APIResponse.swift`
- Create: `MoltipassTests/Models/APIResponseTests.swift`

- [ ] **Step 1: Write failing test**

```swift
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
```

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Implement API response types**

```swift
import Foundation

struct RegistrationResponse: Codable {
    let apiKey: String
    let claimURL: URL
    let verificationCode: String

    enum CodingKeys: String, CodingKey {
        case apiKey = "api_key"
        case claimURL = "claim_url"
        case verificationCode = "verification_code"
    }
}

struct StatusResponse: Codable {
    let status: ClaimStatus

    enum ClaimStatus: String, Codable {
        case pendingClaim = "pending_claim"
        case claimed = "claimed"
    }
}

struct APIError: Codable, Error {
    let error: String
    var retryAfterMinutes: Int?
    var message: String?

    enum CodingKeys: String, CodingKey {
        case error, message
        case retryAfterMinutes = "retry_after_minutes"
    }
}

struct FeedResponse: Codable {
    let posts: [Post]
    var nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case posts
        case nextCursor = "next_cursor"
    }
}

struct CommentsResponse: Codable {
    let comments: [Comment]
}

struct SearchResponse: Codable {
    var posts: [Post]?
    var agents: [Agent]?
    var submolts: [Submolt]?
}
```

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add Moltipass/Models/APIResponse.swift MoltipassTests/Models/APIResponseTests.swift
git commit -m "feat: add API response wrapper types"
```

---

## Chunk 3: MoltbookAPI Service

### Task 3.1: MockURLProtocol for Testing

**Files:**
- Create: `MoltipassTests/Helpers/MockURLProtocol.swift`

- [ ] **Step 1: Create MockURLProtocol for API testing**

```swift
import Foundation

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("MockURLProtocol.requestHandler not set")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
```

- [ ] **Step 2: Commit**

```bash
git add MoltipassTests/Helpers/MockURLProtocol.swift
git commit -m "feat: add MockURLProtocol for API testing"
```

### Task 3.2: API Client Foundation

**Files:**
- Create: `Moltipass/Services/MoltbookAPI.swift`
- Create: `MoltipassTests/Services/MoltbookAPITests.swift`

- [ ] **Step 1: Write failing test for request building**

```swift
import XCTest
@testable import Moltipass

final class MoltbookAPITests: XCTestCase {
    var api: MoltbookAPI!
    var mockSession: URLSession!

    @MainActor
    override func setUp() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)
        api = MoltbookAPI(apiKey: "test_key", session: mockSession)
    }

    @MainActor
    func testBuildAuthenticatedRequest() {
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
}
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL - MoltbookAPI not found

- [ ] **Step 3: Implement MoltbookAPI foundation**

```swift
import Foundation

@MainActor
final class MoltbookAPI: ObservableObject {
    private let baseURL = "https://www.moltbook.com/api/v1"
    private var apiKey: String?
    private let session: URLSession
    private let decoder: JSONDecoder

    @Published var isAuthenticated = false

    init(apiKey: String? = nil, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.isAuthenticated = apiKey != nil
    }

    func setAPIKey(_ key: String) {
        self.apiKey = key
        self.isAuthenticated = true
    }

    func clearAPIKey() {
        self.apiKey = nil
        self.isAuthenticated = false
    }

    // Internal for testing
    func buildRequest(endpoint: String, method: String, body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: URL(string: baseURL + endpoint)!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = body
        }

        return request
    }

    func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(error: "invalid_response")
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try decoder.decode(T.self, from: data)
        case 401:
            throw APIError(error: "unauthorized", message: "Invalid or expired API key")
        case 404:
            throw APIError(error: "not_found", message: "Resource not found")
        case 429:
            let errorResponse = try? decoder.decode(APIError.self, from: data)
            throw errorResponse ?? APIError(error: "rate_limited")
        default:
            let errorResponse = try? decoder.decode(APIError.self, from: data)
            throw errorResponse ?? APIError(error: "unknown", message: "HTTP \(httpResponse.statusCode)")
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add Moltipass/Services/MoltbookAPI.swift MoltipassTests/Services/MoltbookAPITests.swift
git commit -m "feat: add MoltbookAPI foundation with request building"
```

### Task 3.3: Registration & Status Endpoints

**Files:**
- Modify: `Moltipass/Services/MoltbookAPI.swift`
- Modify: `MoltipassTests/Services/MoltbookAPITests.swift`

- [ ] **Step 1: Write failing test for register**

Add to MoltbookAPITests.swift:

```swift
@MainActor
func testRegister() async throws {
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
```

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Implement register and checkStatus**

Add to MoltbookAPI.swift:

```swift
func register() async throws -> RegistrationResponse {
    let request = buildRequest(endpoint: "/agents/register", method: "POST")
    return try await perform(request)
}

func checkStatus() async throws -> StatusResponse {
    let request = buildRequest(endpoint: "/agents/status", method: "GET")
    return try await perform(request)
}
```

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add Moltipass/Services/MoltbookAPI.swift MoltipassTests/Services/MoltbookAPITests.swift
git commit -m "feat: add register and checkStatus API methods"
```

### Task 3.4: Feed & Posts Endpoints

**Files:**
- Modify: `Moltipass/Services/MoltbookAPI.swift`
- Modify: `MoltipassTests/Services/MoltbookAPITests.swift`

- [ ] **Step 1: Write failing test for getFeed**

Add to MoltbookAPITests.swift:

```swift
@MainActor
func testGetFeed() async throws {
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
```

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Implement feed and post methods**

Add to MoltbookAPI.swift:

```swift
enum FeedSort: String {
    case hot, new, top, rising
}

func getFeed(sort: FeedSort = .hot, cursor: String? = nil) async throws -> FeedResponse {
    var endpoint = "/posts?sort=\(sort.rawValue)"
    if let cursor = cursor {
        endpoint += "&cursor=\(cursor)"
    }
    let request = buildRequest(endpoint: endpoint, method: "GET")
    return try await perform(request)
}

func getSubmoltFeed(submoltId: String, sort: FeedSort = .hot, cursor: String? = nil) async throws -> FeedResponse {
    var endpoint = "/submolts/\(submoltId)/posts?sort=\(sort.rawValue)"
    if let cursor = cursor {
        endpoint += "&cursor=\(cursor)"
    }
    let request = buildRequest(endpoint: endpoint, method: "GET")
    return try await perform(request)
}

func getPost(id: String) async throws -> Post {
    let request = buildRequest(endpoint: "/posts/\(id)", method: "GET")
    return try await perform(request)
}

struct CreatePostRequest: Encodable {
    let title: String
    let body: String?
    let url: String?
    let submoltId: String

    enum CodingKeys: String, CodingKey {
        case title, body, url
        case submoltId = "submolt_id"
    }
}

func createPost(title: String, body: String?, url: String?, submoltId: String) async throws -> Post {
    let payload = CreatePostRequest(title: title, body: body, url: url, submoltId: submoltId)
    let data = try JSONEncoder().encode(payload)
    let request = buildRequest(endpoint: "/posts", method: "POST", body: data)
    return try await perform(request)
}

func deletePost(id: String) async throws {
    let request = buildRequest(endpoint: "/posts/\(id)", method: "DELETE")
    let _: EmptyResponse = try await perform(request)
}

struct EmptyResponse: Decodable {}
```

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add Moltipass/Services/MoltbookAPI.swift MoltipassTests/Services/MoltbookAPITests.swift
git commit -m "feat: add feed and post API methods"
```

### Task 3.5: Comments, Voting, Submolts, Search, Profile Endpoints

**Files:**
- Modify: `Moltipass/Services/MoltbookAPI.swift`

- [ ] **Step 1: Add remaining API methods**

Add to MoltbookAPI.swift:

```swift
// MARK: - Comments

enum CommentSort: String {
    case top, new, controversial
}

func getComments(postId: String, sort: CommentSort = .top) async throws -> CommentsResponse {
    let request = buildRequest(endpoint: "/posts/\(postId)/comments?sort=\(sort.rawValue)", method: "GET")
    return try await perform(request)
}

struct CreateCommentRequest: Encodable {
    let body: String
    let parentId: String?

    enum CodingKeys: String, CodingKey {
        case body
        case parentId = "parent_id"
    }
}

func createComment(postId: String, body: String, parentId: String? = nil) async throws -> Comment {
    let payload = CreateCommentRequest(body: body, parentId: parentId)
    let data = try JSONEncoder().encode(payload)
    let request = buildRequest(endpoint: "/posts/\(postId)/comments", method: "POST", body: data)
    return try await perform(request)
}

// MARK: - Voting

struct VoteRequest: Encodable {
    let direction: Int
}

func votePost(id: String, direction: Int) async throws {
    let payload = VoteRequest(direction: direction)
    let data = try JSONEncoder().encode(payload)
    let request = buildRequest(endpoint: "/posts/\(id)/vote", method: "POST", body: data)
    let _: EmptyResponse = try await perform(request)
}

func voteComment(id: String, direction: Int) async throws {
    let payload = VoteRequest(direction: direction)
    let data = try JSONEncoder().encode(payload)
    let request = buildRequest(endpoint: "/comments/\(id)/vote", method: "POST", body: data)
    let _: EmptyResponse = try await perform(request)
}

// MARK: - Submolts

struct SubmoltsResponse: Decodable {
    let submolts: [Submolt]
}

func getSubscribedSubmolts() async throws -> SubmoltsResponse {
    let request = buildRequest(endpoint: "/submolts/subscribed", method: "GET")
    return try await perform(request)
}

func getPopularSubmolts() async throws -> SubmoltsResponse {
    let request = buildRequest(endpoint: "/submolts/popular", method: "GET")
    return try await perform(request)
}

func getSubmolt(id: String) async throws -> Submolt {
    let request = buildRequest(endpoint: "/submolts/\(id)", method: "GET")
    return try await perform(request)
}

func subscribe(submoltId: String) async throws {
    let request = buildRequest(endpoint: "/submolts/\(submoltId)/subscribe", method: "POST")
    let _: EmptyResponse = try await perform(request)
}

func unsubscribe(submoltId: String) async throws {
    let request = buildRequest(endpoint: "/submolts/\(submoltId)/unsubscribe", method: "POST")
    let _: EmptyResponse = try await perform(request)
}

// MARK: - Search

enum SearchScope: String {
    case posts, agents, submolts
}

func search(query: String, scope: SearchScope) async throws -> SearchResponse {
    let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
    let request = buildRequest(endpoint: "/search?q=\(encodedQuery)&scope=\(scope.rawValue)", method: "GET")
    return try await perform(request)
}

// MARK: - Profile

func getMyProfile() async throws -> Agent {
    let request = buildRequest(endpoint: "/agents/me", method: "GET")
    return try await perform(request)
}

struct UpdateProfileRequest: Encodable {
    let name: String?
    let bio: String?
}

func updateProfile(name: String?, bio: String?) async throws -> Agent {
    let payload = UpdateProfileRequest(name: name, bio: bio)
    let data = try JSONEncoder().encode(payload)
    let request = buildRequest(endpoint: "/agents/me", method: "PATCH", body: data)
    return try await perform(request)
}

func uploadAvatar(imageData: Data) async throws -> Agent {
    var request = URLRequest(url: URL(string: baseURL + "/agents/me/avatar")!)
    request.httpMethod = "POST"

    let boundary = UUID().uuidString
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    if let apiKey = apiKey {
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    }

    var body = Data()
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
    body.append(imageData)
    body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
    request.httpBody = body

    return try await perform(request)
}

func getAgent(id: String) async throws -> Agent {
    let request = buildRequest(endpoint: "/agents/\(id)", method: "GET")
    return try await perform(request)
}

func getAgentPosts(id: String) async throws -> FeedResponse {
    let request = buildRequest(endpoint: "/agents/\(id)/posts", method: "GET")
    return try await perform(request)
}

// MARK: - Following

struct FollowingResponse: Decodable {
    let agents: [Agent]
}

func getFollowing() async throws -> FollowingResponse {
    let request = buildRequest(endpoint: "/agents/me/following", method: "GET")
    return try await perform(request)
}

func follow(agentId: String) async throws {
    let request = buildRequest(endpoint: "/agents/\(agentId)/follow", method: "POST")
    let _: EmptyResponse = try await perform(request)
}

func unfollow(agentId: String) async throws {
    let request = buildRequest(endpoint: "/agents/\(agentId)/unfollow", method: "POST")
    let _: EmptyResponse = try await perform(request)
}
```

- [ ] **Step 2: Commit**

```bash
git add Moltipass/Services/MoltbookAPI.swift
git commit -m "feat: add remaining API methods (comments, voting, submolts, search, profile)"
```

---

## Chunk 4: Onboarding Views

### Task 4.1: App State & Root View

**Files:**
- Create: `Moltipass/App/AppState.swift`
- Modify: `Moltipass/App/MoltipassApp.swift`

- [ ] **Step 1: Create AppState to manage auth flow**

```swift
import SwiftUI

@MainActor
@Observable
class AppState {
    enum AuthStatus {
        case unknown
        case unauthenticated
        case pendingClaim(verificationCode: String)
        case authenticated
    }

    var authStatus: AuthStatus = .unknown
    let api: MoltbookAPI
    private let keychain = KeychainService()
    private let apiKeyKey = "moltbook_api_key"

    init() {
        if let apiKey = keychain.retrieve(key: apiKeyKey) {
            api = MoltbookAPI(apiKey: apiKey)
        } else {
            api = MoltbookAPI()
        }
    }

    private let verificationCodeKey = "moltbook_verification_code"

    func checkAuthStatus() async {
        guard let _ = keychain.retrieve(key: apiKeyKey) else {
            authStatus = .unauthenticated
            return
        }

        do {
            let status = try await api.checkStatus()
            switch status.status {
            case .claimed:
                authStatus = .authenticated
            case .pendingClaim:
                // Retrieve stored verification code for pending claim state
                if let code = keychain.retrieve(key: verificationCodeKey) {
                    authStatus = .pendingClaim(verificationCode: code)
                } else {
                    authStatus = .unauthenticated
                }
            }
        } catch {
            authStatus = .unauthenticated
        }
    }

    func saveCredentials(apiKey: String, verificationCode: String) {
        keychain.save(key: apiKeyKey, value: apiKey)
        keychain.save(key: verificationCodeKey, value: verificationCode)
        api.setAPIKey(apiKey)
        authStatus = .pendingClaim(verificationCode: verificationCode)
    }

    func completeAuthentication() {
        authStatus = .authenticated
    }

    func signOut() {
        keychain.delete(key: apiKeyKey)
        api.clearAPIKey()
        authStatus = .unauthenticated
    }
}
```

- [ ] **Step 2: Update MoltipassApp to use AppState**

```swift
import SwiftUI

@main
struct MoltipassApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
    }
}
```

- [ ] **Step 3: Create RootView**

Create `Moltipass/Views/RootView.swift`:

```swift
import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            switch appState.authStatus {
            case .unknown:
                ProgressView("Loading...")
                    .task { await appState.checkAuthStatus() }
            case .unauthenticated:
                WelcomeView()
            case .pendingClaim(let code):
                ClaimInstructionsView(verificationCode: code)
            case .authenticated:
                MainTabView()
            }
        }
    }
}
```

- [ ] **Step 4: Create placeholder MainTabView**

Create `Moltipass/Views/MainTabView.swift`:

```swift
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Text("Feed")
                .tabItem { Label("Feed", systemImage: "house") }
            Text("Submolts")
                .tabItem { Label("Submolts", systemImage: "square.stack") }
            Text("Search")
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
            Text("Profile")
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}
```

- [ ] **Step 5: Commit**

```bash
git add Moltipass/
git commit -m "feat: add AppState and root navigation"
```

### Task 4.2: Welcome & Registration Views

**Files:**
- Create: `Moltipass/Views/Onboarding/WelcomeView.swift`
- Create: `Moltipass/Views/Onboarding/RegistrationView.swift`

- [ ] **Step 1: Create WelcomeView**

```swift
import SwiftUI

struct WelcomeView: View {
    @State private var showRegistration = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("Moltipass")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Your gateway to Moltbook")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Get Started") {
                showRegistration = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .sheet(isPresented: $showRegistration) {
            RegistrationView()
        }
    }
}
```

- [ ] **Step 2: Create RegistrationView**

```swift
import SwiftUI

struct RegistrationView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Registering your agent...")
                } else if let error = error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.red)
                        Text(error)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            self.error = nil
                            Task { await register() }
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)

                        Text("Create Your Agent")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("We'll register a new agent on Moltbook for you to claim.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Register New Agent") {
                            Task { await register() }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
            }
            .padding()
            .navigationTitle("Registration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func register() async {
        isLoading = true
        error = nil

        do {
            let response = try await appState.api.register()
            appState.saveCredentials(apiKey: response.apiKey, verificationCode: response.verificationCode)
            dismiss()
        } catch let apiError as APIError {
            error = apiError.message ?? apiError.error
        } catch {
            self.error = "Network error. Please check your connection."
        }

        isLoading = false
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add Moltipass/Views/Onboarding/
git commit -m "feat: add Welcome and Registration views"
```

### Task 4.3: Claim Instructions & Verification Views

**Files:**
- Create: `Moltipass/Views/Onboarding/ClaimInstructionsView.swift`

- [ ] **Step 1: Create ClaimInstructionsView**

```swift
import SwiftUI

struct ClaimInstructionsView: View {
    @Environment(AppState.self) private var appState
    let verificationCode: String

    @State private var isVerifying = false
    @State private var error: String?
    @State private var pollCount = 0
    private let maxPolls = 40 // 2 minutes at 3 second intervals

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.seal")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Claim Your Agent")
                    .font(.title2)
                    .fontWeight(.semibold)

                VStack(spacing: 8) {
                    Text("Post this code on Twitter/X:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(verificationCode)
                        .font(.system(.title, design: .monospaced))
                        .fontWeight(.bold)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    Button("Copy Code") {
                        UIPasteboard.general.string = verificationCode
                    }
                    .font(.caption)
                }

                Button("Open Twitter") {
                    openTwitter()
                }
                .buttonStyle(.borderedProminent)

                Divider()

                if isVerifying {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Verifying your claim...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if let error = error {
                    VStack(spacing: 8) {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.subheadline)
                        Button("Try Again") {
                            Task { await startVerification() }
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    Button("I've Posted It") {
                        Task { await startVerification() }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationTitle("Verification")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func openTwitter() {
        let tweetText = verificationCode
        let encodedText = tweetText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? tweetText
        if let url = URL(string: "twitter://post?message=\(encodedText)") {
            UIApplication.shared.open(url) { success in
                if !success, let webURL = URL(string: "https://twitter.com/intent/tweet?text=\(encodedText)") {
                    UIApplication.shared.open(webURL)
                }
            }
        }
    }

    private func startVerification() async {
        isVerifying = true
        error = nil
        pollCount = 0

        while pollCount < maxPolls {
            do {
                let status = try await appState.api.checkStatus()
                if status.status == .claimed {
                    appState.completeAuthentication()
                    return
                }
            } catch {
                // Continue polling on error
            }

            pollCount += 1
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        }

        isVerifying = false
        error = "Verification timed out. Make sure you posted the code and try again."
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Moltipass/Views/Onboarding/ClaimInstructionsView.swift
git commit -m "feat: add ClaimInstructionsView with polling"
```

---

## Chunk 5: Feed Views

### Task 5.1: Feed View

**Files:**
- Create: `Moltipass/Views/Feed/FeedView.swift`
- Create: `Moltipass/Views/Feed/FeedViewModel.swift`

- [ ] **Step 1: Create FeedViewModel**

```swift
import SwiftUI

@MainActor
@Observable
class FeedViewModel {
    var posts: [Post] = []
    var isLoading = false
    var error: String?
    var selectedSort: FeedSort = .hot
    private var nextCursor: String?

    private let api: MoltbookAPI

    init(api: MoltbookAPI) {
        self.api = api
    }

    func loadFeed(refresh: Bool = false) async {
        if refresh {
            nextCursor = nil
        }

        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            let response = try await api.getFeed(sort: selectedSort, cursor: refresh ? nil : nextCursor)
            if refresh {
                posts = response.posts
            } else {
                posts.append(contentsOf: response.posts)
            }
            nextCursor = response.nextCursor
        } catch let apiError as APIError {
            error = apiError.message ?? apiError.error
        } catch {
            self.error = "Failed to load feed"
        }

        isLoading = false
    }

    func vote(post: Post, direction: Int) async {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }

        // Optimistic update
        let oldVote = posts[index].userVote
        let oldCount = posts[index].voteCount

        if posts[index].userVote == direction {
            posts[index].userVote = nil
            posts[index].voteCount -= direction
        } else {
            if let oldVote = oldVote {
                posts[index].voteCount -= oldVote
            }
            posts[index].userVote = direction
            posts[index].voteCount += direction
        }

        do {
            try await api.votePost(id: post.id, direction: posts[index].userVote ?? 0)
        } catch {
            // Revert on error
            posts[index].userVote = oldVote
            posts[index].voteCount = oldCount
        }
    }
}
```

- [ ] **Step 2: Create FeedView**

```swift
import SwiftUI

struct FeedView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: FeedViewModel?
    @State private var showCompose = false

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    FeedContent(viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Feed")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCompose = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCompose) {
                ComposePostView()
            }
        }
        .task {
            if viewModel == nil {
                viewModel = FeedViewModel(api: appState.api)
                await viewModel?.loadFeed()
            }
        }
    }
}

struct FeedContent: View {
    @Bindable var viewModel: FeedViewModel

    var body: some View {
        VStack(spacing: 0) {
            Picker("Sort", selection: $viewModel.selectedSort) {
                Text("Hot").tag(FeedSort.hot)
                Text("New").tag(FeedSort.new)
                Text("Top").tag(FeedSort.top)
                Text("Rising").tag(FeedSort.rising)
            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: viewModel.selectedSort) {
                Task { await viewModel.loadFeed(refresh: true) }
            }

            if let error = viewModel.error {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry") {
                        Task { await viewModel.loadFeed(refresh: true) }
                    }
                }
            } else {
                List {
                    ForEach(viewModel.posts) { post in
                        NavigationLink(value: post) {
                            PostCellView(post: post) { direction in
                                Task { await viewModel.vote(post: post, direction: direction) }
                            }
                        }
                    }

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.loadFeed(refresh: true)
                }
                .navigationDestination(for: Post.self) { post in
                    PostDetailView(post: post)
                }
            }
        }
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add Moltipass/Views/Feed/
git commit -m "feat: add FeedView with sort and pull-to-refresh"
```

### Task 5.2: Post Cell View

**Files:**
- Create: `Moltipass/Views/Feed/PostCellView.swift`

- [ ] **Step 1: Create PostCellView**

```swift
import SwiftUI

struct PostCellView: View {
    let post: Post
    var onVote: ((Int) -> Void)?
    var onTapAgent: ((Agent) -> Void)?
    var onTapSubmolt: ((Submolt) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    onTapAgent?(post.author)
                } label: {
                    HStack(spacing: 8) {
                        AsyncImage(url: post.author.avatarURL) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())

                        Text(post.author.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Text("•")
                    .foregroundStyle(.secondary)

                Button {
                    onTapSubmolt?(post.submolt)
                } label: {
                    Text(post.submolt.name)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }

            Text(post.title)
                .font(.headline)
                .lineLimit(2)

            if post.isLinkPost, let url = post.url {
                Text(url.host ?? url.absoluteString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Button {
                        onVote?(1)
                    } label: {
                        Image(systemName: post.userVote == 1 ? "arrow.up.circle.fill" : "arrow.up.circle")
                            .foregroundStyle(post.userVote == 1 ? .orange : .secondary)
                    }
                    .buttonStyle(.plain)

                    Text("\(post.voteCount)")
                        .font(.subheadline)
                        .monospacedDigit()

                    Button {
                        onVote?(-1)
                    } label: {
                        Image(systemName: post.userVote == -1 ? "arrow.down.circle.fill" : "arrow.down.circle")
                            .foregroundStyle(post.userVote == -1 ? .purple : .secondary)
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                        .foregroundStyle(.secondary)
                    Text("\(post.commentCount)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(post.createdAt.relativeTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Moltipass/Views/Feed/PostCellView.swift
git commit -m "feat: add PostCellView with voting"
```

---

## Chunk 6: Post Detail & Comments

### Task 6.1: Post Detail View

**Files:**
- Create: `Moltipass/Views/Post/PostDetailView.swift`
- Create: `Moltipass/Views/Post/PostDetailViewModel.swift`

- [ ] **Step 1: Create PostDetailViewModel**

```swift
import SwiftUI

@MainActor
@Observable
class PostDetailViewModel {
    var post: Post
    var comments: [Comment] = []
    var isLoading = false
    var error: String?
    var selectedSort: CommentSort = .top

    private let api: MoltbookAPI

    init(post: Post, api: MoltbookAPI) {
        self.post = post
        self.api = api
    }

    func loadComments() async {
        isLoading = true
        error = nil

        do {
            let response = try await api.getComments(postId: post.id, sort: selectedSort)
            comments = response.comments
        } catch {
            self.error = "Failed to load comments"
        }

        isLoading = false
    }

    func votePost(direction: Int) async {
        let oldVote = post.userVote
        let oldCount = post.voteCount

        if post.userVote == direction {
            post.userVote = nil
            post.voteCount -= direction
        } else {
            if let oldVote = oldVote {
                post.voteCount -= oldVote
            }
            post.userVote = direction
            post.voteCount += direction
        }

        do {
            try await api.votePost(id: post.id, direction: post.userVote ?? 0)
        } catch {
            post.userVote = oldVote
            post.voteCount = oldCount
        }
    }
}
```

- [ ] **Step 2: Create PostDetailView**

```swift
import SwiftUI

struct PostDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: PostDetailViewModel?
    @State private var showCompose = false
    let post: Post

    var body: some View {
        Group {
            if let viewModel = viewModel {
                PostDetailContent(viewModel: viewModel, showCompose: $showCompose)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCompose = true
                } label: {
                    Image(systemName: "arrowshape.turn.up.left")
                }
            }
        }
        .sheet(isPresented: $showCompose) {
            if let viewModel = viewModel {
                ComposeCommentView(postId: viewModel.post.id)
            }
        }
        .task {
            if viewModel == nil {
                viewModel = PostDetailViewModel(post: post, api: appState.api)
                await viewModel?.loadComments()
            }
        }
    }
}

struct PostDetailContent: View {
    @Bindable var viewModel: PostDetailViewModel
    @Binding var showCompose: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Post header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        AsyncImage(url: viewModel.post.author.avatarURL) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())

                        VStack(alignment: .leading) {
                            Text(viewModel.post.author.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(viewModel.post.submolt.name)
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }

                        Spacer()

                        Text(viewModel.post.createdAt.relativeTime)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(viewModel.post.title)
                        .font(.title3)
                        .fontWeight(.semibold)

                    if let body = viewModel.post.body {
                        Text(body)
                            .font(.body)
                    }

                    if viewModel.post.isLinkPost, let url = viewModel.post.url {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "link")
                                Text(url.host ?? url.absoluteString)
                            }
                            .font(.subheadline)
                        }
                    }

                    // Vote buttons
                    HStack(spacing: 16) {
                        Button {
                            Task { await viewModel.votePost(direction: 1) }
                        } label: {
                            Label("\(viewModel.post.voteCount)", systemImage: viewModel.post.userVote == 1 ? "arrow.up.circle.fill" : "arrow.up.circle")
                        }
                        .foregroundStyle(viewModel.post.userVote == 1 ? .orange : .primary)

                        Button {
                            Task { await viewModel.votePost(direction: -1) }
                        } label: {
                            Image(systemName: viewModel.post.userVote == -1 ? "arrow.down.circle.fill" : "arrow.down.circle")
                        }
                        .foregroundStyle(viewModel.post.userVote == -1 ? .purple : .primary)

                        Button {
                            showCompose = true
                        } label: {
                            Label("Reply", systemImage: "arrowshape.turn.up.left")
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()

                Divider()

                // Comments section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Comments")
                            .font(.headline)
                        Spacer()
                        Picker("Sort", selection: $viewModel.selectedSort) {
                            Text("Top").tag(CommentSort.top)
                            Text("New").tag(CommentSort.new)
                            Text("Controversial").tag(CommentSort.controversial)
                        }
                        .onChange(of: viewModel.selectedSort) {
                            Task { await viewModel.loadComments() }
                        }
                    }
                    .padding(.horizontal)

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if viewModel.comments.isEmpty {
                        Text("No comments yet")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        ForEach(viewModel.comments) { comment in
                            CommentView(comment: comment, depth: 0)
                        }
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add Moltipass/Views/Post/
git commit -m "feat: add PostDetailView with comments"
```

### Task 6.2: Comment View

**Files:**
- Create: `Moltipass/Views/Post/CommentView.swift`

- [ ] **Step 1: Create CommentView (recursive for nesting)**

```swift
import SwiftUI

struct CommentView: View {
    @Environment(AppState.self) private var appState
    let comment: Comment
    let postId: String
    let depth: Int
    var onVote: ((Comment, Int) -> Void)?
    @State private var showReply = false

    private let maxDepth = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                AsyncImage(url: comment.author.avatarURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .frame(width: 20, height: 20)
                .clipShape(Circle())

                Text(comment.author.name)
                    .font(.caption)
                    .fontWeight(.medium)

                Text("•")
                    .foregroundStyle(.secondary)

                Text(comment.createdAt.relativeTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(comment.body)
                .font(.subheadline)

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Button {
                        onVote?(comment, 1)
                    } label: {
                        Image(systemName: comment.userVote == 1 ? "arrow.up.circle.fill" : "arrow.up.circle")
                            .foregroundStyle(comment.userVote == 1 ? .orange : .secondary)
                    }
                    .buttonStyle(.plain)

                    Text("\(comment.voteCount)")
                        .font(.caption)

                    Button {
                        onVote?(comment, -1)
                    } label: {
                        Image(systemName: comment.userVote == -1 ? "arrow.down.circle.fill" : "arrow.down.circle")
                            .foregroundStyle(comment.userVote == -1 ? .purple : .secondary)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    showReply = true
                } label: {
                    Label("Reply", systemImage: "arrowshape.turn.up.left")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            // Nested replies
            if depth < maxDepth && !comment.replies.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(comment.replies) { reply in
                        CommentView(comment: reply, postId: postId, depth: depth + 1, onVote: onVote)
                    }
                }
                .padding(.leading, 16)
            } else if depth >= maxDepth && !comment.replies.isEmpty {
                Button {
                    // Navigate to thread
                } label: {
                    Text("Continue thread →")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                .padding(.leading, 16)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .sheet(isPresented: $showReply) {
            ComposeCommentView(postId: postId, parentId: comment.id)
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Moltipass/Views/Post/CommentView.swift
git commit -m "feat: add CommentView with nested replies"
```

---

## Chunk 7: Compose Views

### Task 7.1: Compose Post View

**Files:**
- Create: `Moltipass/Views/Compose/ComposePostView.swift`

- [ ] **Step 1: Create ComposePostView**

```swift
import SwiftUI

struct ComposePostView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var body = ""
    @State private var url = ""
    @State private var isLinkPost = false
    @State private var selectedSubmolt: Submolt?
    @State private var submolts: [Submolt] = []
    @State private var isLoading = false
    @State private var isSubmitting = false
    @State private var error: String?

    private var canSubmit: Bool {
        !title.isEmpty && selectedSubmolt != nil && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Post Type") {
                    Picker("Type", selection: $isLinkPost) {
                        Text("Text").tag(false)
                        Text("Link").tag(true)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Content") {
                    TextField("Title", text: $title)

                    if isLinkPost {
                        TextField("URL", text: $url)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    } else {
                        TextField("Body (optional)", text: $body, axis: .vertical)
                            .lineLimit(5...10)
                    }
                }

                Section("Community") {
                    if isLoading {
                        ProgressView()
                    } else {
                        Picker("Submolt", selection: $selectedSubmolt) {
                            Text("Select a community").tag(nil as Submolt?)
                            ForEach(submolts) { submolt in
                                Text(submolt.name).tag(submolt as Submolt?)
                            }
                        }
                    }
                }

                if let error = error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        Task { await submit() }
                    }
                    .disabled(!canSubmit)
                }
            }
            .task {
                await loadSubmolts()
            }
        }
    }

    private func loadSubmolts() async {
        isLoading = true
        do {
            let response = try await appState.api.getSubscribedSubmolts()
            submolts = response.submolts
        } catch {
            self.error = "Failed to load communities"
        }
        isLoading = false
    }

    private func submit() async {
        guard let submolt = selectedSubmolt else { return }

        isSubmitting = true
        error = nil

        do {
            _ = try await appState.api.createPost(
                title: title,
                body: isLinkPost ? nil : (body.isEmpty ? nil : body),
                url: isLinkPost ? url : nil,
                submoltId: submolt.id
            )
            dismiss()
        } catch let apiError as APIError {
            if apiError.error == "rate_limited", let minutes = apiError.retryAfterMinutes {
                error = "You can post again in \(minutes) minutes"
            } else {
                error = apiError.message ?? apiError.error
            }
        } catch {
            self.error = "Failed to create post"
        }

        isSubmitting = false
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Moltipass/Views/Compose/ComposePostView.swift
git commit -m "feat: add ComposePostView with rate limit handling"
```

### Task 7.2: Compose Comment View

**Files:**
- Create: `Moltipass/Views/Compose/ComposeCommentView.swift`

- [ ] **Step 1: Create ComposeCommentView**

```swift
import SwiftUI

struct ComposeCommentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let postId: String
    var parentId: String?

    @State private var body = ""
    @State private var isSubmitting = false
    @State private var error: String?

    private var canSubmit: Bool {
        !body.isEmpty && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Write a comment...", text: $body, axis: .vertical)
                        .lineLimit(3...10)
                }

                if let error = error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(parentId != nil ? "Reply" : "Comment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        Task { await submit() }
                    }
                    .disabled(!canSubmit)
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        error = nil

        do {
            _ = try await appState.api.createComment(postId: postId, body: body, parentId: parentId)
            dismiss()
        } catch let apiError as APIError {
            if apiError.error == "rate_limited" {
                error = "Comment rate limit reached. Please wait."
            } else {
                error = apiError.message ?? apiError.error
            }
        } catch {
            self.error = "Failed to post comment"
        }

        isSubmitting = false
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Moltipass/Views/Compose/ComposeCommentView.swift
git commit -m "feat: add ComposeCommentView"
```

---

## Chunk 8: Submolts, Search, Profile Views

### Task 8.1: Submolts Tab

**Files:**
- Create: `Moltipass/Views/Submolts/SubmoltsView.swift`
- Create: `Moltipass/Views/Submolts/SubmoltDetailView.swift`

- [ ] **Step 1: Create SubmoltsView**

```swift
import SwiftUI

struct SubmoltsView: View {
    @Environment(AppState.self) private var appState
    @State private var subscribedSubmolts: [Submolt] = []
    @State private var popularSubmolts: [Submolt] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            List {
                Section("Your Communities") {
                    if subscribedSubmolts.isEmpty {
                        Text("You haven't joined any communities yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(subscribedSubmolts) { submolt in
                            NavigationLink(value: submolt) {
                                SubmoltRowView(submolt: submolt)
                            }
                        }
                    }
                }

                Section("Discover") {
                    ForEach(popularSubmolts) { submolt in
                        NavigationLink(value: submolt) {
                            SubmoltRowView(submolt: submolt)
                        }
                    }
                }
            }
            .navigationTitle("Submolts")
            .navigationDestination(for: Submolt.self) { submolt in
                SubmoltDetailView(submolt: submolt)
            }
            .refreshable {
                await loadSubmolts()
            }
            .task {
                await loadSubmolts()
            }
        }
    }

    private func loadSubmolts() async {
        isLoading = true
        async let subscribed = appState.api.getSubscribedSubmolts()
        async let popular = appState.api.getPopularSubmolts()

        do {
            subscribedSubmolts = try await subscribed.submolts
            popularSubmolts = try await popular.submolts
        } catch {
            // Handle error
        }
        isLoading = false
    }
}

struct SubmoltRowView: View {
    let submolt: Submolt

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(submolt.name)
                .font(.headline)
            if let count = submolt.subscriberCount {
                Text("\(count) members")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

- [ ] **Step 2: Create SubmoltDetailView**

```swift
import SwiftUI

struct SubmoltDetailView: View {
    @Environment(AppState.self) private var appState
    let submolt: Submolt
    @State private var posts: [Post] = []
    @State private var isSubscribed: Bool
    @State private var isLoading = false

    init(submolt: Submolt) {
        self.submolt = submolt
        self._isSubscribed = State(initialValue: submolt.isSubscribed)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    if let description = submolt.description {
                        Text(description)
                            .font(.subheadline)
                    }
                    if let count = submolt.subscriberCount {
                        Text("\(count) members")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button(isSubscribed ? "Unsubscribe" : "Subscribe") {
                        Task { await toggleSubscription() }
                    }
                    .buttonStyle(.bordered)
                }
            }

            Section("Posts") {
                ForEach(posts) { post in
                    NavigationLink(value: post) {
                        PostCellView(post: post)
                    }
                }
            }
        }
        .navigationTitle(submolt.name)
        .navigationDestination(for: Post.self) { post in
            PostDetailView(post: post)
        }
        .task {
            await loadPosts()
        }
    }

    private func loadPosts() async {
        do {
            let response = try await appState.api.getSubmoltFeed(submoltId: submolt.id)
            posts = response.posts
        } catch {}
    }

    private func toggleSubscription() async {
        do {
            if isSubscribed {
                try await appState.api.unsubscribe(submoltId: submolt.id)
            } else {
                try await appState.api.subscribe(submoltId: submolt.id)
            }
            isSubscribed.toggle()
        } catch {}
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add Moltipass/Views/Submolts/
git commit -m "feat: add Submolts tab and detail views"
```

### Task 8.2: Search View

**Files:**
- Create: `Moltipass/Views/Search/SearchView.swift`

- [ ] **Step 1: Create SearchView**

```swift
import SwiftUI

struct SearchView: View {
    @Environment(AppState.self) private var appState
    @State private var query = ""
    @State private var scope: SearchScope = .posts
    @State private var posts: [Post] = []
    @State private var agents: [Agent] = []
    @State private var submolts: [Submolt] = []
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Scope", selection: $scope) {
                    Text("Posts").tag(SearchScope.posts)
                    Text("Agents").tag(SearchScope.agents)
                    Text("Submolts").tag(SearchScope.submolts)
                }
                .pickerStyle(.segmented)
                .padding()

                List {
                    switch scope {
                    case .posts:
                        ForEach(posts) { post in
                            NavigationLink(value: post) {
                                PostCellView(post: post)
                            }
                        }
                    case .agents:
                        ForEach(agents) { agent in
                            NavigationLink(value: agent) {
                                AgentRowView(agent: agent)
                            }
                        }
                    case .submolts:
                        ForEach(submolts) { submolt in
                            NavigationLink(value: submolt) {
                                SubmoltRowView(submolt: submolt)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Search")
            .searchable(text: $query)
            .onSubmit(of: .search) {
                Task { await search() }
            }
            .navigationDestination(for: Post.self) { PostDetailView(post: $0) }
            .navigationDestination(for: Agent.self) { AgentDetailView(agent: $0) }
            .navigationDestination(for: Submolt.self) { SubmoltDetailView(submolt: $0) }
        }
    }

    private func search() async {
        guard !query.isEmpty else { return }
        isSearching = true

        do {
            let response = try await appState.api.search(query: query, scope: scope)
            posts = response.posts ?? []
            agents = response.agents ?? []
            submolts = response.submolts ?? []
        } catch {}

        isSearching = false
    }
}

struct AgentRowView: View {
    let agent: Agent

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: agent.avatarURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading) {
                Text(agent.name)
                    .font(.headline)
                if let bio = agent.bio {
                    Text(bio)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Moltipass/Views/Search/
git commit -m "feat: add SearchView with scope selection"
```

### Task 8.3: Profile Views

**Files:**
- Create: `Moltipass/Views/Profile/ProfileView.swift`
- Create: `Moltipass/Views/Profile/EditProfileView.swift`
- Create: `Moltipass/Views/Profile/AgentDetailView.swift`

- [ ] **Step 1: Create ProfileView**

```swift
import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var profile: Agent?
    @State private var showEdit = false
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            List {
                if let profile = profile {
                    Section {
                        HStack(spacing: 16) {
                            AsyncImage(url: profile.avatarURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 60))
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())

                            VStack(alignment: .leading) {
                                Text(profile.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                if let bio = profile.bio {
                                    Text(bio)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        Button("Edit Profile") {
                            showEdit = true
                        }
                    }

                    Section {
                        HStack {
                            Label("Posts", systemImage: "doc.text")
                            Spacer()
                            Text("\(profile.postCount ?? 0)")
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Label("Comments", systemImage: "bubble.right")
                            Spacer()
                            Text("\(profile.commentCount ?? 0)")
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Label("Karma", systemImage: "star")
                            Spacer()
                            Text("\(profile.karma ?? 0)")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section {
                        NavigationLink("Following") {
                            FollowingListView()
                        }
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        showSignOutAlert = true
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showEdit) {
                if let profile = profile {
                    EditProfileView(profile: profile) { updated in
                        self.profile = updated
                    }
                }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    appState.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .task {
                await loadProfile()
            }
        }
    }

    private func loadProfile() async {
        do {
            profile = try await appState.api.getMyProfile()
        } catch {}
    }
}
```

- [ ] **Step 2: Create EditProfileView**

```swift
import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let profile: Agent
    var onSave: (Agent) -> Void

    @State private var name: String
    @State private var bio: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isSaving = false

    @State private var avatarImage: UIImage?
    @State private var error: String?

    init(profile: Agent, onSave: @escaping (Agent) -> Void) {
        self.profile = profile
        self.onSave = onSave
        self._name = State(initialValue: profile.name)
        self._bio = State(initialValue: profile.bio ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            Text("Change Avatar")
                            Spacer()
                            if let avatarImage = avatarImage {
                                Image(uiImage: avatarImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            } else {
                                AsyncImage(url: profile.avatarURL) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                            }
                        }
                    }
                    .onChange(of: selectedPhoto) {
                        Task { await loadImage() }
                    }
                }

                Section {
                    TextField("Name", text: $name)
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...5)
                }

                if let error = error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func loadImage() async {
        guard let selectedPhoto = selectedPhoto,
              let data = try? await selectedPhoto.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            return
        }

        // Resize to max 500KB
        var compressionQuality: CGFloat = 0.8
        var imageData = image.jpegData(compressionQuality: compressionQuality)

        while let data = imageData, data.count > 500_000, compressionQuality > 0.1 {
            compressionQuality -= 0.1
            imageData = image.jpegData(compressionQuality: compressionQuality)
        }

        if let finalData = imageData, let resizedImage = UIImage(data: finalData) {
            avatarImage = resizedImage
        }
    }

    private func save() async {
        isSaving = true
        error = nil

        do {
            // Upload avatar if changed
            if let avatarImage = avatarImage,
               let imageData = avatarImage.jpegData(compressionQuality: 0.8) {
                _ = try await appState.api.uploadAvatar(imageData: imageData)
            }

            // Update profile fields
            let updated = try await appState.api.updateProfile(
                name: name != profile.name ? name : nil,
                bio: bio != profile.bio ? bio : nil
            )
            onSave(updated)
            dismiss()
        } catch let apiError as APIError {
            error = apiError.message ?? apiError.error
        } catch {
            self.error = "Failed to save profile"
        }

        isSaving = false
    }
}
```

- [ ] **Step 3: Create AgentDetailView and FollowingListView**

```swift
import SwiftUI

struct AgentDetailView: View {
    @Environment(AppState.self) private var appState
    let agent: Agent
    @State private var posts: [Post] = []
    @State private var isFollowing: Bool

    init(agent: Agent) {
        self.agent = agent
        self._isFollowing = State(initialValue: agent.isFollowing ?? false)
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    AsyncImage(url: agent.avatarURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())

                    VStack(alignment: .leading) {
                        Text(agent.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        if let bio = agent.bio {
                            Text(bio)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Button(isFollowing ? "Unfollow" : "Follow") {
                    Task { await toggleFollow() }
                }
                .buttonStyle(.bordered)
            }

            Section("Posts") {
                ForEach(posts) { post in
                    NavigationLink(value: post) {
                        PostCellView(post: post)
                    }
                }
            }
        }
        .navigationTitle(agent.name)
        .navigationDestination(for: Post.self) { PostDetailView(post: $0) }
        .task {
            await loadPosts()
        }
    }

    private func loadPosts() async {
        do {
            let response = try await appState.api.getAgentPosts(id: agent.id)
            posts = response.posts
        } catch {}
    }

    private func toggleFollow() async {
        do {
            if isFollowing {
                try await appState.api.unfollow(agentId: agent.id)
            } else {
                try await appState.api.follow(agentId: agent.id)
            }
            isFollowing.toggle()
        } catch {}
    }
}

struct FollowingListView: View {
    @Environment(AppState.self) private var appState
    @State private var agents: [Agent] = []

    var body: some View {
        List(agents) { agent in
            NavigationLink(value: agent) {
                AgentRowView(agent: agent)
            }
        }
        .navigationTitle("Following")
        .navigationDestination(for: Agent.self) { AgentDetailView(agent: $0) }
        .task {
            do {
                let response = try await appState.api.getFollowing()
                agents = response.agents
            } catch {}
        }
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add Moltipass/Views/Profile/
git commit -m "feat: add Profile views with edit and following"
```

### Task 8.4: Update MainTabView

**Files:**
- Modify: `Moltipass/Views/MainTabView.swift`

- [ ] **Step 1: Wire up all tabs**

```swift
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            FeedView()
                .tabItem { Label("Feed", systemImage: "house") }

            SubmoltsView()
                .tabItem { Label("Submolts", systemImage: "square.stack") }

            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Moltipass/Views/MainTabView.swift
git commit -m "feat: wire up all tabs in MainTabView"
```

---

## Chunk 9: Final Integration & Testing

### Task 9.1: Run Full App Test

- [ ] **Step 1: Build and run in simulator**

```bash
xcodebuild -scheme Moltipass -destination 'platform=iOS Simulator,name=iPhone 15' build
```

- [ ] **Step 2: Run all tests**

```bash
xcodebuild test -scheme Moltipass -destination 'platform=iOS Simulator,name=iPhone 15'
```

- [ ] **Step 3: Manual testing checklist**

Test each flow:
- [ ] Welcome screen appears on first launch
- [ ] Registration flow works
- [ ] Claim instructions display correctly
- [ ] Returning user in pending_claim state sees claim instructions (not welcome)
- [ ] Feed loads after authentication
- [ ] Sort picker changes feed content
- [ ] Pull-to-refresh works
- [ ] Tapping agent name/avatar navigates to agent detail
- [ ] Tapping submolt name navigates to submolt detail
- [ ] Post detail shows comments
- [ ] Voting on posts updates immediately
- [ ] Voting on comments updates immediately
- [ ] Reply to comment opens compose sheet
- [ ] Compose post works with rate limit handling
- [ ] Submolts tab shows subscribed and popular
- [ ] Subscribe/unsubscribe works
- [ ] Search returns results
- [ ] Profile shows correct data
- [ ] Edit profile saves changes
- [ ] Avatar upload compresses to under 500KB
- [ ] Sign out returns to welcome

Test error handling:
- [ ] 401 Unauthorized clears credentials and returns to welcome
- [ ] 429 Rate limit shows friendly message with time remaining
- [ ] Network error shows retry option
- [ ] Invalid form input shows validation error

- [ ] **Step 4: Final commit**

```bash
git add .
git commit -m "feat: complete Moltipass iOS app implementation"
```

---

**Plan complete. Ready to execute?**
