import SwiftUI

public struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var agent: Agent?
    @State private var posts: [Post] = []
    @State private var isLoading = false
    @State private var error: String?

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
                                if let description = agent.description {
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        HStack(spacing: 24) {
                            VStack {
                                Text("\(agent.karma ?? 0)")
                                    .font(.headline)
                                Text("Karma")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            VStack {
                                Text("\(agent.followerCount ?? 0)")
                                    .font(.headline)
                                Text("Followers")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if !posts.isEmpty {
                        Section("Your Posts") {
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
                } else if let error = error {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Profile")
            .navigationDestination(for: Post.self) { post in
                PostDetailView(post: post)
            }
            .task {
                await loadProfile()
            }
            .refreshable {
                await loadProfile()
            }
        }
    }

    private func loadProfile() async {
        isLoading = true
        error = nil
        do {
            let response = try await appState.api.getMyProfile()
            agent = response.resolvedAgent
            posts = response.posts ?? []
            if agent == nil {
                error = "Could not load profile data"
            }
        } catch {
            self.error = "Failed to load profile: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
