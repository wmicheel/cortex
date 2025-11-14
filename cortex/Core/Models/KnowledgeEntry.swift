//
//  KnowledgeEntry.swift
//  Cortex
//
//  Created by Claude Code
//

import CloudKit
import Foundation
import SwiftData

/// Represents a knowledge entry in the user's Second Brain
@Model
final class KnowledgeEntry {
    // MARK: - Properties

    /// Unique identifier
    @Attribute(.unique) var id: String

    /// Entry title
    var title: String

    /// Entry content (markdown supported)
    /// @deprecated Use blocks for new entries
    var content: String

    /// Block-based content (new format)
    @Relationship(deleteRule: .cascade)
    var blocks: [ContentBlock]?

    /// Is this entry using the block-based format?
    var isBlockBased: Bool

    /// Tags for categorization
    var tags: [String]

    /// Creation timestamp
    var createdAt: Date

    /// Last modification timestamp
    var modifiedAt: Date

    /// Linked Apple Reminders identifier
    var linkedReminderID: String?

    /// Linked Apple Calendar event identifier
    var linkedCalendarEventID: String?

    /// Linked Apple Note identifier
    var linkedNoteID: String?

    // MARK: - Semantic Search

    /// OpenAI embedding vector for semantic search (1536 dimensions for text-embedding-3-small)
    var embedding: [Double]?

    /// Timestamp when embedding was last generated
    var embeddingGeneratedAt: Date?

    // MARK: - AI Processing

    /// AI-generated tags
    var aiGeneratedTags: [String]?

    /// AI-generated summary
    var aiSummary: String?

    /// IDs of related/similar entries found by AI
    var aiRelatedEntryIDs: [String]?

    /// Timestamp when AI last processed this entry
    var aiLastProcessed: Date?

    // MARK: - Initialization

    /// Initialize a new knowledge entry
    init(
        id: String = UUID().uuidString,
        title: String,
        content: String,
        blocks: [ContentBlock]? = nil,
        isBlockBased: Bool = false,
        tags: [String] = [],
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        linkedReminderID: String? = nil,
        linkedCalendarEventID: String? = nil,
        linkedNoteID: String? = nil,
        embedding: [Double]? = nil,
        embeddingGeneratedAt: Date? = nil,
        aiGeneratedTags: [String]? = nil,
        aiSummary: String? = nil,
        aiRelatedEntryIDs: [String]? = nil,
        aiLastProcessed: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.blocks = blocks
        self.isBlockBased = isBlockBased
        self.tags = tags
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.linkedReminderID = linkedReminderID
        self.linkedCalendarEventID = linkedCalendarEventID
        self.linkedNoteID = linkedNoteID
        self.embedding = embedding
        self.embeddingGeneratedAt = embeddingGeneratedAt
        self.aiGeneratedTags = aiGeneratedTags
        self.aiSummary = aiSummary
        self.aiRelatedEntryIDs = aiRelatedEntryIDs
        self.aiLastProcessed = aiLastProcessed
    }
}

// MARK: - CloudKitRecord Conformance (for future migration)

extension KnowledgeEntry: CloudKitRecord {
    static let recordType = "KnowledgeEntry"

    /// Convert to CloudKit record
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)

        record["title"] = title as CKRecordValue
        record["content"] = content as CKRecordValue
        record["tags"] = tags as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["modifiedAt"] = modifiedAt as CKRecordValue
        record["linkedReminderID"] = linkedReminderID as CKRecordValue?
        record["linkedCalendarEventID"] = linkedCalendarEventID as CKRecordValue?
        record["linkedNoteID"] = linkedNoteID as CKRecordValue?
        record["embedding"] = embedding as CKRecordValue?
        record["embeddingGeneratedAt"] = embeddingGeneratedAt as CKRecordValue?
        record["aiGeneratedTags"] = aiGeneratedTags as CKRecordValue?
        record["aiSummary"] = aiSummary as CKRecordValue?
        record["aiRelatedEntryIDs"] = aiRelatedEntryIDs as CKRecordValue?
        record["aiLastProcessed"] = aiLastProcessed as CKRecordValue?

        return record
    }

    /// Initialize from CloudKit record
    convenience init?(from record: CKRecord) {
        guard
            let title = record["title"] as? String,
            let content = record["content"] as? String,
            let createdAt = record["createdAt"] as? Date,
            let modifiedAt = record["modifiedAt"] as? Date
        else {
            return nil
        }

        self.init(
            id: record.recordID.recordName,
            title: title,
            content: content,
            tags: record["tags"] as? [String] ?? [],
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            linkedReminderID: record["linkedReminderID"] as? String,
            linkedCalendarEventID: record["linkedCalendarEventID"] as? String,
            linkedNoteID: record["linkedNoteID"] as? String,
            embedding: record["embedding"] as? [Double],
            embeddingGeneratedAt: record["embeddingGeneratedAt"] as? Date,
            aiGeneratedTags: record["aiGeneratedTags"] as? [String],
            aiSummary: record["aiSummary"] as? String,
            aiRelatedEntryIDs: record["aiRelatedEntryIDs"] as? [String],
            aiLastProcessed: record["aiLastProcessed"] as? Date
        )
    }
}

// MARK: - Helper Methods

extension KnowledgeEntry {
    /// Update the modified timestamp
    func touch() {
        self.modifiedAt = Date()
    }

    /// Check if entry has a specific tag
    func hasTag(_ tag: String) -> Bool {
        tags.contains(tag)
    }

    /// Add a tag if not already present
    func addTag(_ tag: String) {
        guard !tags.contains(tag) else { return }
        tags.append(tag)
        touch()
    }

    /// Remove a tag
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
        touch()
    }

    /// Check if entry matches search query
    func matches(searchText: String) -> Bool {
        let lowercasedQuery = searchText.lowercased()
        return title.lowercased().contains(lowercasedQuery) ||
               content.lowercased().contains(lowercasedQuery) ||
               tags.contains { $0.lowercased().contains(lowercasedQuery) }
    }

    /// Link a reminder to this entry
    func linkReminder(_ reminderID: String) {
        self.linkedReminderID = reminderID
        touch()
    }

    /// Unlink the reminder from this entry
    func unlinkReminder() {
        self.linkedReminderID = nil
        touch()
    }

    /// Check if entry has a linked reminder
    var hasLinkedReminder: Bool {
        linkedReminderID != nil
    }

    /// Link a calendar event to this entry
    func linkCalendarEvent(_ eventID: String) {
        self.linkedCalendarEventID = eventID
        touch()
    }

    /// Unlink the calendar event from this entry
    func unlinkCalendarEvent() {
        self.linkedCalendarEventID = nil
        touch()
    }

    /// Check if entry has a linked calendar event
    var hasLinkedCalendarEvent: Bool {
        linkedCalendarEventID != nil
    }

    /// Link a note to this entry
    func linkNote(_ noteID: String) {
        self.linkedNoteID = noteID
        touch()
    }

    /// Unlink the note from this entry
    func unlinkNote() {
        self.linkedNoteID = nil
        touch()
    }

    /// Check if entry has a linked note
    var hasLinkedNote: Bool {
        linkedNoteID != nil
    }

    // MARK: - AI Processing Helpers

    /// Check if entry has been processed by AI
    var hasAIProcessing: Bool {
        aiLastProcessed != nil
    }

    /// Check if entry has AI-generated tags
    var hasAITags: Bool {
        aiGeneratedTags?.isEmpty == false
    }

    /// Check if entry has AI-generated summary
    var hasAISummary: Bool {
        aiSummary?.isEmpty == false
    }

    /// Check if entry has AI-found related entries
    var hasAIRelations: Bool {
        aiRelatedEntryIDs?.isEmpty == false
    }

    /// Update AI processing results
    func updateAIResults(
        tags: [String]? = nil,
        summary: String? = nil,
        relatedIDs: [String]? = nil
    ) {
        if let tags = tags {
            self.aiGeneratedTags = tags
        }
        if let summary = summary {
            self.aiSummary = summary
        }
        if let relatedIDs = relatedIDs {
            self.aiRelatedEntryIDs = relatedIDs
        }
        self.aiLastProcessed = Date()
        touch()
    }

    /// Clear all AI-generated data
    func clearAIResults() {
        self.aiGeneratedTags = nil
        self.aiSummary = nil
        self.aiRelatedEntryIDs = nil
        self.aiLastProcessed = nil
        touch()
    }

    /// Merge AI-generated tags with manual tags
    func mergeAITags() {
        guard let aiTags = aiGeneratedTags, !aiTags.isEmpty else { return }
        let uniqueTags = Set(tags + aiTags)
        tags = Array(uniqueTags).sorted()
        touch()
    }

    // MARK: - Semantic Search Helpers

    /// Check if entry has an embedding generated
    var hasEmbedding: Bool {
        embedding != nil && !(embedding?.isEmpty ?? true)
    }

    /// Check if embedding needs regeneration (content changed after embedding was generated)
    func needsEmbeddingUpdate() -> Bool {
        guard let embeddingDate = embeddingGeneratedAt else { return true }
        return modifiedAt > embeddingDate
    }

    /// Update embedding vector
    func updateEmbedding(_ vector: [Double]) {
        self.embedding = vector
        self.embeddingGeneratedAt = Date()
        // Don't call touch() here - embedding update shouldn't change modifiedAt
    }

    /// Clear embedding data
    func clearEmbedding() {
        self.embedding = nil
        self.embeddingGeneratedAt = nil
    }

    // MARK: - Block Management Helpers

    /// Get content as text (from blocks or legacy content field)
    func getContentText() -> String {
        if isBlockBased, let blocks = blocks, !blocks.isEmpty {
            return blocks
                .sorted { $0.order < $1.order }
                .map { $0.toMarkdown() }
                .joined(separator: "\n")
        }
        return content
    }

    /// Convert to block-based format
    func convertToBlocks() {
        guard !isBlockBased else { return }

        // Will be implemented by BlockMigrationService
        isBlockBased = true
        touch()
    }

    /// Add a new block
    func addBlock(_ block: ContentBlock) {
        if blocks == nil {
            blocks = []
        }
        blocks?.append(block)
        touch()
    }

    /// Remove a block
    func removeBlock(_ block: ContentBlock) {
        blocks?.removeAll { $0.id == block.id }
        touch()
    }

    /// Get sorted blocks
    func getSortedBlocks() -> [ContentBlock] {
        blocks?.sorted { $0.order < $1.order } ?? []
    }

    /// Reorder blocks
    func reorderBlocks(_ orderedBlocks: [ContentBlock]) {
        for (index, block) in orderedBlocks.enumerated() {
            block.order = index
        }
        blocks = orderedBlocks
        touch()
    }
}
