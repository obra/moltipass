import SwiftUI

public struct RootView: View {
    @Environment(AppState.self) private var appState
    @State private var showDebug = false

    public init() {}

    public var body: some View {
        Group {
            switch appState.authStatus {
            case .unknown:
                ProgressView("Loading...")
                    .task { await appState.checkAuthStatus() }
            case .unauthenticated:
                WelcomeView()
            case .pendingClaim(let code, let claimURL):
                ClaimInstructionsView(verificationCode: code, claimURL: claimURL)
            case .authenticated:
                MainTabView()
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(showDebug ? "Hide Debug" : "Debug") {
                showDebug.toggle()
            }
            .font(.caption2)
            .padding(4)
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 4) {
                if showDebug {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auth: \(authStatusDescription)")
                        Text("API Key: \(appState.api.isAuthenticated ? "Set" : "Not set")")
                        if let error = appState.lastError {
                            Text("Error: \(error)")
                                .foregroundStyle(.red)
                        }
                    }
                    .font(.caption2)
                    .padding(8)
                    .background(Color.black.opacity(0.8))
                    .foregroundStyle(.white)
                    .cornerRadius(8)
                }

                if let error = appState.lastError, !showDebug {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.9))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }

    private var authStatusDescription: String {
        switch appState.authStatus {
        case .unknown: return "unknown"
        case .unauthenticated: return "unauthenticated"
        case .pendingClaim(let code, let url):
            return "pendingClaim(code: \(code), url: \(url?.absoluteString ?? "nil"))"
        case .authenticated: return "authenticated"
        }
    }
}
