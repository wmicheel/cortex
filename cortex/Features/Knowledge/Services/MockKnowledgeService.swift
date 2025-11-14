//
//  MockKnowledgeService.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation

/// Mock knowledge service using in-memory storage
/// Use this for development without CloudKit/iCloud
actor MockKnowledgeService: KnowledgeServiceProtocol {
    // MARK: - Properties

    private let mockCloudKit: MockCloudKitService
    private let tagExtractor: TagExtractionService
    private var cache: [String: KnowledgeEntry] = [:]
    private var cacheTimestamp: Date?
    private let cacheValidityDuration: TimeInterval = 300

    // MARK: - Initialization

    init(mockCloudKit: MockCloudKitService = MockCloudKitService(), tagExtractor: TagExtractionService = TagExtractionService()) {
        self.mockCloudKit = mockCloudKit
        self.tagExtractor = tagExtractor

        // Seed initial data
        Task {
            await mockCloudKit.seedMockData()
        }
    }

    // MARK: - Cache Management

    private var isCacheValid: Bool {
        guard let timestamp = cacheTimestamp else { return false }
        return Date().timeIntervalSince(timestamp) < cacheValidityDuration
    }

    private func invalidateCache() {
        cache.removeAll()
        cacheTimestamp = nil
    }

    private func updateCache(with entry: KnowledgeEntry) {
        cache[entry.id] = entry
    }

    private func removeFromCache(id: String) {
        cache.removeValue(forKey: id)
    }

    // MARK: - Create

    func create(title: String, content: String, tags: [String] = [], autoTag: Bool = true) async throws -> KnowledgeEntry {
        var finalTags = tags

        // Auto-suggest tags if enabled
        if autoTag {
            let suggestedTags = await tagExtractor.suggestTags(title: title, content: content)
            finalTags = Array(Set(tags + suggestedTags)) // Merge and deduplicate
        }

        let entry = KnowledgeEntry(
            title: title,
            content: content,
            tags: finalTags
        )

        let savedEntry = try await mockCloudKit.save(entry)
        updateCache(with: savedEntry)

        return savedEntry
    }

    func suggestTags(title: String, content: String) async -> [String] {
        return await tagExtractor.suggestTags(title: title, content: content)
    }

    // MARK: - Read

    func fetch(id: String) async throws -> KnowledgeEntry {
        if isCacheValid, let cachedEntry = cache[id] {
            return cachedEntry
        }

        let entry = try await mockCloudKit.fetch(id: id, type: KnowledgeEntry.self)
        updateCache(with: entry)

        return entry
    }

    func fetchAll(forceRefresh: Bool = false) async throws -> [KnowledgeEntry] {
        if !forceRefresh && isCacheValid && !cache.isEmpty {
            return Array(cache.values).sorted { $0.modifiedAt > $1.modifiedAt }
        }

        let sortDescriptor = NSSortDescriptor(key: "modifiedAt", ascending: false)
        let entries = try await mockCloudKit.query(
            type: KnowledgeEntry.self,
            sortDescriptors: [sortDescriptor]
        )

        invalidateCache()
        for entry in entries {
            updateCache(with: entry)
        }
        cacheTimestamp = Date()

        return entries
    }

    func search(query: String) async throws -> [KnowledgeEntry] {
        let allEntries = try await fetchAll()

        guard !query.isEmpty else {
            return allEntries
        }

        return allEntries.filter { $0.matches(searchText: query) }
    }

    func fetchEntries(withTag tag: String) async throws -> [KnowledgeEntry] {
        let allEntries = try await fetchAll()
        return allEntries.filter { $0.hasTag(tag) }
    }

    func fetchAllTags() async throws -> [String] {
        let entries = try await fetchAll()
        let allTags = entries.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }

    // MARK: - Update

    func update(_ entry: KnowledgeEntry) async throws -> KnowledgeEntry {
        var updatedEntry = entry
        updatedEntry.touch()

        let savedEntry = try await mockCloudKit.update(updatedEntry)
        updateCache(with: savedEntry)

        return savedEntry
    }

    func updateContent(id: String, title: String, content: String) async throws -> KnowledgeEntry {
        var entry = try await fetch(id: id)
        entry.title = title
        entry.content = content

        return try await update(entry)
    }

    func addTag(_ tag: String, to entryId: String) async throws -> KnowledgeEntry {
        var entry = try await fetch(id: entryId)
        entry.addTag(tag)

        return try await update(entry)
    }

    func removeTag(_ tag: String, from entryId: String) async throws -> KnowledgeEntry {
        var entry = try await fetch(id: entryId)
        entry.removeTag(tag)

        return try await update(entry)
    }

    // MARK: - Delete

    func delete(id: String) async throws {
        try await mockCloudKit.delete(id: id, type: KnowledgeEntry.self)
        removeFromCache(id: id)
    }

    func delete(_ entry: KnowledgeEntry) async throws {
        try await delete(id: entry.id)
    }

    func deleteAll(_ entries: [KnowledgeEntry]) async throws {
        try await mockCloudKit.deleteAll(entries)
        for entry in entries {
            removeFromCache(id: entry.id)
        }
    }

    // MARK: - Statistics

    func getStatistics() async throws -> KnowledgeStatistics {
        let entries = try await fetchAll()

        return KnowledgeStatistics(
            totalEntries: entries.count,
            totalTags: Set(entries.flatMap { $0.tags }).count,
            recentEntries: entries.prefix(5).map { $0 },
            mostUsedTags: calculateMostUsedTags(from: entries)
        )
    }

    private func calculateMostUsedTags(from entries: [KnowledgeEntry], limit: Int = 10) -> [(tag: String, count: Int)] {
        var tagCounts: [String: Int] = [:]

        for entry in entries {
            for tag in entry.tags {
                tagCounts[tag, default: 0] += 1
            }
        }

        return tagCounts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (tag: $0.key, count: $0.value) }
    }
}
