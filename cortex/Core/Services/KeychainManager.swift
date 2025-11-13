//
//  KeychainManager.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation
import Security

/// Secure storage manager for API keys and sensitive data using Keychain
/// Actor-based for thread safety and Swift 6 concurrency compliance
actor KeychainManager {
    // MARK: - Singleton

    /// Shared instance
    static let shared = KeychainManager()

    // MARK: - Properties

    /// Service name for keychain items
    private let serviceName = "com.wieland.Cortex"

    // MARK: - Initialization

    private init() {}

    // MARK: - Public API

    /// Save a value to the keychain
    /// - Parameters:
    ///   - key: The key to store the value under
    ///   - value: The value to store
    /// - Throws: CortexError.keychainError if save fails
    func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw CortexError.invalidData
        }

        // Create query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        // Delete any existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw CortexError.keychainError(
                message: "Failed to save to keychain: \(status)"
            )
        }
    }

    /// Retrieve a value from the keychain
    /// - Parameter key: The key to retrieve
    /// - Returns: The stored value, or nil if not found
    /// - Throws: CortexError.keychainError if retrieval fails
    func get(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        // Item not found is not an error, just return nil
        guard status != errSecItemNotFound else {
            return nil
        }

        guard status == errSecSuccess else {
            throw CortexError.keychainError(
                message: "Failed to retrieve from keychain: \(status)"
            )
        }

        guard let data = dataTypeRef as? Data else {
            throw CortexError.invalidData
        }

        return String(data: data, encoding: .utf8)
    }

    /// Delete a value from the keychain
    /// - Parameter key: The key to delete
    /// - Throws: CortexError.keychainError if deletion fails
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        // Item not found is not an error
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CortexError.keychainError(
                message: "Failed to delete from keychain: \(status)"
            )
        }
    }

    /// Check if a key exists in the keychain
    /// - Parameter key: The key to check
    /// - Returns: true if the key exists, false otherwise
    func exists(key: String) throws -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Update an existing value in the keychain
    /// - Parameters:
    ///   - key: The key to update
    ///   - value: The new value
    /// - Throws: CortexError.keychainError if update fails
    func update(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw CortexError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        // If item doesn't exist, create it
        if status == errSecItemNotFound {
            try save(key: key, value: value)
            return
        }

        guard status == errSecSuccess else {
            throw CortexError.keychainError(
                message: "Failed to update keychain: \(status)"
            )
        }
    }

    /// Clear all keychain items for this service
    /// - Throws: CortexError.keychainError if clear fails
    func clearAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]

        let status = SecItemDelete(query as CFDictionary)

        // No items to delete is not an error
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CortexError.keychainError(
                message: "Failed to clear keychain: \(status)"
            )
        }
    }
}

// MARK: - Convenience Keys

extension KeychainManager {
    /// Predefined keychain keys
    enum Key {
        static let context7APIKey = "context7_api_key"
        static let claudeSessionToken = "claude_session_token"
        static let chatGPTAPIKey = "chatgpt_api_key"
    }

    // MARK: - Context7 API Key

    /// Save Context7 API key
    func saveContext7APIKey(_ apiKey: String) throws {
        try save(key: Key.context7APIKey, value: apiKey)
    }

    /// Get Context7 API key
    func getContext7APIKey() throws -> String? {
        try get(key: Key.context7APIKey)
    }

    /// Delete Context7 API key
    func deleteContext7APIKey() throws {
        try delete(key: Key.context7APIKey)
    }

    /// Check if Context7 API key exists
    func hasContext7APIKey() throws -> Bool {
        try exists(key: Key.context7APIKey)
    }

    // MARK: - Claude Session Token

    /// Save Claude session token
    func saveClaudeSessionToken(_ token: String) throws {
        try save(key: Key.claudeSessionToken, value: token)
    }

    /// Get Claude session token
    func getClaudeSessionToken() throws -> String? {
        try get(key: Key.claudeSessionToken)
    }

    /// Delete Claude session token
    func deleteClaudeSessionToken() throws {
        try delete(key: Key.claudeSessionToken)
    }
}
