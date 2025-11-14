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
    private let aiCoordinator: AICoordinatorService
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

        // Initialize AI coordinator
        self.aiCoordinator = AICoordinatorService()

        print("✅ SwiftDataKnowledgeService initialized successfully")
    }

    // MARK: - Create

    func create(title: String, content: String, tags: [String] = [], autoTag: Bool = true, useAITagging: Bool = false) async throws -> KnowledgeEntry {
        // Auto-tag if enabled
        var finalTags = tags

        // 1. NLP-based tagging (fast, local)
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

        // 2. AI-based tagging (optional, slower but more accurate)
        if useAITagging {
            do {
                // Process with AI for auto-tagging
                let aiResult = try await aiCoordinator.processEntry(
                    entry,
                    tasks: [.autoTagging],
                    allEntries: []
                )

                // Apply AI tags
                if let aiTags = aiResult.tags, !aiTags.isEmpty {
                    entry.aiGeneratedTags = aiTags
                    entry.mergeAITags()
                    try modelContext.save()
                    print("✅ AI-generated tags added: \(aiTags.joined(separator: ", "))")
                }
            } catch {
                print("⚠️ AI tagging failed: \(error.localizedDescription)")
                // Continue anyway - entry is already created with NLP tags
            }
        }

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

    // MARK: - Semantic Search

    /// Generate or update embedding for an entry
    func generateEmbedding(for entry: KnowledgeEntry) async throws {
        let embedding = try await EmbeddingService.shared.generateEmbedding(for: entry)
        entry.updateEmbedding(embedding)
        _ = try await update(entry)
        print("✅ Generated embedding for entry: \(entry.title)")
    }

    /// Generate embeddings for all entries that don't have one or need updates
    func generateMissingEmbeddings(progressCallback: @Sendable @escaping (Int, Int) -> Void = { _, _ in }) async throws {
        let allEntries = try await fetchAll()

        // Find entries that need embeddings
        let entriesToProcess = allEntries.filter { $0.embedding == nil || $0.needsEmbeddingUpdate() }

        guard !entriesToProcess.isEmpty else {
            print("✅ All entries have up-to-date embeddings")
            return
        }

        print("📊 Generating embeddings for \(entriesToProcess.count) entries...")

        // Generate embeddings in batches
        let embeddings = try await EmbeddingService.shared.generateEmbeddings(for: entriesToProcess)

        // Update entries with embeddings
        for (index, entry) in entriesToProcess.enumerated() {
            if let embedding = embeddings[entry.id] {
                entry.updateEmbedding(embedding)
                try modelContext.save()
                progressCallback(index + 1, entriesToProcess.count)
            }
        }

        print("✅ Generated \(embeddings.count) embeddings")
    }

    /// Search entries using semantic similarity
    func semanticSearch(
        query: String,
        limit: Int = 10,
        threshold: Double = 0.5
    ) async throws -> [(entry: KnowledgeEntry, similarity: Double)] {
        let allEntries = try await fetchAll()

        // Filter entries that have embeddings
        let entriesWithEmbeddings = allEntries.filter { $0.hasEmbedding }

        guard !entriesWithEmbeddings.isEmpty else {
            print("⚠️ No entries have embeddings. Generate embeddings first.")
            return []
        }

        // Perform semantic search
        let results = try await EmbeddingService.shared.search(
            query: query,
            in: entriesWithEmbeddings,
            limit: limit,
            threshold: threshold
        )

        print("✅ Semantic search found \(results.count) results")
        return results
    }

    /// Hybrid search: combines keyword and semantic search
    func hybridSearch(
        query: String,
        limit: Int = 10,
        semanticWeight: Double = 0.6 // 60% semantic, 40% keyword
    ) async throws -> [KnowledgeEntry] {
        // Perform both searches in parallel
        async let keywordResults = search(query: query)
        async let semanticResults = semanticSearch(query: query, limit: limit * 2)

        let keywords = try await keywordResults
        let semantic = try await semanticResults

        // Combine results with weighted scoring
        var scores: [String: Double] = [:]

        // Keyword matches get base score
        for entry in keywords {
            scores[entry.id] = 1.0 - semanticWeight // e.g., 0.4
        }

        // Semantic matches get similarity score
        for (entry, similarity) in semantic {
            let semanticScore = similarity * semanticWeight // e.g., similarity * 0.6
            scores[entry.id, default: 0.0] += semanticScore
        }

        // Get all unique entries
        let allResults = Set(keywords.map(\.id) + semantic.map(\.entry.id))

        // Sort by combined score
        let sortedIDs = allResults.sorted { id1, id2 in
            (scores[id1] ?? 0) > (scores[id2] ?? 0)
        }

        // Fetch and return entries
        var results: [KnowledgeEntry] = []
        for id in sortedIDs.prefix(limit) {
            if let entry = try? await fetch(id: id) {
                results.append(entry)
            }
        }

        print("✅ Hybrid search found \(results.count) results")
        return results
    }

    /// Find entries similar to a given entry
    func findSimilar(
        to entry: KnowledgeEntry,
        limit: Int = 5,
        threshold: Double = 0.6
    ) async throws -> [(entry: KnowledgeEntry, similarity: Double)] {
        guard let queryEmbedding = entry.embedding else {
            throw CortexError.invalidData
        }

        let allEntries = try await fetchAll()

        // Filter out the query entry itself and entries without embeddings
        let candidates = allEntries.filter { $0.id != entry.id && $0.hasEmbedding }

        // Find similar entries
        let results = await EmbeddingService.shared.findSimilar(
            to: queryEmbedding,
            in: candidates,
            limit: limit,
            threshold: threshold
        )

        print("✅ Found \(results.count) similar entries to '\(entry.title)'")
        return results
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
        // Fetch all entries for link finding context
        let allEntries = try await fetchAll()

        // Process entry with AI coordinator
        let result = try await aiCoordinator.processEntry(entry, tasks: tasks, allEntries: allEntries)

        // Apply AI results to entry
        entry.updateAIResults(
            tags: result.tags,
            summary: result.summary,
            relatedIDs: result.relatedEntryIDs
        )

        // If auto-tagging was performed and successful, merge AI tags with existing tags
        if result.wasCompleted(.autoTagging), let aiTags = result.tags, !aiTags.isEmpty {
            entry.mergeAITags()
        }

        // Save updated entry
        _ = try await update(entry)

        print("✅ AI processing completed for entry: \(entry.title)")
        return entry
    }

    func processBatchWithAI(
        _ entries: [KnowledgeEntry],
        tasks: [AITask],
        progressCallback: @Sendable @escaping (Int, Int) -> Void
    ) async throws -> AIBatchProcessingResult {
        // Process batch with AI coordinator
        let result = try await aiCoordinator.processBatch(
            entries,
            tasks: tasks,
            progressCallback: progressCallback
        )

        // Apply results to each entry
        for (entryID, processingResult) in result.results {
            guard let entry = try? await fetch(id: entryID) else { continue }

            // Update entry with AI results
            entry.updateAIResults(
                tags: processingResult.tags,
                summary: processingResult.summary,
                relatedIDs: processingResult.relatedEntryIDs
            )

            // Merge AI tags if auto-tagging was successful
            if processingResult.wasCompleted(.autoTagging),
               let aiTags = processingResult.tags,
               !aiTags.isEmpty {
                entry.mergeAITags()
            }

            // Save updated entry
            _ = try? await update(entry)
        }

        print("✅ Batch AI processing completed: \(result.successfulEntries)/\(result.totalEntries) successful")
        return result
    }
}
