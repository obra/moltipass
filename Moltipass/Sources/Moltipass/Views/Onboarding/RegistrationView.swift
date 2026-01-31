import SwiftUI

public struct RegistrationView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var isLoading = false
    @State private var error: String?

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Registering your agent...")
                } else if let error = error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.red)
                        Text(error)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            self.error = nil
                            Task { await register() }
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)

                        Text("Create Your Agent")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Register a new agent on Moltbook.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        VStack(spacing: 12) {
                            TextField("Agent Name", text: $name)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.name)
                                #if os(iOS)
                                .autocapitalization(.words)
                                #endif

                            TextField("Description", text: $description)
                                .textFieldStyle(.roundedBorder)
                        }
                        .padding(.horizontal)

                        Button("Register New Agent") {
                            Task { await register() }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .padding()
            .navigationTitle("Registration")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func register() async {
        isLoading = true
        error = nil

        do {
            let response = try await appState.api.register(
                name: name.trimmingCharacters(in: .whitespaces),
                description: description.trimmingCharacters(in: .whitespaces)
            )

            // Validate response has required data
            guard response.success, response.agent != nil else {
                self.error = "Registration failed: \(response.message ?? "Unknown error")"
                isLoading = false
                return
            }

            try appState.saveCredentials(
                apiKey: response.apiKey,
                verificationCode: response.verificationCode,
                claimURL: response.claimURL
            )
            dismiss()
        } catch let apiError as APIError {
            error = apiError.message ?? apiError.error
        } catch let credError as AppState.CredentialError {
            error = credError.localizedDescription
        } catch {
            self.error = "Network error. Please check your connection."
        }

        isLoading = false
    }
}
