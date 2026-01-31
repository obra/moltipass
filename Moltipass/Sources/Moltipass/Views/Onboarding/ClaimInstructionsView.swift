import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct ClaimInstructionsView: View {
    @Environment(AppState.self) private var appState
    public let verificationCode: String

    @State private var isVerifying = false
    @State private var error: String?
    @State private var pollCount = 0
    private let maxPolls = 40

    public init(verificationCode: String) {
        self.verificationCode = verificationCode
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.seal")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Claim Your Agent")
                    .font(.title2)
                    .fontWeight(.semibold)

                VStack(spacing: 8) {
                    Text("Post this code on Twitter/X:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(verificationCode)
                        .font(.system(.title, design: .monospaced))
                        .fontWeight(.bold)
                        .padding()
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)

                    Button("Copy Code") {
                        copyToClipboard(verificationCode)
                    }
                    .font(.caption)
                }

                Button("Open Twitter") {
                    openTwitter()
                }
                .buttonStyle(.borderedProminent)

                Divider()

                if isVerifying {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Verifying your claim...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if let error = error {
                    VStack(spacing: 8) {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.subheadline)
                        Button("Try Again") {
                            Task { await startVerification() }
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    Button("I've Posted It") {
                        Task { await startVerification() }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationTitle("Verification")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    private func copyToClipboard(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }

    private func openTwitter() {
        let tweetText = verificationCode
        let encodedText = tweetText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? tweetText

        #if canImport(UIKit)
        if let url = URL(string: "twitter://post?message=\(encodedText)") {
            UIApplication.shared.open(url) { success in
                if !success, let webURL = URL(string: "https://twitter.com/intent/tweet?text=\(encodedText)") {
                    UIApplication.shared.open(webURL)
                }
            }
        }
        #elseif canImport(AppKit)
        if let url = URL(string: "https://twitter.com/intent/tweet?text=\(encodedText)") {
            NSWorkspace.shared.open(url)
        }
        #endif
    }

    private func startVerification() async {
        isVerifying = true
        error = nil
        pollCount = 0

        while pollCount < maxPolls {
            do {
                let status = try await appState.api.checkStatus()
                if status.status == .claimed {
                    appState.completeAuthentication()
                    return
                }
            } catch {
                // Continue polling on error
            }

            pollCount += 1
            try? await Task.sleep(nanoseconds: 3_000_000_000)
        }

        isVerifying = false
        error = "Verification timed out. Make sure you posted the code and try again."
    }
}
