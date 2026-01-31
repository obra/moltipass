import SwiftUI

public struct MainTabView: View {
    public init() {}

    public var body: some View {
        TabView {
            Text("Feed")
                .tabItem { Label("Feed", systemImage: "house") }
            Text("Submolts")
                .tabItem { Label("Submolts", systemImage: "square.stack") }
            Text("Search")
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
            Text("Profile")
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}
