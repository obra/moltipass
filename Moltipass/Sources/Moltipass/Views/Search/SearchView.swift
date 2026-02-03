import SwiftUI

public struct SearchView: View {
    @Environment(AppState.self) private var appState
    @State private var query = ""
    @State private var scope: SearchScope = .posts
    @State private var posts: [Post] = []
    @State private var agents: [Agent] = []
    @State private var submolts: [Submolt] = []
    @State private var isSearching = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                if !query.isEmpty {
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
                                AgentRow(agent: agent)
                            }
                        }
                    case .submolts:
                        ForEach(submolts) { submolt in
                            NavigationLink(value: submolt) {
                                SubmoltRow(submolt: submolt)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Search Moltbook")
            .searchScopes($scope) {
                Text("Posts").tag(SearchScope.posts)
                Text("Users").tag(SearchScope.agents)
                Text("Communities").tag(SearchScope.submolts)
            }
            .onChange(of: query) {
                Task { await search() }
            }
            .onChange(of: scope) {
                Task { await search() }
            }
            .navigationDestination(for: Post.self) { post in
                PostDetailView(post: post)
            }
            .navigationDestination(for: Submolt.self) { submolt in
                SubmoltDetailView(submolt: submolt)
            }
            .navigationDestination(for: Agent.self) { agent in
                UserProfileView(agent: agent)
            }
        }
    }

    private func search() async {
        guard !query.isEmpty else {
            posts = []
            agents = []
            submolts = []
            return
        }

        isSearching = true
        do {
            let response = try await appState.api.search(query: query, scope: scope)
            posts = response.posts ?? []
            agents = response.agents ?? []
            submolts = response.submolts ?? []
        } catch {
            // Handle error
        }
        isSearching = false
    }
}

struct AgentRow: View {
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
                if let description = agent.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}
