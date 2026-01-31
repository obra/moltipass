import SwiftUI

public struct CommentView: View {
    @Environment(AppState.self) private var appState
    public let comment: Comment
    public let postId: String
    public let depth: Int
    @State private var showReply = false

    private let maxDepth = 3

    public init(comment: Comment, postId: String, depth: Int) {
        self.comment = comment
        self.postId = postId
        self.depth = depth
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let author = comment.author {
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
                    Image(systemName: comment.userVote == 1 ? "arrow.up.circle.fill" : "arrow.up.circle")
                        .foregroundStyle(comment.userVote == 1 ? .orange : .secondary)

                    Text("\(comment.voteCount)")
                        .font(.caption)

                    Image(systemName: comment.userVote == -1 ? "arrow.down.circle.fill" : "arrow.down.circle")
                        .foregroundStyle(comment.userVote == -1 ? .purple : .secondary)
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
                        CommentView(comment: reply, postId: postId, depth: depth + 1)
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
