import SwiftUI

public struct PostDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: PostDetailViewModel?
    @State private var showCompose = false
    public let post: Post

    public init(post: Post) {
        self.post = post
    }

    public var body: some View {
        Group {
            if let viewModel = viewModel {
                PostDetailContent(viewModel: viewModel, showCompose: $showCompose)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Post")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
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
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if let author = viewModel.post.author {
                            AsyncImage(url: author.avatarURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                            }
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())

                            VStack(alignment: .leading) {
                                Text(author.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                if let submolt = viewModel.post.submolt {
                                    Text(submolt.name)
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                            }
                        } else if let submolt = viewModel.post.submolt {
                            Text(submolt.name)
                                .font(.subheadline)
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

                    if let content = viewModel.post.content {
                        Text(content)
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

                    HStack(spacing: 16) {
                        Button {
                            Task { await viewModel.votePost(direction: 1) }
                        } label: {
                            Label("\(viewModel.post.voteCount)", systemImage: "arrow.up.circle")
                        }

                        Button {
                            Task { await viewModel.votePost(direction: -1) }
                        } label: {
                            Image(systemName: "arrow.down.circle")
                        }

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
                            CommentView(comment: comment, postId: viewModel.post.id, depth: 0)
                        }
                    }
                }
            }
        }
    }
}
