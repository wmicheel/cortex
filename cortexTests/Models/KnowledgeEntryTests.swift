//
//  KnowledgeEntryTests.swift
//  CortexTests
//
//  Created by Claude Code
//

import XCTest
import CloudKit
@testable import cortex

final class KnowledgeEntryTests: XCTestCase {
    // MARK: - Initialization Tests

    func testInitialization() {
        let entry = KnowledgeEntry(
            title: "Test Entry",
            content: "Test content",
            tags: ["test", "swift"]
        )

        XCTAssertFalse(entry.id.isEmpty)
        XCTAssertEqual(entry.title, "Test Entry")
        XCTAssertEqual(entry.content, "Test content")
        XCTAssertEqual(entry.tags, ["test", "swift"])
    }

    // MARK: - CloudKit Conversion Tests

    func testToCKRecord() {
        let entry = KnowledgeEntry(
            id: "test-id",
            title: "Test Entry",
            content: "Test content",
            tags: ["test"]
        )

        let record = entry.toCKRecord()

        XCTAssertEqual(record.recordID.recordName, "test-id")
        XCTAssertEqual(record.recordType, "KnowledgeEntry")
        XCTAssertEqual(record["title"] as? String, "Test Entry")
        XCTAssertEqual(record["content"] as? String, "Test content")
        XCTAssertEqual(record["tags"] as? [String], ["test"])
    }

    func testFromCKRecord() {
        let recordID = CKRecord.ID(recordName: "test-id")
        let record = CKRecord(recordType: "KnowledgeEntry", recordID: recordID)
        record["title"] = "Test Entry"
        record["content"] = "Test content"
        record["tags"] = ["test", "swift"]
        record["createdAt"] = Date()
        record["modifiedAt"] = Date()

        let entry = KnowledgeEntry(from: record)

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.id, "test-id")
        XCTAssertEqual(entry?.title, "Test Entry")
        XCTAssertEqual(entry?.content, "Test content")
        XCTAssertEqual(entry?.tags, ["test", "swift"])
    }

    func testFromCKRecordWithInvalidData() {
        let recordID = CKRecord.ID(recordName: "test-id")
        let record = CKRecord(recordType: "KnowledgeEntry", recordID: recordID)
        // Missing required fields

        let entry = KnowledgeEntry(from: record)

        XCTAssertNil(entry)
    }

    // MARK: - Tag Management Tests

    func testHasTag() {
        let entry = KnowledgeEntry(
            title: "Test",
            content: "Content",
            tags: ["swift", "ios"]
        )

        XCTAssertTrue(entry.hasTag("swift"))
        XCTAssertTrue(entry.hasTag("ios"))
        XCTAssertFalse(entry.hasTag("android"))
    }

    func testAddTag() {
        var entry = KnowledgeEntry(
            title: "Test",
            content: "Content",
            tags: ["swift"]
        )

        entry.addTag("ios")

        XCTAssertTrue(entry.hasTag("ios"))
        XCTAssertEqual(entry.tags.count, 2)
    }

    func testAddDuplicateTag() {
        var entry = KnowledgeEntry(
            title: "Test",
            content: "Content",
            tags: ["swift"]
        )

        entry.addTag("swift")

        XCTAssertEqual(entry.tags.count, 1)
    }

    func testRemoveTag() {
        var entry = KnowledgeEntry(
            title: "Test",
            content: "Content",
            tags: ["swift", "ios"]
        )

        entry.removeTag("swift")

        XCTAssertFalse(entry.hasTag("swift"))
        XCTAssertEqual(entry.tags.count, 1)
    }

    // MARK: - Search Tests

    func testMatchesSearchText() {
        let entry = KnowledgeEntry(
            title: "SwiftUI Guide",
            content: "Learn SwiftUI with this comprehensive guide",
            tags: ["swift", "ui"]
        )

        XCTAssertTrue(entry.matches(searchText: "SwiftUI"))
        XCTAssertTrue(entry.matches(searchText: "guide"))
        XCTAssertTrue(entry.matches(searchText: "swift"))
        XCTAssertFalse(entry.matches(searchText: "kotlin"))
    }

    func testMatchesIsCaseInsensitive() {
        let entry = KnowledgeEntry(
            title: "SwiftUI Guide",
            content: "Content",
            tags: []
        )

        XCTAssertTrue(entry.matches(searchText: "swiftui"))
        XCTAssertTrue(entry.matches(searchText: "GUIDE"))
    }

    // MARK: - Equatable Tests

    func testEquality() {
        let entry1 = KnowledgeEntry(
            id: "same-id",
            title: "Entry 1",
            content: "Content 1"
        )

        let entry2 = KnowledgeEntry(
            id: "same-id",
            title: "Entry 2",
            content: "Content 2"
        )

        XCTAssertEqual(entry1, entry2)
    }

    func testInequality() {
        let entry1 = KnowledgeEntry(
            id: "id-1",
            title: "Entry 1",
            content: "Content 1"
        )

        let entry2 = KnowledgeEntry(
            id: "id-2",
            title: "Entry 1",
            content: "Content 1"
        )

        XCTAssertNotEqual(entry1, entry2)
    }

    // MARK: - Touch Tests

    func testTouch() {
        var entry = KnowledgeEntry(
            title: "Test",
            content: "Content"
        )

        let originalModifiedDate = entry.modifiedAt

        // Wait a bit to ensure timestamp changes
        Thread.sleep(forTimeInterval: 0.1)

        entry.touch()

        XCTAssertGreaterThan(entry.modifiedAt, originalModifiedDate)
    }
}
