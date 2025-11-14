//
//  KnowledgeEntry.swift
//  Cortex
//
//  Created by Claude Code
//

import CloudKit
import Foundation

/// Represents a knowledge entry in the user's Second Brain
struct KnowledgeEntry: CloudKitRecord, Identifiable, Sendable {
    // MARK: - Properties

    /// Unique identifier
    let id: String

    /// Entry title
    var title: String

    /// Entry content (markdown supported)
    var content: String

    /// Tags for categorization
    var tags: [String]

    /// Creation timestamp
    let createdAt: Date

    /// Last modification timestamp
    var modifiedAt: Date

    /// Linked Apple Reminders identifier
    var linkedReminderID: String?

    /// Linked Apple Calendar event identifier
    var linkedCalendarEventID: String?

    // MARK: - CloudKit Configuration

    nonisolated static let recordType = "KnowledgeEntry"

    // MARK: - Initialization

    /// Initialize a new knowledge entry
    nonisolated init(
        id: String = UUID().uuidString,
        title: String,
        content: String,
        tags: [String] = [],
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        linkedReminderID: String? = nil,
        linkedCalendarEventID: String? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.tags = tags
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.linkedReminderID = linkedReminderID
        self.linkedCalendarEventID = linkedCalendarEventID
    }

    // MARK: - CloudKitRecord Conformance

    /// Convert to CloudKit record
    nonisolated func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)

        record["title"] = title as CKRecordValue
        record["content"] = content as CKRecordValue
        record["tags"] = tags as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["modifiedAt"] = modifiedAt as CKRecordValue
        record["linkedReminderID"] = linkedReminderID as CKRecordValue?
        record["linkedCalendarEventID"] = linkedCalendarEventID as CKRecordValue?

        return record
    }

    /// Initialize from CloudKit record
    nonisolated init?(from record: CKRecord) {
        guard
            let title = record["title"] as? String,
            let content = record["content"] as? String,
            let createdAt = record["createdAt"] as? Date,
            let modifiedAt = record["modifiedAt"] as? Date
        else {
            return nil
        }

        self.id = record.recordID.recordName
        self.title = title
        self.content = content
        self.tags = record["tags"] as? [String] ?? []
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.linkedReminderID = record["linkedReminderID"] as? String
        self.linkedCalendarEventID = record["linkedCalendarEventID"] as? String
    }
}

// MARK: - Equatable

extension KnowledgeEntry: Equatable {
    nonisolated static func == (lhs: KnowledgeEntry, rhs: KnowledgeEntry) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension KnowledgeEntry: Hashable {
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Helper Methods

extension KnowledgeEntry {
    /// Update the modified timestamp
    nonisolated mutating func touch() {
        self.modifiedAt = Date()
    }

    /// Check if entry has a specific tag
    nonisolated func hasTag(_ tag: String) -> Bool {
        tags.contains(tag)
    }

    /// Add a tag if not already present
    nonisolated mutating func addTag(_ tag: String) {
        guard !tags.contains(tag) else { return }
        tags.append(tag)
        touch()
    }

    /// Remove a tag
    nonisolated mutating func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
        touch()
    }

    /// Check if entry matches search query
    nonisolated func matches(searchText: String) -> Bool {
        let lowercasedQuery = searchText.lowercased()
        return title.lowercased().contains(lowercasedQuery) ||
               content.lowercased().contains(lowercasedQuery) ||
               tags.contains { $0.lowercased().contains(lowercasedQuery) }
    }

    /// Link a reminder to this entry
    nonisolated mutating func linkReminder(_ reminderID: String) {
        self.linkedReminderID = reminderID
        touch()
    }

    /// Unlink the reminder from this entry
    nonisolated mutating func unlinkReminder() {
        self.linkedReminderID = nil
        touch()
    }

    /// Check if entry has a linked reminder
    nonisolated var hasLinkedReminder: Bool {
        linkedReminderID != nil
    }

    /// Link a calendar event to this entry
    nonisolated mutating func linkCalendarEvent(_ eventID: String) {
        self.linkedCalendarEventID = eventID
        touch()
    }

    /// Unlink the calendar event from this entry
    nonisolated mutating func unlinkCalendarEvent() {
        self.linkedCalendarEventID = nil
        touch()
    }

    /// Check if entry has a linked calendar event
    nonisolated var hasLinkedCalendarEvent: Bool {
        linkedCalendarEventID != nil
    }
}
