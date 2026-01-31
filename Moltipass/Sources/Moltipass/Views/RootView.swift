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
            case .pendingClaim(let code):
                ClaimInstructionsView(verificationCode: code)
            case .authenticated:
                MainTabView()
            }
        }
    }
}
