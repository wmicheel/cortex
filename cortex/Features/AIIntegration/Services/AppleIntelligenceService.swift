//
//  AppleIntelligenceService.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation

/// Service for Apple Intelligence integration (ChatGPT via Siri/System)
/// Falls back to OpenAI API if system integration is unavailable
actor AppleIntelligenceService {
    // MARK: - Properties

    private let openAIService: OpenAIService
    private var isSystemIntegrationAvailable: Bool = false

    // MARK: - Initialization

    init(openAIService: OpenAIService = OpenAIService()) {
        self.openAIService = openAIService
        Task {
            await checkSystemIntegration()
        }
    }

    // MARK: - System Integration Check

    /// Check if Apple Intelligence/ChatGPT system integration is available
    private func checkSystemIntegration() async {
        // NOTE: This is a placeholder for macOS 26+ system integration
        // Apple Intelligence/ChatGPT integration APIs may not be available yet
        // For now, we'll always fall back to OpenAI API

        // In the future, this might check for:
        // - Writing Tools API availability
        // - Siri Intelligence framework
        // - System-level ChatGPT integration

        isSystemIntegrationAvailable = false
    }

    /// Check if service is available (either system or API)
    func isAvailable() async -> Bool {
        if isSystemIntegrationAvailable {
            return true
        }
        return await openAIService.isConfigured()
    }

    // MARK: - AI Tasks (Delegating to OpenAI)

    /// Generate tags - delegates to OpenAI
    func generateTags(for content: String, title: String? = nil) async throws -> [String] {
        // Try system integration first (currently not available)
        if isSystemIntegrationAvailable {
            return try await generateTagsViaSystem(content: content, title: title)
        }

        // Fallback to OpenAI API
        return try await openAIService.generateTags(for: content, title: title)
    }

    /// Generate summary - delegates to OpenAI
    func generateSummary(for content: String, title: String? = nil) async throws -> String {
        if isSystemIntegrationAvailable {
            return try await generateSummaryViaSystem(content: content, title: title)
        }

        return try await openAIService.generateSummary(for: content, title: title)
    }

    /// Find similar entries - delegates to OpenAI
    func findSimilarEntries(
        for content: String,
        among candidates: [(id: String, title: String, content: String)],
        limit: Int = 5
    ) async throws -> [String] {
        // System integration doesn't support this task, always use OpenAI
        return try await openAIService.findSimilarEntries(for: content, among: candidates, limit: limit)
    }

    /// Enrich content - delegates to OpenAI
    func enrichContent(_ content: String, title: String? = nil) async throws -> String {
        if isSystemIntegrationAvailable {
            return try await enrichContentViaSystem(content: content, title: title)
        }

        return try await openAIService.enrichContent(content, title: title)
    }

    // MARK: - System Integration (Placeholder)

    private func generateTagsViaSystem(content: String, title: String?) async throws -> [String] {
        // Placeholder for future Apple Intelligence integration
        // This would use system-level AI APIs when available
        throw CortexError.aiProcessingFailed(
            task: "Tag Generation",
            reason: "Apple Intelligence integration not yet available"
        )
    }

    private func generateSummaryViaSystem(content: String, title: String?) async throws -> String {
        // Placeholder for future Apple Intelligence integration
        throw CortexError.aiProcessingFailed(
            task: "Summary Generation",
            reason: "Apple Intelligence integration not yet available"
        )
    }

    private func enrichContentViaSystem(content: String, title: String?) async throws -> String {
        // Placeholder for future Apple Intelligence integration
        throw CortexError.aiProcessingFailed(
            task: "Content Enrichment",
            reason: "Apple Intelligence integration not yet available"
        )
    }

    // MARK: - Configuration

    /// Load API key (for fallback OpenAI service)
    func loadAPIKey() async throws {
        try await openAIService.loadAPIKey()
    }

    /// Save API key (for fallback OpenAI service)
    func saveAPIKey(_ key: String) async throws {
        try await openAIService.saveAPIKey(key)
    }
}
