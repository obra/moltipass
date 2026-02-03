import SwiftUI
import os.log

private let logger = Logger(subsystem: "com.moltipass", category: "auth")

@MainActor
@Observable
public class AppState {
    public enum AuthStatus {
        case unknown
        case unauthenticated
        case pendingClaim(verificationCode: String, claimURL: URL?)
        case authenticated
    }

    public var authStatus: AuthStatus = .unknown
    public var lastError: String?
    public let api: MoltbookAPI
    private var errorDismissTask: Task<Void, Never>?

    public func showError(_ message: String) {
        errorDismissTask?.cancel()
        lastError = message
        errorDismissTask = Task {
            try? await Task.sleep(for: .seconds(4))
            if !Task.isCancelled {
                lastError = nil
            }
        }
    }

    public func clearError() {
        errorDismissTask?.cancel()
        lastError = nil
    }
    private let keychain = KeychainService()
    private let apiKeyKey = "moltbook_api_key"
    private let verificationCodeKey = "moltbook_verification_code"
    private let claimURLKey = "moltbook_claim_url"

    public init() {
        if let apiKey = keychain.retrieve(key: apiKeyKey), !apiKey.isEmpty {
            logger.info("Found API key in keychain")
            api = MoltbookAPI(apiKey: apiKey)
        } else {
            logger.info("No API key in keychain")
            api = MoltbookAPI()
        }
    }

    public func checkAuthStatus() async {
        guard let apiKey = keychain.retrieve(key: apiKeyKey), !apiKey.isEmpty else {
            logger.info("No valid API key, setting unauthenticated")
            authStatus = .unauthenticated
            return
        }

        do {
            let status = try await api.checkStatus()
            logger.info("Status check returned: \(status.status.rawValue), agent: \(status.agent?.name ?? "nil")")
            switch status.status {
            case .claimed:
                authStatus = .authenticated
            case .pendingClaim:
                if let code = keychain.retrieve(key: verificationCodeKey), !code.isEmpty {
                    // Prefer claimURL from API response, fall back to saved
                    var claimURL = status.claimURL
                    if claimURL == nil {
                        claimURL = keychain.retrieve(key: claimURLKey).flatMap { URL(string: $0) }
                    } else if let url = claimURL {
                        // Save the fresh URL from API
                        keychain.save(key: claimURLKey, value: url.absoluteString)
                    }
                    logger.info("Restored pending claim with code: \(code), claimURL: \(claimURL?.absoluteString ?? "nil")")
                    authStatus = .pendingClaim(verificationCode: code, claimURL: claimURL)
                } else {
                    logger.error("API key valid but no verification code saved - corrupt state")
                    showError("Session corrupted. Please sign out and register again.")
                    authStatus = .unauthenticated
                }
            }
        } catch let apiError as APIError {
            logger.error("Status check API error: \(apiError.error) - \(apiError.message ?? "")")
            // Don't immediately go to unauthenticated - show the pending state with stored code
            if let code = keychain.retrieve(key: verificationCodeKey), !code.isEmpty {
                let claimURL = keychain.retrieve(key: claimURLKey).flatMap { URL(string: $0) }
                authStatus = .pendingClaim(verificationCode: code, claimURL: claimURL)
                showError("Could not verify status: \(apiError.message ?? apiError.error)")
            } else {
                authStatus = .unauthenticated
                showError(apiError.message ?? apiError.error)
            }
        } catch {
            logger.error("Status check network error: \(error)")
            // On network error, restore from keychain if possible
            if let code = keychain.retrieve(key: verificationCodeKey), !code.isEmpty {
                let claimURL = keychain.retrieve(key: claimURLKey).flatMap { URL(string: $0) }
                authStatus = .pendingClaim(verificationCode: code, claimURL: claimURL)
                showError("Network error. Will retry when online.")
            } else {
                authStatus = .unauthenticated
                showError("Network error")
            }
        }
    }

    public func saveCredentials(apiKey: String, verificationCode: String, claimURL: URL?) throws {
        // Validate before saving
        guard !apiKey.isEmpty else {
            throw CredentialError.emptyAPIKey
        }
        guard !verificationCode.isEmpty else {
            throw CredentialError.emptyVerificationCode
        }

        logger.info("Saving credentials - API key length: \(apiKey.count), code: \(verificationCode)")

        guard keychain.save(key: apiKeyKey, value: apiKey) else {
            logger.error("Failed to save API key to keychain")
            throw CredentialError.keychainSaveFailed
        }
        guard keychain.save(key: verificationCodeKey, value: verificationCode) else {
            logger.error("Failed to save verification code to keychain")
            throw CredentialError.keychainSaveFailed
        }
        if let claimURL = claimURL {
            if !keychain.save(key: claimURLKey, value: claimURL.absoluteString) {
                logger.warning("Failed to save claim URL to keychain")
            }
        }

        api.setAPIKey(apiKey)
        authStatus = .pendingClaim(verificationCode: verificationCode, claimURL: claimURL)
    }

    public enum CredentialError: Error, LocalizedError {
        case emptyAPIKey
        case emptyVerificationCode
        case keychainSaveFailed

        public var errorDescription: String? {
            switch self {
            case .emptyAPIKey: return "Registration failed: no API key received"
            case .emptyVerificationCode: return "Registration failed: no verification code received"
            case .keychainSaveFailed: return "Failed to save credentials securely"
            }
        }
    }

    public func completeAuthentication() {
        authStatus = .authenticated
    }

    public func signOut() {
        keychain.delete(key: apiKeyKey)
        keychain.delete(key: verificationCodeKey)
        api.clearAPIKey()
        authStatus = .unauthenticated
    }
}
