//
//  AICoordinatorService.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation

/// Coordinates AI processing across different AI services
actor AICoordinatorService {
    // MARK: - Properties

    // Processing queue for batch operations
    private var processingQueue: [String] = []  // Entry IDs
    private var isProcessing = false

    // MARK: - Initialization

    init() {
        // Services are managed by AIConfiguration.shared
    }

    // MARK: - Single Entry Processing

    /// Process a single knowledge entry with specified AI tasks
    func processEntry(
        _ entry: KnowledgeEntry,
        tasks: [AITask],
        allEntries: [KnowledgeEntry] = []
    ) async throws -> AIProcessingResult {
        var result = AIProcessingResult()

        for task in tasks {
            do {
                try await processTask(task, for: entry, result: &result, allEntries: allEntries)
                result.completedTasks.append(task)
            } catch {
                result.errors[task] = error.localizedDescription
            }
        }

        return result
    }

    // MARK: - Batch Processing

    /// Process multiple entries asynchronously
    func processBatch(
        _ entries: [KnowledgeEntry],
        tasks: [AITask],
        progressCallback: @Sendable @escaping (Int, Int) -> Void
    ) async throws -> AIBatchProcessingResult {
        let startTime = Date()
        var results: [String: AIProcessingResult] = [:]
        var successCount = 0
        var failureCount = 0

        for (index, entry) in entries.enumerated() {
            do {
                let result = try await processEntry(entry, tasks: tasks, allEntries: entries)
                results[entry.id] = result

                if result.hasErrors {
                    failureCount += 1
                } else {
                    successCount += 1
                }
            } catch {
                failureCount += 1
                var errorResult = AIProcessingResult()
                errorResult.errors[.autoTagging] = error.localizedDescription
                results[entry.id] = errorResult
            }

            // Report progress
            await progressCallback(index + 1, entries.count)
        }

        let endTime = Date()

        return AIBatchProcessingResult(
            totalEntries: entries.count,
            successfulEntries: successCount,
            failedEntries: failureCount,
            results: results,
            duration: endTime.timeIntervalSince(startTime),
            startedAt: startTime,
            completedAt: endTime
        )
    }

    // MARK: - Task Processing

    private func processTask(
        _ task: AITask,
        for entry: KnowledgeEntry,
        result: inout AIProcessingResult,
        allEntries: [KnowledgeEntry]
    ) async throws {
        let service = await selectService(for: task)
        result.serviceUsed[task] = service

        switch task {
        case .autoTagging:
            let tags = try await generateTags(for: entry, using: service)
            result.tags = tags

        case .summarization:
            let summary = try await generateSummary(for: entry, using: service)
            result.summary = summary

        case .linkFinding:
            let relatedIDs = try await findRelatedEntries(
                for: entry,
                among: allEntries,
                using: service
            )
            result.relatedEntryIDs = relatedIDs

        case .contentEnrichment:
            let enriched = try await enrichContent(for: entry, using: service)
            result.enrichedContent = enriched
        }
    }

    // MARK: - Service Selection

    private func selectService(for task: AITask) async -> AIServiceType {
        // Get service from central configuration
        return await MainActor.run {
            AIConfiguration.shared.getService(for: task)
        }
    }

    // MARK: - AI Operations

    private func generateTags(for entry: KnowledgeEntry, using service: AIServiceType) async throws -> [String] {
        let config = await MainActor.run { AIConfiguration.shared }

        switch service {
        case .openAI:
            return try await config.openAIService.generateTags(for: entry.content, title: entry.title)

        case .appleIntelligence:
            return try await config.appleIntelligenceService.generateTags(for: entry.content, title: entry.title)

        case .claude:
            return try await config.claudeService.generateTags(for: entry.content, title: entry.title)
        }
    }

    private func generateSummary(for entry: KnowledgeEntry, using service: AIServiceType) async throws -> String {
        let config = await MainActor.run { AIConfiguration.shared }

        switch service {
        case .openAI:
            return try await config.openAIService.generateSummary(for: entry.content, title: entry.title)

        case .appleIntelligence:
            return try await config.appleIntelligenceService.generateSummary(for: entry.content, title: entry.title)

        case .claude:
            return try await config.claudeService.generateSummary(for: entry.content, title: entry.title)
        }
    }

    private func findRelatedEntries(
        for entry: KnowledgeEntry,
        among allEntries: [KnowledgeEntry],
        using service: AIServiceType
    ) async throws -> [String] {
        // Filter out the current entry
        let candidates = allEntries
            .filter { $0.id != entry.id }
            .map { (id: $0.id, title: $0.title, content: $0.content) }

        guard !candidates.isEmpty else {
            return []
        }

        let config = await MainActor.run { AIConfiguration.shared }

        switch service {
        case .openAI, .appleIntelligence:
            // Only OpenAI supports similarity search currently
            return try await config.openAIService.findSimilarEntries(
                for: entry.content,
                among: candidates,
                limit: 5
            )

        case .claude:
            // Claude doesn't support this yet
            throw CortexError.aiProcessingFailed(
                task: "Link Finding",
                reason: "Not supported by Claude service"
            )
        }
    }

    private func enrichContent(for entry: KnowledgeEntry, using service: AIServiceType) async throws -> String {
        let config = await MainActor.run { AIConfiguration.shared }

        switch service {
        case .openAI:
            return try await config.openAIService.enrichContent(entry.content, title: entry.title)

        case .appleIntelligence:
            return try await config.appleIntelligenceService.enrichContent(entry.content, title: entry.title)

        case .claude:
            return try await config.claudeService.enrichContent(entry.content, title: entry.title)
        }
    }

    // MARK: - Configuration

    /// Check if any AI service is available
    func isAnyServiceAvailable() async -> Bool {
        return await MainActor.run {
            AIConfiguration.shared.openAIConfigured ||
            AIConfiguration.shared.appleIntelligenceAvailable ||
            AIConfiguration.shared.claudeAvailable
        }
    }
}
