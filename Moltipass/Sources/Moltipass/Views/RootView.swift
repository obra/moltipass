import SwiftUI

public struct RootView: View {
    @Environment(AppState.self) private var appState

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
        .overlay(alignment: .bottom) {
            if let error = appState.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.9))
                    .cornerRadius(8)
                    .padding()
            }
        }
    }
}
