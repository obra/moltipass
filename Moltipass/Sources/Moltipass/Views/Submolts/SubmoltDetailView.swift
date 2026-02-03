import SwiftUI
import os.log

private let logger = Logger(subsystem: "com.moltipass", category: "submolt")

public struct SubmoltDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var submolt: Submolt
    @State private var posts: [Post] = []
    @State private var isLoading = false
    @State private var isTogglingSubscription = false
    @State private var error: String?

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
                    Button {
                        Task { await toggleSubscription() }
                    } label: {
                        if isTogglingSubscription {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Text(submolt.isSubscribed ? "Leave" : "Join")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isTogglingSubscription)
                }
            }

            if let error = error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }

            Section("Posts") {
                if isLoading {
                    ProgressView()
                } else if posts.isEmpty {
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
        .navigationTitle(submolt.title)
        .navigationDestination(for: Post.self) { post in
            PostDetailView(post: post)
        }
        .navigationDestination(for: Agent.self) { agent in
            UserProfileView(agent: agent)
        }
        .task {
            await loadSubmoltDetail()
        }
        .refreshable {
            await loadSubmoltDetail()
        }
    }

    private func loadSubmoltDetail() async {
        isLoading = true
        error = nil
        do {
            let response = try await appState.api.getSubmoltDetail(name: submolt.name)
            submolt = response.submolt
            posts = response.posts
        } catch {
            self.error = "Failed to load: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func toggleSubscription() async {
        let wasSubscribed = submolt.isSubscribed
        let action = wasSubscribed ? "unsubscribe" : "subscribe"
        logger.info("Toggling subscription: \(action) for \(submolt.name), current isSubscribed: \(wasSubscribed)")

        isTogglingSubscription = true
        error = nil

        do {
            let response: SubscribeResponse
            if wasSubscribed {
                response = try await appState.api.unsubscribe(submoltName: submolt.name)
            } else {
                response = try await appState.api.subscribe(submoltName: submolt.name)
            }

            logger.info("Subscribe response: success=\(response.success), message=\(response.message ?? "nil")")

            if response.success {
                // Update local state immediately
                submolt.isSubscribed = !wasSubscribed
                logger.info("Updated local state: isSubscribed=\(submolt.isSubscribed)")

                // Try to reload for fresh data, but don't fail if it errors
                do {
                    let detail = try await appState.api.getSubmoltDetail(name: submolt.name)
                    submolt = detail.submolt
                    posts = detail.posts
                } catch {
                    logger.warning("Reload after \(action) failed: \(error), keeping optimistic state")
                }
            } else {
                logger.error("Subscribe failed: \(response.message ?? "no message")")
                self.error = response.message ?? "Failed to \(action)"
            }
        } catch {
            logger.error("Subscribe threw error: \(error)")
            self.error = "Error: \(error.localizedDescription)"
        }

        isTogglingSubscription = false
    }
}
