import SwiftUI

@MainActor
@Observable
public class PostDetailViewModel {
    public var post: Post
    public var comments: [Comment] = []
    public var isLoading = false
    public var error: String?
    public var selectedSort: CommentSort = .top

    private let api: MoltbookAPI

    public init(post: Post, api: MoltbookAPI) {
        self.post = post
        self.api = api
    }

    public func loadComments() async {
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

    public func votePost(direction: Int) async {
        let oldUpvotes = post.upvotes
        let oldDownvotes = post.downvotes

        // Optimistic update
        if direction > 0 {
            post.upvotes += 1
        } else if direction < 0 {
            post.downvotes += 1
        }

        do {
            try await api.votePost(id: post.id, direction: direction)
        } catch {
            // Revert on error
            post.upvotes = oldUpvotes
            post.downvotes = oldDownvotes
        }
    }
}
