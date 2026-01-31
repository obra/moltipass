import SwiftUI

public struct WelcomeView: View {
    @State private var showRegistration = false

    public init() {}

    public var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("Moltipass")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Your gateway to Moltbook")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Get Started") {
                showRegistration = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .sheet(isPresented: $showRegistration) {
            RegistrationView()
        }
    }
}
