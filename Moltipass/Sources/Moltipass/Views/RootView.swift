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
                // TODO: Replace with WelcomeView() when implemented
                Text("Welcome - Unauthenticated")
            case .pendingClaim(let code):
                // TODO: Replace with ClaimInstructionsView(verificationCode: code) when implemented
                Text("Pending Claim: \(code)")
            case .authenticated:
                MainTabView()
            }
        }
    }
}
