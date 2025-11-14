//
//  KnowledgeService.swift
//  Cortex
//
//  Created by Claude Code
//

import CloudKit
import Foundation

/// Domain-specific service for knowledge management operations
actor KnowledgeService: KnowledgeServiceProtocol {
    // MARK: - Properties

    /// CloudKit service for data persistence
    private let cloudKitService: CloudKitService

    /// Tag extraction service for auto-tagging
    private let tagExtractor: TagExtractionService

    /// In-memory cache for faster access
    private var cache: [String: KnowledgeEntry] = [:]

    /// Cache invalidation timestamp
    private var cacheTimestamp: Date?

    /// Cache validity duration (5 minutes)
    private let cacheValidityDuration: TimeInterval = 300

    // MARK: - Initialization

    init(cloudKitService: CloudKitService = CloudKitService(), tagExtractor: TagExtractionService = TagExtractionService()) {
        self.cloudKitService = cloudKitService
        self.tagExtractor = tagExtractor
    }

    // MARK: - Cache Management

    /// Check if cache is valid
    private var isCacheValid: Bool {
        guard let timestamp = cacheTimestamp else { return false }
        return Date().timeIntervalSince(timestamp) < cacheValidityDuration
    }

    /// Invalidate cache
    private func invalidateCache() {
        cache.removeAll()
        cacheTimestamp = nil
    }

    /// Update cache with entry
    private func updateCache(with entry: KnowledgeEntry) {
        cache[entry.id] = entry
    }

    /// Remove entry from cache
    private func removeFromCache(id: String) {
        cache.removeValue(forKey: id)
    }

    // MARK: - Create

    /// Create a new knowledge entry
    /// - Parameters:
    ///   - title: Entry title
    ///   - content: Entry content
    ///   - tags: User-provided tags
    ///   - autoTag: Whether to auto-suggest additional tags
    /// - Returns: Created knowledge entry
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

        let savedEntry = try await cloudKitService.save(entry)
        updateCache(with: savedEntry)

        return savedEntry
    }

    /// Suggest tags for title and content without creating entry
    func suggestTags(title: String, content: String) async -> [String] {
        return await tagExtractor.suggestTags(title: title, content: content)
    }

    // MARK: - Read

    /// Fetch a knowledge entry by ID
    func fetch(id: String) async throws -> KnowledgeEntry {
        // Check cache first
        if isCacheValid, let cachedEntry = cache[id] {
            return cachedEntry
        }

        // Fetch from CloudKit
        let entry = try await cloudKitService.fetch(id: id, type: KnowledgeEntry.self)
        updateCache(with: entry)

        return entry
    }

    /// Fetch all knowledge entries
    func fetchAll(forceRefresh: Bool = false) async throws -> [KnowledgeEntry] {
        // Use cache if valid and not forcing refresh
        if !forceRefresh && isCacheValid && !cache.isEmpty {
            return Array(cache.values).sorted { $0.modifiedAt > $1.modifiedAt }
        }

        // Fetch from CloudKit with sort by modification date
        let sortDescriptor = NSSortDescriptor(key: "modifiedAt", ascending: false)
        let entries = try await cloudKitService.query(
            type: KnowledgeEntry.self,
            sortDescriptors: [sortDescriptor]
        )

        // Update cache
        invalidateCache()
        for entry in entries {
            updateCache(with: entry)
        }
        cacheTimestamp = Date()

        return entries
    }

    /// Search knowledge entries
    func search(query: String) async throws -> [KnowledgeEntry] {
        // For now, fetch all and filter locally
        // In production, this should use CloudKit queries for better performance
        let allEntries = try await fetchAll()

        guard !query.isEmpty else {
            return allEntries
        }

        return allEntries.filter { $0.matches(searchText: query) }
    }

    /// Fetch entries with specific tag
    func fetchEntries(withTag tag: String) async throws -> [KnowledgeEntry] {
        let allEntries = try await fetchAll()
        return allEntries.filter { $0.hasTag(tag) }
    }

    /// Get all unique tags
    func fetchAllTags() async throws -> [String] {
        let entries = try await fetchAll()
        let allTags = entries.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }

    // MARK: - Update

    /// Update a knowledge entry
    func update(_ entry: KnowledgeEntry) async throws -> KnowledgeEntry {
        var updatedEntry = entry
        updatedEntry.touch()

        let savedEntry = try await cloudKitService.update(updatedEntry)
        updateCache(with: savedEntry)

        return savedEntry
    }

    /// Update entry content
    func updateContent(id: String, title: String, content: String) async throws -> KnowledgeEntry {
        var entry = try await fetch(id: id)
        entry.title = title
        entry.content = content

        return try await update(entry)
    }

    /// Add tag to entry
    func addTag(_ tag: String, to entryId: String) async throws -> KnowledgeEntry {
        var entry = try await fetch(id: entryId)
        entry.addTag(tag)

        return try await update(entry)
    }

    /// Remove tag from entry
    func removeTag(_ tag: String, from entryId: String) async throws -> KnowledgeEntry {
        var entry = try await fetch(id: entryId)
        entry.removeTag(tag)

        return try await update(entry)
    }

    // MARK: - Delete

    /// Delete a knowledge entry
    func delete(id: String) async throws {
        try await cloudKitService.delete(id: id, type: KnowledgeEntry.self)
        removeFromCache(id: id)
    }

    /// Delete a knowledge entry
    func delete(_ entry: KnowledgeEntry) async throws {
        try await delete(id: entry.id)
    }

    /// Delete multiple entries
    func deleteAll(_ entries: [KnowledgeEntry]) async throws {
        try await cloudKitService.deleteAll(entries)
        for entry in entries {
            removeFromCache(id: entry.id)
        }
    }

    // MARK: - Statistics

    /// Get entry statistics
    func getStatistics() async throws -> KnowledgeStatistics {
        let entries = try await fetchAll()

        return KnowledgeStatistics(
            totalEntries: entries.count,
            totalTags: Set(entries.flatMap { $0.tags }).count,
            recentEntries: entries.prefix(5).map { $0 },
            mostUsedTags: calculateMostUsedTags(from: entries)
        )
    }

    /// Calculate most used tags
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

// MARK: - Supporting Types

/// Knowledge base statistics
struct KnowledgeStatistics: Sendable {
    let totalEntries: Int
    let totalTags: Int
    let recentEntries: [KnowledgeEntry]
    let mostUsedTags: [(tag: String, count: Int)]
}
