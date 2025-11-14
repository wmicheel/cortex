//
//  CloudKitRecord.swift
//  Cortex
//
//  Created by Claude Code
//

import CloudKit
import Foundation

/// Protocol for types that can be stored in CloudKit
protocol CloudKitRecord {
    /// CloudKit record type name
    static var recordType: String { get }

    /// Unique identifier (required for Identifiable conformance)
    var id: String { get }

    /// Convert instance to CloudKit record
    func toCKRecord() -> CKRecord

    /// Initialize from CloudKit record
    init?(from record: CKRecord)
}

/// Extension to provide default implementations
extension CloudKitRecord {
    /// Default record type uses the type name
    static var recordType: String {
        String(describing: Self.self)
    }
}
