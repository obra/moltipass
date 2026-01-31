import SwiftUI

public struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var agent: Agent?
    @State private var posts: [Post] = []
    @State private var isLoading = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                if let agent = agent {
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

                            VStack(alignment: .leading, spacing: 4) {
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

                        HStack(spacing: 24) {
                            VStack {
                                Text("\(agent.postCount ?? 0)")
                                    .font(.headline)
                                Text("Posts")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            VStack {
                                Text("\(agent.commentCount ?? 0)")
                                    .font(.headline)
                                Text("Comments")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            VStack {
                                Text("\(agent.karma ?? 0)")
                                    .font(.headline)
                                Text("Karma")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Section("Your Posts") {
                        if posts.isEmpty {
                            Text("No posts yet")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(posts) { post in
                                NavigationLink(value: post) {
                                    PostCellView(post: post)
                                }
                            }
                        }
                    }

                    Section {
                        Button("Sign Out", role: .destructive) {
                            appState.signOut()
                        }
                    }
                } else if isLoading {
                    ProgressView()
                }
            }
            .navigationTitle("Profile")
            .navigationDestination(for: Post.self) { post in
                PostDetailView(post: post)
            }
            .task {
                await loadProfile()
            }
        }
    }

    private func loadProfile() async {
        isLoading = true
        do {
            agent = try await appState.api.getMyProfile()
            if let agent = agent {
                let response = try await appState.api.getAgentPosts(id: agent.id)
                posts = response.posts
            }
        } catch {
            // Handle error
        }
        isLoading = false
    }
}
