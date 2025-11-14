//
//  KnowledgeServiceProtocol.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation

/// Protocol for knowledge service implementations
/// Allows swapping between real CloudKit and Mock implementations
protocol KnowledgeServiceProtocol {
    // MARK: - Create

    func create(title: String, content: String, tags: [String], autoTag: Bool, useAITagging: Bool) async throws -> KnowledgeEntry
    func suggestTags(title: String, content: String) async -> [String]

    // MARK: - Read

    func fetch(id: String) async throws -> KnowledgeEntry
    func fetchAll(forceRefresh: Bool) async throws -> [KnowledgeEntry]
    func search(query: String) async throws -> [KnowledgeEntry]
    func fetchEntries(withTag tag: String) async throws -> [KnowledgeEntry]
    func fetchAllTags() async throws -> [String]

    // MARK: - Update

    func update(_ entry: KnowledgeEntry) async throws -> KnowledgeEntry
    func updateContent(id: String, title: String, content: String) async throws -> KnowledgeEntry
    func addTag(_ tag: String, to entryId: String) async throws -> KnowledgeEntry
    func removeTag(_ tag: String, from entryId: String) async throws -> KnowledgeEntry

    // MARK: - Delete

    func delete(id: String) async throws
    func delete(_ entry: KnowledgeEntry) async throws
    func deleteAll(_ entries: [KnowledgeEntry]) async throws

    // MARK: - Statistics

    func getStatistics() async throws -> KnowledgeStatistics

    // MARK: - AI Processing

    func processWithAI(_ entry: KnowledgeEntry, tasks: [AITask]) async throws -> KnowledgeEntry
    func processBatchWithAI(_ entries: [KnowledgeEntry], tasks: [AITask], progressCallback: @Sendable @escaping (Int, Int) -> Void) async throws -> AIBatchProcessingResult
}
