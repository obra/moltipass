import SwiftUI

public struct SubmoltDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var submolt: Submolt
    @State private var posts: [Post] = []
    @State private var isLoading = false

    public init(submolt: Submolt) {
        self._submolt = State(initialValue: submolt)
    }

    public var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    if let description = submolt.description {
                        Text(description)
                    }
                    if let count = submolt.subscriberCount {
                        Text("\(count) members")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button(submolt.isSubscribed ? "Leave" : "Join") {
                        Task { await toggleSubscription() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Section("Posts") {
                if posts.isEmpty && !isLoading {
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
        }
        .navigationTitle(submolt.name)
        .navigationDestination(for: Post.self) { post in
            PostDetailView(post: post)
        }
        .task {
            await loadPosts()
        }
    }

    private func loadPosts() async {
        isLoading = true
        do {
            let response = try await appState.api.getSubmoltFeed(submoltId: submolt.id)
            posts = response.posts
        } catch {
            // Handle error
        }
        isLoading = false
    }

    private func toggleSubscription() async {
        do {
            if submolt.isSubscribed {
                try await appState.api.unsubscribe(submoltId: submolt.id)
                submolt.isSubscribed = false
            } else {
                try await appState.api.subscribe(submoltId: submolt.id)
                submolt.isSubscribed = true
            }
        } catch {
            // Handle error
        }
    }
}
