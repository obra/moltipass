import Foundation
import Security
import os.log

private let logger = Logger(subsystem: "com.moltipass", category: "keychain")

/// Stores credentials securely using Keychain, with UserDefaults fallback for development.
/// Note: UserDefaults fallback is less secure but works when keychain entitlements are missing.
public final class KeychainService {
    private let serviceName = "com.moltipass.app"
    private let userDefaultsPrefix = "com.moltipass.fallback."
    private var useUserDefaultsFallback = false

    public init() {}

    @discardableResult
    public func save(key: String, value: String) -> Bool {
        // Try keychain first
        if !useUserDefaultsFallback {
            if saveToKeychain(key: key, value: value) {
                return true
            }
            // Keychain failed, switch to UserDefaults fallback
            logger.warning("Keychain unavailable, using UserDefaults fallback (less secure)")
            useUserDefaultsFallback = true
        }

        // UserDefaults fallback
        UserDefaults.standard.set(value, forKey: userDefaultsPrefix + key)
        logger.info("Saved to UserDefaults fallback: \(key)")
        return true
    }

    private func saveToKeychain(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            logger.error("Failed to encode value for key: \(key)")
            return false
        }

        deleteFromKeychain(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            logger.error("Keychain save failed for \(key): OSStatus \(status)")
            return false
        }
        logger.info("Keychain save succeeded for \(key)")
        return true
    }

    public func retrieve(key: String) -> String? {
        // Try keychain first
        if let value = retrieveFromKeychain(key: key) {
            return value
        }

        // Try UserDefaults fallback
        if let value = UserDefaults.standard.string(forKey: userDefaultsPrefix + key) {
            useUserDefaultsFallback = true
            return value
        }

        return nil
    }

    private func retrieveFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    @discardableResult
    public func delete(key: String) -> Bool {
        // Delete from both storages
        let keychainResult = deleteFromKeychain(key: key)
        UserDefaults.standard.removeObject(forKey: userDefaultsPrefix + key)
        return keychainResult
    }

    private func deleteFromKeychain(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}
