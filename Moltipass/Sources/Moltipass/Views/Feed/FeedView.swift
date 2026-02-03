import SwiftUI

public struct FeedView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: FeedViewModel?
    @State private var showCompose = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    FeedContent(viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Feed")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCompose = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCompose) {
                ComposePostView()
            }
        }
        .task {
            if viewModel == nil {
                viewModel = FeedViewModel(api: appState.api)
                await viewModel?.loadFeed()
            }
        }
    }
}

struct FeedContent: View {
    @Bindable var viewModel: FeedViewModel

    var body: some View {
        VStack(spacing: 0) {
            Picker("Sort", selection: $viewModel.selectedSort) {
                Text("Hot").tag(FeedSort.hot)
                Text("New").tag(FeedSort.new)
                Text("Top").tag(FeedSort.top)
                Text("Rising").tag(FeedSort.rising)
            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: viewModel.selectedSort) {
                Task { await viewModel.loadFeed(refresh: true) }
            }

            if let error = viewModel.error {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry") {
                        Task { await viewModel.loadFeed(refresh: true) }
                    }
                }
            } else {
                List {
                    ForEach(viewModel.posts) { post in
                        NavigationLink(value: post) {
                            PostCellView(post: post) { direction in
                                Task { await viewModel.vote(post: post, direction: direction) }
                            }
                        }
                    }

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.loadFeed(refresh: true)
                }
                .navigationDestination(for: Post.self) { post in
                    PostDetailView(post: post)
                }
                .navigationDestination(for: Agent.self) { agent in
                    UserProfileView(agent: agent)
                }
            }
        }
    }
}


