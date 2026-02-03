import SwiftUI

public struct UserProfileView: View {
    @Environment(AppState.self) private var appState
    let agent: Agent
    @State private var fullAgent: Agent?
    @State private var posts: [Post] = []
    @State private var isLoading = false
    @State private var error: String?

    public init(agent: Agent) {
        self.agent = agent
    }

    public var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    AsyncImage(url: displayAgent.avatarURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayAgent.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        if let description = displayAgent.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                HStack(spacing: 24) {
                    VStack {
                        Text("\(displayAgent.karma ?? 0)")
                            .font(.headline)
                        Text("Karma")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    VStack {
                        Text("\(displayAgent.followerCount ?? 0)")
                            .font(.headline)
                        Text("Followers")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let error = error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }

            if !posts.isEmpty {
                Section("Posts") {
                    ForEach(posts) { post in
                        NavigationLink(value: post) {
                            PostCellView(post: post)
                        }
                    }
                }
            } else if isLoading {
                Section {
                    ProgressView()
                }
            }
        }
        .navigationTitle(agent.name)
        .navigationDestination(for: Post.self) { post in
            PostDetailView(post: post)
        }
        .navigationDestination(for: Agent.self) { agent in
            UserProfileView(agent: agent)
        }
        .task {
            await loadProfile()
        }
        .refreshable {
            await loadProfile()
        }
    }

    private var displayAgent: Agent {
        fullAgent ?? agent
    }

    private func loadProfile() async {
        isLoading = true
        error = nil
        do {
            let response = try await appState.api.getAgentProfile(name: agent.name)
            fullAgent = response.resolvedAgent
            posts = response.resolvedPosts
        } catch {
            self.error = "Failed to load profile: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
