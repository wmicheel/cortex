//
//  BlockMigrationService.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation
import SwiftData

/// Service for migrating legacy markdown entries to block-based format
@MainActor
@Observable
final class BlockMigrationService {
    // MARK: - Properties

    var isMigrating = false
    var migrationProgress: Double = 0.0
    var currentEntryTitle: String = ""
    var totalEntries: Int = 0
    var migratedEntries: Int = 0

    private let modelContext: ModelContext
    private let parser = MarkdownParser()

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Migration

    /// Check if migration is needed
    func needsMigration() -> Bool {
        do {
            let descriptor = FetchDescriptor<KnowledgeEntry>(
                predicate: #Predicate { entry in
                    entry.isBlockBased == false
                }
            )
            let legacyEntries = try modelContext.fetch(descriptor)
            return !legacyEntries.isEmpty
        } catch {
            print("❌ Error checking migration status: \(error)")
            return false
        }
    }

    /// Perform automatic migration of all legacy entries
    func migrateAllEntries() async throws {
        guard !isMigrating else { return }

        isMigrating = true
        defer { isMigrating = false }

        print("🔄 Starting automatic migration to block-based format...")

        // Fetch all legacy entries
        let descriptor = FetchDescriptor<KnowledgeEntry>(
            predicate: #Predicate { entry in
                entry.isBlockBased == false
            }
        )

        let legacyEntries = try modelContext.fetch(descriptor)
        totalEntries = legacyEntries.count

        print("📊 Found \(totalEntries) entries to migrate")

        guard totalEntries > 0 else {
            print("✅ No entries need migration")
            return
        }

        // Migrate each entry
        for (index, entry) in legacyEntries.enumerated() {
            currentEntryTitle = entry.title
            migratedEntries = index

            do {
                try await migrateEntry(entry)
                migrationProgress = Double(index + 1) / Double(totalEntries)

                // Save periodically
                if (index + 1) % 10 == 0 {
                    try modelContext.save()
                    print("💾 Saved migration progress: \(index + 1)/\(totalEntries)")
                }
            } catch {
                print("❌ Error migrating entry '\(entry.title)': \(error)")
                // Continue with next entry
            }
        }

        // Final save
        try modelContext.save()

        migratedEntries = totalEntries
        migrationProgress = 1.0

        print("✅ Migration completed! Migrated \(totalEntries) entries")
    }

    /// Migrate a single entry from markdown to blocks
    private func migrateEntry(_ entry: KnowledgeEntry) async throws {
        guard !entry.isBlockBased else { return }

        print("🔄 Migrating: \(entry.title)")

        // Parse markdown content into blocks
        let entryID = UUID(uuidString: entry.id) ?? UUID()
        let blocks = await parser.parse(markdown: entry.content, for: entryID)

        print("  → Created \(blocks.count) blocks")

        // Insert blocks into SwiftData context
        for block in blocks {
            modelContext.insert(block)
        }

        // Update entry
        entry.blocks = blocks
        entry.isBlockBased = true
        entry.touch()

        print("  ✅ Migration complete for: \(entry.title)")
    }

    /// Migrate specific entry (manual migration)
    func migrateEntry(id: String) async throws {
        let descriptor = FetchDescriptor<KnowledgeEntry>(
            predicate: #Predicate { entry in
                entry.id == id && entry.isBlockBased == false
            }
        )

        guard let entry = try modelContext.fetch(descriptor).first else {
            throw CortexError.entryNotFound(id: id)
        }

        try await migrateEntry(entry)
        try modelContext.save()
    }

    /// Rollback an entry to markdown format
    func rollbackEntry(_ entry: KnowledgeEntry) throws {
        guard entry.isBlockBased else { return }

        // Remove all blocks
        if let blocks = entry.blocks {
            for block in blocks {
                modelContext.delete(block)
            }
        }

        entry.blocks = nil
        entry.isBlockBased = false
        entry.touch()

        try modelContext.save()

        print("↩️ Rolled back entry to markdown: \(entry.title)")
    }
}
