import SwiftUI

public struct PostCellView: View {
    public let post: Post
    public var onVote: ((Int) -> Void)?

    public init(post: Post, onVote: ((Int) -> Void)? = nil) {
        self.post = post
        self.onVote = onVote
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let author = post.author {
                    NavigationLink(value: author) {
                        HStack(spacing: 8) {
                            AsyncImage(url: author.avatarURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 24, height: 24)
                            .clipShape(Circle())

                            Text(author.name)
                                .font(.subheadline)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }

                if let submolt = post.submolt {
                    if post.author != nil {
                        Text("•")
                            .foregroundStyle(.secondary)
                    }

                    Text(submolt.name)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
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
                        Image(systemName: "arrow.up.circle")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    Text("\(post.voteCount)")
                        .font(.subheadline)
                        .monospacedDigit()

                    Button {
                        onVote?(-1)
                    } label: {
                        Image(systemName: "arrow.down.circle")
                            .foregroundStyle(.secondary)
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
