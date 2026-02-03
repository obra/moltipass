import SwiftUI

public struct CommentView: View {
    @Environment(AppState.self) private var appState
    public let comment: Comment
    public let postId: String
    public let depth: Int
    public var onVote: ((String, Int) -> Void)?
    @State private var showReply = false
    @State private var localUpvotes: Int
    @State private var localDownvotes: Int

    private let maxDepth = 3

    public init(comment: Comment, postId: String, depth: Int, onVote: ((String, Int) -> Void)? = nil) {
        self.comment = comment
        self.postId = postId
        self.depth = depth
        self.onVote = onVote
        self._localUpvotes = State(initialValue: comment.upvotes)
        self._localDownvotes = State(initialValue: comment.downvotes)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let author = comment.author {
                    NavigationLink(value: author) {
                        HStack(spacing: 8) {
                            AsyncImage(url: author.avatarURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 20, height: 20)
                            .clipShape(Circle())

                            Text(author.name)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    .buttonStyle(.plain)

                    Text("•")
                        .foregroundStyle(.secondary)
                }

                Text(comment.createdAt.relativeTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(comment.content)
                .font(.subheadline)

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Button {
                        localUpvotes += 1
                        onVote?(comment.id, 1)
                    } label: {
                        Image(systemName: comment.userVote == 1 ? "arrow.up.circle.fill" : "arrow.up.circle")
                            .foregroundStyle(comment.userVote == 1 ? .orange : .secondary)
                    }
                    .buttonStyle(.plain)

                    Text("\(localUpvotes - localDownvotes)")
                        .font(.caption)

                    Button {
                        localDownvotes += 1
                        onVote?(comment.id, -1)
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

            if depth < maxDepth && !comment.replies.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(comment.replies) { reply in
                        CommentView(comment: reply, postId: postId, depth: depth + 1, onVote: onVote)
                    }
                }
                .padding(.leading, 16)
            } else if depth >= maxDepth && !comment.replies.isEmpty {
                Text("Continue thread ->")
                    .font(.caption)
                    .foregroundStyle(.blue)
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
