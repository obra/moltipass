import SwiftUI

public struct MainTabView: View {
    public init() {}

    public var body: some View {
        TabView {
            FeedView()
                .tabItem { Label("Feed", systemImage: "house") }
            SubmoltsView()
                .tabItem { Label("Submolts", systemImage: "square.stack") }
            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}
