//
//  KeychainManagerTests.swift
//  CortexTests
//
//  Created by Claude Code
//

import XCTest
@testable import cortex

final class KeychainManagerTests: XCTestCase {
    var keychainManager: KeychainManager!
    let testKey = "test_key_\(UUID().uuidString)"

    override func setUp() async throws {
        try await super.setUp()
        keychainManager = KeychainManager.shared

        // Clean up test key if it exists
        try? await keychainManager.delete(key: testKey)
    }

    override func tearDown() async throws {
        // Clean up test key
        try? await keychainManager.delete(key: testKey)
        try await super.tearDown()
    }

    // MARK: - Save Tests

    func testSaveValue() async throws {
        let testValue = "test_value"

        try await keychainManager.save(key: testKey, value: testValue)

        let retrievedValue = try await keychainManager.get(key: testKey)
        XCTAssertEqual(retrievedValue, testValue)
    }

    func testSaveOverwritesExistingValue() async throws {
        let initialValue = "initial_value"
        let updatedValue = "updated_value"

        try await keychainManager.save(key: testKey, value: initialValue)
        try await keychainManager.save(key: testKey, value: updatedValue)

        let retrievedValue = try await keychainManager.get(key: testKey)
        XCTAssertEqual(retrievedValue, updatedValue)
    }

    // MARK: - Get Tests

    func testGetNonExistentKey() async throws {
        let retrievedValue = try await keychainManager.get(key: "non_existent_key_\(UUID().uuidString)")
        XCTAssertNil(retrievedValue)
    }

    func testGetValue() async throws {
        let testValue = "test_value"
        try await keychainManager.save(key: testKey, value: testValue)

        let retrievedValue = try await keychainManager.get(key: testKey)
        XCTAssertEqual(retrievedValue, testValue)
    }

    // MARK: - Delete Tests

    func testDeleteValue() async throws {
        let testValue = "test_value"
        try await keychainManager.save(key: testKey, value: testValue)

        try await keychainManager.delete(key: testKey)

        let retrievedValue = try await keychainManager.get(key: testKey)
        XCTAssertNil(retrievedValue)
    }

    func testDeleteNonExistentKey() async throws {
        // Should not throw an error
        try await keychainManager.delete(key: "non_existent_key_\(UUID().uuidString)")
    }

    // MARK: - Exists Tests

    func testExistsForExistingKey() async throws {
        let testValue = "test_value"
        try await keychainManager.save(key: testKey, value: testValue)

        let exists = try await keychainManager.exists(key: testKey)
        XCTAssertTrue(exists)
    }

    func testExistsForNonExistentKey() async throws {
        let exists = try await keychainManager.exists(key: "non_existent_key_\(UUID().uuidString)")
        XCTAssertFalse(exists)
    }

    // MARK: - Update Tests

    func testUpdateExistingValue() async throws {
        let initialValue = "initial_value"
        let updatedValue = "updated_value"

        try await keychainManager.save(key: testKey, value: initialValue)
        try await keychainManager.update(key: testKey, value: updatedValue)

        let retrievedValue = try await keychainManager.get(key: testKey)
        XCTAssertEqual(retrievedValue, updatedValue)
    }

    func testUpdateNonExistentValue() async throws {
        let testValue = "test_value"

        // Update should create the value if it doesn't exist
        try await keychainManager.update(key: testKey, value: testValue)

        let retrievedValue = try await keychainManager.get(key: testKey)
        XCTAssertEqual(retrievedValue, testValue)
    }

    // MARK: - Context7 API Key Tests

    func testSaveContext7APIKey() async throws {
        let apiKey = "test_api_key"
        let testContext7Key = "context7_test_\(UUID().uuidString)"

        try await keychainManager.save(key: testContext7Key, value: apiKey)

        let retrievedKey = try await keychainManager.get(key: testContext7Key)
        XCTAssertEqual(retrievedKey, apiKey)

        // Cleanup
        try await keychainManager.delete(key: testContext7Key)
    }

    // MARK: - Unicode and Special Characters Tests

    func testSaveUnicodeValue() async throws {
        let unicodeValue = "Hello 世界 🌍"

        try await keychainManager.save(key: testKey, value: unicodeValue)

        let retrievedValue = try await keychainManager.get(key: testKey)
        XCTAssertEqual(retrievedValue, unicodeValue)
    }

    func testSaveEmptyString() async throws {
        let emptyValue = ""

        try await keychainManager.save(key: testKey, value: emptyValue)

        let retrievedValue = try await keychainManager.get(key: testKey)
        XCTAssertEqual(retrievedValue, emptyValue)
    }

    func testSaveLongValue() async throws {
        let longValue = String(repeating: "A", count: 10000)

        try await keychainManager.save(key: testKey, value: longValue)

        let retrievedValue = try await keychainManager.get(key: testKey)
        XCTAssertEqual(retrievedValue, longValue)
    }
}
