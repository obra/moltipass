import SwiftUI
import os.log

private let logger = Logger(subsystem: "com.moltipass", category: "feed")

@MainActor
@Observable
public class FeedViewModel {
    public var posts: [Post] = []
    public var isLoading = false
    public var error: String?
    public var selectedSort: FeedSort = .hot
    private var nextCursor: String?

    private let api: MoltbookAPI

    public init(api: MoltbookAPI) {
        self.api = api
    }

    public func loadFeed(refresh: Bool = false) async {
        if refresh {
            nextCursor = nil
        }

        guard !isLoading else { return }
        isLoading = true
        error = nil

        logger.info("Loading feed, sort: \(self.selectedSort.rawValue), refresh: \(refresh)")

        do {
            let response = try await api.getFeed(sort: selectedSort, cursor: refresh ? nil : nextCursor)
            logger.info("Loaded \(response.posts.count) posts")
            if refresh {
                posts = response.posts
            } else {
                posts.append(contentsOf: response.posts)
            }
            nextCursor = response.nextCursor
        } catch let apiError as APIError {
            logger.error("Feed load API error: \(apiError.error)")
            error = apiError.message ?? apiError.error
        } catch {
            logger.error("Feed load error: \(error)")
            self.error = "Failed to load feed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    public func vote(post: Post, direction: Int) async {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }

        let oldUpvotes = posts[index].upvotes
        let oldDownvotes = posts[index].downvotes

        // Optimistic update
        if direction > 0 {
            posts[index].upvotes += 1
        } else if direction < 0 {
            posts[index].downvotes += 1
        }

        do {
            try await api.votePost(id: post.id, direction: direction)
            logger.info("Vote succeeded for post \(post.id)")
        } catch {
            logger.error("Vote failed: \(error)")
            // Revert on error
            posts[index].upvotes = oldUpvotes
            posts[index].downvotes = oldDownvotes
        }
    }
}
