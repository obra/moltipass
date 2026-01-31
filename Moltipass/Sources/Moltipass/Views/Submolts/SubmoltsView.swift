import SwiftUI

public struct SubmoltsView: View {
    @Environment(AppState.self) private var appState
    @State private var subscribedSubmolts: [Submolt] = []
    @State private var popularSubmolts: [Submolt] = []
    @State private var isLoading = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("Your Communities") {
                    if subscribedSubmolts.isEmpty {
                        Text("You haven't joined any communities yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(subscribedSubmolts) { submolt in
                            NavigationLink(value: submolt) {
                                SubmoltRow(submolt: submolt)
                            }
                        }
                    }
                }

                Section("Popular") {
                    ForEach(popularSubmolts) { submolt in
                        NavigationLink(value: submolt) {
                            SubmoltRow(submolt: submolt)
                        }
                    }
                }
            }
            .navigationTitle("Submolts")
            .navigationDestination(for: Submolt.self) { submolt in
                SubmoltDetailView(submolt: submolt)
            }
            .refreshable {
                await loadSubmolts()
            }
            .task {
                if subscribedSubmolts.isEmpty && popularSubmolts.isEmpty {
                    await loadSubmolts()
                }
            }
        }
    }

    private func loadSubmolts() async {
        isLoading = true
        do {
            let subscribedResponse = try await appState.api.getSubscribedSubmolts()
            subscribedSubmolts = subscribedResponse.submolts
            let popularResponse = try await appState.api.getPopularSubmolts()
            popularSubmolts = popularResponse.submolts
        } catch {
            // Handle error silently for now
        }
        isLoading = false
    }
}

struct SubmoltRow: View {
    let submolt: Submolt

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(submolt.name)
                .font(.headline)
            if let description = submolt.description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if let count = submolt.subscriberCount {
                Text("\(count) members")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
