//
//  MockCloudKitService.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation

/// Mock CloudKit service for development without iCloud
/// Stores data in-memory only (lost on app restart)
actor MockCloudKitService {
    // MARK: - Properties

    private var recordsById: [String: any CloudKitRecord] = [:]

    // MARK: - Account Status

    func checkAccountStatus() async throws {
        // Mock always returns success
        print("MockCloudKitService: Account status OK (mock)")
    }

    // MARK: - Create

    func save<T: CloudKitRecord>(_ record: T) async throws -> T {
        recordsById[record.id] = record
        print("MockCloudKitService: Saved \(T.recordType) with id: \(record.id)")
        return record
    }

    func saveAll<T: CloudKitRecord>(_ records: [T]) async throws -> [T] {
        for record in records {
            recordsById[record.id] = record
        }
        print("MockCloudKitService: Saved \(records.count) records of type \(T.recordType)")
        return records
    }

    // MARK: - Read

    func fetch<T: CloudKitRecord>(id: String, type: T.Type) async throws -> T {
        guard let record = recordsById[id] as? T else {
            throw CortexError.cloudKitRecordNotFound
        }
        print("MockCloudKitService: Fetched \(T.recordType) with id: \(id)")
        return record
    }

    func query<T: CloudKitRecord>(
        type: T.Type,
        predicate: NSPredicate = NSPredicate(value: true),
        sortDescriptors: [NSSortDescriptor] = []
    ) async throws -> [T] {
        let allRecords = recordsById.values.compactMap { $0 as? T }

        // Simple filtering (NSPredicate on in-memory objects)
        let filtered = allRecords.filter { record in
            predicate.evaluate(with: record)
        }

        // Simple sorting
        var sorted = filtered
        for descriptor in sortDescriptors.reversed() {
            sorted.sort { record1, record2 in
                guard let key = descriptor.key else { return false }

                // Use reflection to get property values
                let mirror1 = Mirror(reflecting: record1)
                let mirror2 = Mirror(reflecting: record2)

                guard let value1 = mirror1.children.first(where: { $0.label == key })?.value,
                      let value2 = mirror2.children.first(where: { $0.label == key })?.value else {
                    return false
                }

                // Compare dates
                if let date1 = value1 as? Date, let date2 = value2 as? Date {
                    return descriptor.ascending ? date1 < date2 : date1 > date2
                }

                return false
            }
        }

        print("MockCloudKitService: Queried \(sorted.count) records of type \(T.recordType)")
        return sorted
    }

    func fetchAll<T: CloudKitRecord>(type: T.Type) async throws -> [T] {
        return try await query(type: type)
    }

    // MARK: - Update

    func update<T: CloudKitRecord>(_ record: T) async throws -> T {
        return try await save(record)
    }

    // MARK: - Delete

    func delete<T: CloudKitRecord>(id: String, type: T.Type) async throws {
        recordsById.removeValue(forKey: id)
        print("MockCloudKitService: Deleted \(T.recordType) with id: \(id)")
    }

    func delete<T: CloudKitRecord>(_ record: T) async throws {
        try await delete(id: record.id, type: T.self)
    }

    func deleteAll<T: CloudKitRecord>(_ records: [T]) async throws {
        for record in records {
            recordsById.removeValue(forKey: record.id)
        }
        print("MockCloudKitService: Deleted \(records.count) records")
    }

    // MARK: - Development Helpers

    /// Seed mock data for testing
    func seedMockData() async {
        // Add some sample knowledge entries
        let sampleEntries = [
            KnowledgeEntry(
                title: "Welcome to Cortex",
                content: "This is a sample entry to get you started. Cortex is your second brain!",
                tags: ["welcome", "demo"]
            ),
            KnowledgeEntry(
                title: "Swift Concurrency",
                content: "Modern Swift uses async/await for asynchronous programming. Actors provide thread-safe state isolation.",
                tags: ["swift", "programming", "concurrency"]
            ),
            KnowledgeEntry(
                title: "MVVM Architecture",
                content: "Model-View-ViewModel separates concerns: Models hold data, Views display UI, ViewModels coordinate between them.",
                tags: ["architecture", "swift", "patterns"]
            ),
            KnowledgeEntry(
                title: "CloudKit Integration",
                content: "CloudKit provides seamless iCloud sync for macOS and iOS apps. Private databases keep user data secure.",
                tags: ["cloudkit", "apple", "sync"]
            ),
            KnowledgeEntry(
                title: "SwiftUI Best Practices",
                content: "@Observable is the modern way to handle state in SwiftUI. Use @State for view-local state, @Environment for dependency injection.",
                tags: ["swiftui", "swift", "ui"]
            )
        ]

        for entry in sampleEntries {
            recordsById[entry.id] = entry
        }

        print("MockCloudKitService: Seeded \(sampleEntries.count) sample entries")
    }

    /// Clear all mock data
    func clearAllData() {
        recordsById.removeAll()
        print("MockCloudKitService: Cleared all data")
    }
}
