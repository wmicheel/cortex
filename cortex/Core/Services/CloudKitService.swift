//
//  CloudKitService.swift
//  Cortex
//
//  Created by Claude Code
//

import CloudKit
import Foundation

/// Generic CloudKit service for CRUD operations
/// Actor-based for thread safety and Swift 6 concurrency compliance
actor CloudKitService {
    // MARK: - Properties

    /// CloudKit container
    private let container: CKContainer

    /// Private database for user data
    private let database: CKDatabase

    // MARK: - Initialization

    /// Initialize with default iCloud container
    init() {
        self.container = CKContainer.default()
        self.database = container.privateCloudDatabase
    }

    /// Initialize with custom container identifier
    init(containerIdentifier: String) {
        self.container = CKContainer(identifier: containerIdentifier)
        self.database = container.privateCloudDatabase
    }

    // MARK: - Account Status

    /// Check if CloudKit is available and user is signed in
    func checkAccountStatus() async throws {
        let status = try await container.accountStatus()

        switch status {
        case .available:
            return
        case .noAccount:
            throw CortexError.cloudKitAccountNotFound
        case .restricted, .couldNotDetermine, .temporarilyUnavailable:
            throw CortexError.cloudKitNotAvailable
        @unknown default:
            throw CortexError.cloudKitNotAvailable
        }
    }

    // MARK: - Create

    /// Save a new record to CloudKit
    func save<T: CloudKitRecord>(_ record: T) async throws -> T {
        // Verify account status
        try await checkAccountStatus()

        let ckRecord = record.toCKRecord()

        do {
            let savedRecord = try await database.save(ckRecord)
            guard let result = T(from: savedRecord) else {
                throw CortexError.cloudKitInvalidRecord
            }
            return result
        } catch {
            throw CortexError.cloudKitSaveFailed(underlying: error)
        }
    }

    /// Save multiple records in batch
    func saveAll<T: CloudKitRecord>(_ records: [T]) async throws -> [T] {
        // Verify account status
        try await checkAccountStatus()

        let ckRecords = records.map { $0.toCKRecord() }

        do {
            let operation = CKModifyRecordsOperation(recordsToSave: ckRecords)
            operation.savePolicy = .changedKeys
            operation.qualityOfService = .userInitiated

            let (savedRecords, _) = try await database.modifyRecords(
                saving: ckRecords,
                deleting: []
            )

            return savedRecords.compactMap { _, result in
                guard let record = try? result.get() else { return nil }
                return T(from: record)
            }
        } catch {
            throw CortexError.cloudKitSaveFailed(underlying: error)
        }
    }

    // MARK: - Read

    /// Fetch a record by ID
    func fetch<T: CloudKitRecord>(id: String, type: T.Type) async throws -> T {
        // Verify account status
        try await checkAccountStatus()

        let recordID = CKRecord.ID(recordName: id)

        do {
            let record = try await database.record(for: recordID)
            guard let result = T(from: record) else {
                throw CortexError.cloudKitInvalidRecord
            }
            return result
        } catch let error as CKError where error.code == .unknownItem {
            throw CortexError.cloudKitRecordNotFound
        } catch {
            throw CortexError.cloudKitFetchFailed(underlying: error)
        }
    }

    /// Query records with predicate
    func query<T: CloudKitRecord>(
        type: T.Type,
        predicate: NSPredicate = NSPredicate(value: true),
        sortDescriptors: [NSSortDescriptor] = []
    ) async throws -> [T] {
        // Verify account status
        try await checkAccountStatus()

        let query = CKQuery(recordType: T.recordType, predicate: predicate)
        query.sortDescriptors = sortDescriptors

        do {
            let (matchResults, _) = try await database.records(matching: query)

            let records = matchResults.compactMap { _, result -> CKRecord? in
                try? result.get()
            }

            return records.compactMap { T(from: $0) }
        } catch {
            throw CortexError.cloudKitQueryFailed(underlying: error)
        }
    }

    /// Fetch all records of a type
    func fetchAll<T: CloudKitRecord>(type: T.Type) async throws -> [T] {
        return try await query(type: type)
    }

    // MARK: - Update

    /// Update an existing record
    func update<T: CloudKitRecord>(_ record: T) async throws -> T {
        // Update is the same as save in CloudKit
        return try await save(record)
    }

    // MARK: - Delete

    /// Delete a record by ID
    func delete<T: CloudKitRecord>(id: String, type: T.Type) async throws {
        // Verify account status
        try await checkAccountStatus()

        let recordID = CKRecord.ID(recordName: id)

        do {
            try await database.deleteRecord(withID: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            throw CortexError.cloudKitRecordNotFound
        } catch {
            throw CortexError.cloudKitDeleteFailed(underlying: error)
        }
    }

    /// Delete a record
    func delete<T: CloudKitRecord>(_ record: T) async throws {
        try await delete(id: record.id, type: T.self)
    }

    /// Delete multiple records
    func deleteAll<T: CloudKitRecord>(_ records: [T]) async throws {
        // Verify account status
        try await checkAccountStatus()

        let recordIDs = records.map { CKRecord.ID(recordName: $0.id) }

        do {
            let (_, _) = try await database.modifyRecords(
                saving: [],
                deleting: recordIDs
            )
        } catch {
            throw CortexError.cloudKitDeleteFailed(underlying: error)
        }
    }

    // MARK: - Subscriptions

    /// Subscribe to changes for a record type
    func subscribe<T: CloudKitRecord>(
        to type: T.Type,
        predicate: NSPredicate = NSPredicate(value: true)
    ) async throws -> CKSubscription {
        // Verify account status
        try await checkAccountStatus()

        let subscriptionID = "subscription-\(T.recordType)-\(UUID().uuidString)"
        let subscription = CKQuerySubscription(
            recordType: T.recordType,
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo

        do {
            return try await database.save(subscription)
        } catch {
            throw CortexError.cloudKitSaveFailed(underlying: error)
        }
    }
}
