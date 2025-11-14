//
//  CloudKitBootstrapper.swift
//  Cortex
//
//  Created by Claude Code
//

import CloudKit
import Foundation

/// Bootstraps CloudKit on app launch
actor CloudKitBootstrapper {
    // MARK: - CloudKit Status Check

    /// Check CloudKit availability and account status
    static func checkCloudKitStatus() async throws {
        let container = CKContainer(identifier: "iCloud.wieland.cortex")

        do {
            let status = try await container.accountStatus()

            switch status {
            case .available:
                print("✅ CloudKit is available and ready")
            case .noAccount:
                print("❌ No iCloud account found")
                throw CortexError.cloudKitAccountNotFound
            case .restricted:
                print("❌ CloudKit is restricted")
                throw CortexError.cloudKitNotAvailable
            case .couldNotDetermine:
                print("❌ Could not determine CloudKit status")
                throw CortexError.cloudKitNotAvailable
            case .temporarilyUnavailable:
                print("⚠️  CloudKit is temporarily unavailable")
                throw CortexError.cloudKitNotAvailable
            @unknown default:
                print("❌ Unknown CloudKit status")
                throw CortexError.cloudKitNotAvailable
            }
        } catch let error as CortexError {
            throw error
        } catch {
            print("❌ Error checking CloudKit status: \(error)")
            throw CortexError.unknown(underlying: error)
        }
    }

    // MARK: - Schema Verification

    /// Verify record types exist (development only)
    static func verifySchema() async throws {
        let container = CKContainer(identifier: "iCloud.wieland.cortex")
        let database = container.privateCloudDatabase

        // Try to fetch a record (will fail gracefully if none exist)
        let query = CKQuery(recordType: "KnowledgeEntry", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "modifiedAt", ascending: false)]

        do {
            let (matchResults, _) = try await database.records(matching: query, resultsLimit: 1)

            // If we get here, the record type exists
            if matchResults.isEmpty {
                print("✅ KnowledgeEntry record type exists in CloudKit (no records yet)")
            } else {
                let count = matchResults.count
                print("✅ KnowledgeEntry record type exists with \(count) record(s)")
            }
        } catch let error as CKError {
            // Check if it's a schema error or just no records
            switch error.code {
            case .unknownItem:
                print("❌ KnowledgeEntry record type does not exist in CloudKit Dashboard")
                print("   → Please create the record type in CloudKit Dashboard first")
                throw CortexError.cloudKitInvalidRecord
            case .networkFailure, .networkUnavailable:
                print("⚠️  Network error during schema verification: \(error.localizedDescription)")
                throw CortexError.cloudKitQueryFailed(underlying: error)
            default:
                print("⚠️  CloudKit schema verification warning: \(error.localizedDescription)")
                // Don't fail on schema verification - it's not critical
            }
        } catch {
            print("⚠️  Unexpected error during schema verification: \(error)")
            // Don't fail - just log the warning
        }
    }

    // MARK: - Full Bootstrap

    /// Run complete CloudKit bootstrap checks
    static func bootstrap() async throws {
        print("🚀 Starting CloudKit bootstrap...")

        // Step 1: Check account status
        try await checkCloudKitStatus()

        // Step 2: Verify schema (non-fatal)
        try await verifySchema()

        print("✅ CloudKit bootstrap completed successfully")
    }
}
