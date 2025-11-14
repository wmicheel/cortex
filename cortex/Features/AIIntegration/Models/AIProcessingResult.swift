//
//  AIProcessingResult.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation

/// Result of AI processing for a Knowledge Entry
struct AIProcessingResult: Codable, Sendable {
    // MARK: - Properties

    /// Generated tags (from auto-tagging)
    var tags: [String]?

    /// Generated summary (from summarization)
    var summary: String?

    /// IDs of related/similar entries (from link finding)
    var relatedEntryIDs: [String]?

    /// Enriched content (from content enrichment)
    var enrichedContent: String?

    /// Which tasks were successfully completed
    var completedTasks: [AITask]

    /// Which service was used for each task
    var serviceUsed: [AITask: AIServiceType]

    /// Processing timestamp
    var processedAt: Date

    /// Any errors that occurred during processing
    var errors: [AITask: String]

    // MARK: - Initialization

    init(
        tags: [String]? = nil,
        summary: String? = nil,
        relatedEntryIDs: [String]? = nil,
        enrichedContent: String? = nil,
        completedTasks: [AITask] = [],
        serviceUsed: [AITask: AIServiceType] = [:],
        processedAt: Date = Date(),
        errors: [AITask: String] = [:]
    ) {
        self.tags = tags
        self.summary = summary
        self.relatedEntryIDs = relatedEntryIDs
        self.enrichedContent = enrichedContent
        self.completedTasks = completedTasks
        self.serviceUsed = serviceUsed
        self.processedAt = processedAt
        self.errors = errors
    }

    // MARK: - Helper Methods

    /// Check if a specific task was completed successfully
    func wasCompleted(_ task: AITask) -> Bool {
        completedTasks.contains(task)
    }

    /// Get error message for a specific task
    func error(for task: AITask) -> String? {
        errors[task]
    }

    /// Check if any tasks failed
    var hasErrors: Bool {
        !errors.isEmpty
    }

    /// Get number of successfully completed tasks
    var successCount: Int {
        completedTasks.count
    }

    /// Get number of failed tasks
    var errorCount: Int {
        errors.count
    }
}

// MARK: - Batch Processing Result

/// Result of batch processing multiple entries
struct AIBatchProcessingResult: Sendable {
    /// Total number of entries processed
    let totalEntries: Int

    /// Number of successfully processed entries
    let successfulEntries: Int

    /// Number of failed entries
    let failedEntries: Int

    /// Individual results per entry
    let results: [String: AIProcessingResult]  // Entry ID -> Result

    /// Overall processing duration
    let duration: TimeInterval

    /// Timestamp when batch started
    let startedAt: Date

    /// Timestamp when batch completed
    let completedAt: Date

    // MARK: - Helper Properties

    var successRate: Double {
        guard totalEntries > 0 else { return 0 }
        return Double(successfulEntries) / Double(totalEntries)
    }

    var hasFailures: Bool {
        failedEntries > 0
    }
}

// MARK: - Processing Status

/// Status of ongoing AI processing
enum AIProcessingStatus: Sendable {
    case idle
    case processing(current: Int, total: Int)
    case completed(result: AIBatchProcessingResult)
    case failed(error: Error)

    var isProcessing: Bool {
        if case .processing = self {
            return true
        }
        return false
    }

    var progress: Double? {
        if case .processing(let current, let total) = self, total > 0 {
            return Double(current) / Double(total)
        }
        return nil
    }
}
