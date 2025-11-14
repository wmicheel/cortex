//
//  SwiftDataKnowledgeService.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation
import SwiftData

/// SwiftData-based knowledge service for local persistence
/// Implements KnowledgeServiceProtocol for seamless integration
@MainActor
final class SwiftDataKnowledgeService: KnowledgeServiceProtocol {
    // MARK: - Properties

    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    private let tagExtractor: TagExtractionService
    private var cache: [String: KnowledgeEntry] = [:]

    // MARK: - Initialization

    init() throws {
        // Define schema
        let schema = Schema([KnowledgeEntry.self])

        // Configure storage
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        // Create container
        self.modelContainer = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )

        // Create context
        self.modelContext = ModelContext(modelContainer)

        // Initialize tag extractor
        self.tagExtractor = TagExtractionService()

        print("✅ SwiftDataKnowledgeService initialized successfully")
    }

    // MARK: - Create

    func create(title: String, content: String, tags: [String] = [], autoTag: Bool = true) async throws -> KnowledgeEntry {
        // Auto-tag if enabled
        var finalTags = tags
        if autoTag {
            let suggestedTags = await tagExtractor.suggestTags(title: title, content: content)
            finalTags = Array(Set(tags + suggestedTags))
        }

        // Create entry
        let entry = KnowledgeEntry(
            title: title,
            content: content,
            tags: finalTags
        )

        // Insert into context
        modelContext.insert(entry)

        // Save
        try modelContext.save()

        // Cache
        cache[entry.id] = entry

        print("✅ Created entry: \(entry.title)")
        return entry
    }

    // MARK: - Read

    func fetch(id: String) async throws -> KnowledgeEntry {
        // Check cache first
        if let cached = cache[id] {
            return cached
        }

        // Fetch from SwiftData
        let predicate = #Predicate<KnowledgeEntry> { $0.id == id }
        let descriptor = FetchDescriptor(predicate: predicate)

        guard let entry = try modelContext.fetch(descriptor).first else {
            throw CortexError.cloudKitRecordNotFound
        }

        // Cache
        cache[id] = entry
        return entry
    }

    func fetchAll(forceRefresh: Bool = false) async throws -> [KnowledgeEntry] {
        // Clear cache if forcing refresh
        if forceRefresh {
            cache.removeAll()
        }

        // Fetch all entries, sorted by modified date
        let descriptor = FetchDescriptor<KnowledgeEntry>(
            sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
        )

        let entries = try modelContext.fetch(descriptor)

        // Update cache
        for entry in entries {
            cache[entry.id] = entry
        }

        return entries
    }

    func fetchEntries(withTag tag: String) async throws -> [KnowledgeEntry] {
        // Fetch all and filter by tag
        let allEntries = try await fetchAll()
        return allEntries.filter { $0.hasTag(tag) }
    }

    // MARK: - Update

    func update(_ entry: KnowledgeEntry) async throws -> KnowledgeEntry {
        // Update modified timestamp
        entry.touch()

        // Save context
        try modelContext.save()

        // Update cache
        cache[entry.id] = entry

        print("✅ Updated entry: \(entry.title)")
        return entry
    }

    func addTag(_ tag: String, to entryID: String) async throws -> KnowledgeEntry {
        let entry = try await fetch(id: entryID)
        entry.addTag(tag)
        return try await update(entry)
    }

    func removeTag(_ tag: String, from entryID: String) async throws -> KnowledgeEntry {
        let entry = try await fetch(id: entryID)
        entry.removeTag(tag)
        return try await update(entry)
    }

    func updateContent(id: String, title: String, content: String) async throws -> KnowledgeEntry {
        let entry = try await fetch(id: id)
        entry.title = title
        entry.content = content
        return try await update(entry)
    }

    // MARK: - Delete

    func delete(_ entry: KnowledgeEntry) async throws {
        modelContext.delete(entry)
        try modelContext.save()

        // Remove from cache
        cache.removeValue(forKey: entry.id)

        print("✅ Deleted entry: \(entry.title)")
    }

    func delete(id: String) async throws {
        let entry = try await fetch(id: id)
        try await delete(entry)
    }

    func deleteAll(_ entries: [KnowledgeEntry]) async throws {
        for entry in entries {
            modelContext.delete(entry)
            cache.removeValue(forKey: entry.id)
        }

        try modelContext.save()
        print("✅ Deleted \(entries.count) entries")
    }

    // MARK: - Search

    func search(query: String) async throws -> [KnowledgeEntry] {
        // Fetch all entries
        let allEntries = try await fetchAll()

        // If query is empty, return all
        guard !query.isEmpty else {
            return allEntries
        }

        // Filter using the matches method
        return allEntries.filter { $0.matches(searchText: query) }
    }

    // MARK: - Tags

    func fetchAllTags() async throws -> [String] {
        let allEntries = try await fetchAll()

        // Collect all tags
        var tagSet: Set<String> = []
        for entry in allEntries {
            tagSet.formUnion(entry.tags)
        }

        // Return sorted
        return Array(tagSet).sorted()
    }

    // MARK: - Statistics

    func getStatistics() async throws -> KnowledgeStatistics {
        let entries = try await fetchAll()
        let totalEntries = entries.count

        // Calculate tag count
        var tagCounts: [String: Int] = [:]
        for entry in entries {
            for tag in entry.tags {
                tagCounts[tag, default: 0] += 1
            }
        }

        let totalTags = tagCounts.count

        // Latest entries (top 5)
        let latestEntries = Array(entries.prefix(5))

        // Most used tags with counts (top 10)
        let mostUsedTagsWithCounts = tagCounts.sorted { $0.value > $1.value }
            .prefix(10)
            .map { (tag: $0.key, count: $0.value) }

        return KnowledgeStatistics(
            totalEntries: totalEntries,
            totalTags: totalTags,
            recentEntries: latestEntries,
            mostUsedTags: Array(mostUsedTagsWithCounts)
        )
    }

    // MARK: - Tag Suggestions

    func suggestTags(title: String, content: String) async -> [String] {
        return await tagExtractor.suggestTags(title: title, content: content)
    }

    // MARK: - AI Processing

    func processWithAI(_ entry: KnowledgeEntry, tasks: [AITask]) async throws -> KnowledgeEntry {
        // TODO: Implement AI processing for SwiftData service
        // For now, return entry unchanged
        return entry
    }

    func processBatchWithAI(
        _ entries: [KnowledgeEntry],
        tasks: [AITask],
        progressCallback: @Sendable @escaping (Int, Int) -> Void
    ) async throws -> AIBatchProcessingResult {
        // TODO: Implement batch AI processing for SwiftData service
        // For now, return empty result
        return AIBatchProcessingResult(
            totalEntries: entries.count,
            successfulEntries: 0,
            failedEntries: 0,
            results: [:],
            duration: 0.0,
            startedAt: Date(),
            completedAt: Date()
        )
    }
}
