import SwiftUI

@MainActor
@Observable
public class AppState {
    public enum AuthStatus {
        case unknown
        case unauthenticated
        case pendingClaim(verificationCode: String)
        case authenticated
    }

    public var authStatus: AuthStatus = .unknown
    public let api: MoltbookAPI
    private let keychain = KeychainService()
    private let apiKeyKey = "moltbook_api_key"
    private let verificationCodeKey = "moltbook_verification_code"

    public init() {
        if let apiKey = keychain.retrieve(key: apiKeyKey) {
            api = MoltbookAPI(apiKey: apiKey)
        } else {
            api = MoltbookAPI()
        }
    }

    public func checkAuthStatus() async {
        guard let _ = keychain.retrieve(key: apiKeyKey) else {
            authStatus = .unauthenticated
            return
        }

        do {
            let status = try await api.checkStatus()
            switch status.status {
            case .claimed:
                authStatus = .authenticated
            case .pendingClaim:
                if let code = keychain.retrieve(key: verificationCodeKey) {
                    authStatus = .pendingClaim(verificationCode: code)
                } else {
                    authStatus = .unauthenticated
                }
            }
        } catch {
            authStatus = .unauthenticated
        }
    }

    public func saveCredentials(apiKey: String, verificationCode: String) {
        keychain.save(key: apiKeyKey, value: apiKey)
        keychain.save(key: verificationCodeKey, value: verificationCode)
        api.setAPIKey(apiKey)
        authStatus = .pendingClaim(verificationCode: verificationCode)
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
