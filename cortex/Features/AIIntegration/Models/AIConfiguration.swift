//
//  AIConfiguration.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation
import Observation

/// Central AI configuration and service management
@MainActor
@Observable
final class AIConfiguration {
    // MARK: - Singleton

    static let shared = AIConfiguration()

    // MARK: - Services

    let openAIService = OpenAIService()
    let appleIntelligenceService = AppleIntelligenceService()
    let claudeService = ClaudeWebService()

    // MARK: - Service Status

    var openAIConfigured: Bool = false
    var appleIntelligenceAvailable: Bool = false
    var claudeAvailable: Bool = false

    // MARK: - Service Selection Configuration

    var autoTaggingService: AIServiceType = .openAI
    var summarizationService: AIServiceType = .claude
    var linkFindingService: AIServiceType = .openAI
    var contentEnrichmentService: AIServiceType = .claude

    // MARK: - Feature Toggles

    var enableAutoTagging: Bool = true
    var enableSummarization: Bool = true
    var enableLinkFinding: Bool = true
    var enableContentEnrichment: Bool = false

    // MARK: - Advanced Settings

    var fallbackToOpenAI: Bool = true
    var maxRetries: Int = 2
    var timeoutSeconds: Double = 30

    // MARK: - Initialization

    private init() {
        // Load configuration from UserDefaults
        loadConfiguration()

        // Initialize Claude WebView
        claudeService.initialize()

        // Check service status
        Task {
            await updateServiceStatus()
        }
    }

    // MARK: - Configuration Management

    func loadConfiguration() {
        let defaults = UserDefaults.standard

        // Service selection
        if let autoTaggingRaw = defaults.string(forKey: "ai.autoTagging.service"),
           let service = AIServiceType(rawValue: autoTaggingRaw) {
            autoTaggingService = service
        }

        if let summarizationRaw = defaults.string(forKey: "ai.summarization.service"),
           let service = AIServiceType(rawValue: summarizationRaw) {
            summarizationService = service
        }

        if let linkFindingRaw = defaults.string(forKey: "ai.linkFinding.service"),
           let service = AIServiceType(rawValue: linkFindingRaw) {
            linkFindingService = service
        }

        if let contentEnrichmentRaw = defaults.string(forKey: "ai.contentEnrichment.service"),
           let service = AIServiceType(rawValue: contentEnrichmentRaw) {
            contentEnrichmentService = service
        }

        // Feature toggles
        enableAutoTagging = defaults.bool(forKey: "ai.feature.autoTagging")
        enableSummarization = defaults.bool(forKey: "ai.feature.summarization")
        enableLinkFinding = defaults.bool(forKey: "ai.feature.linkFinding")
        enableContentEnrichment = defaults.bool(forKey: "ai.feature.contentEnrichment")

        // Advanced settings
        fallbackToOpenAI = defaults.bool(forKey: "ai.fallbackToOpenAI")
        maxRetries = defaults.integer(forKey: "ai.maxRetries")
        if maxRetries == 0 { maxRetries = 2 } // Default
        timeoutSeconds = defaults.double(forKey: "ai.timeoutSeconds")
        if timeoutSeconds == 0 { timeoutSeconds = 30 } // Default

        print("✅ AI Configuration loaded")
    }

    func saveConfiguration() {
        let defaults = UserDefaults.standard

        // Service selection
        defaults.set(autoTaggingService.rawValue, forKey: "ai.autoTagging.service")
        defaults.set(summarizationService.rawValue, forKey: "ai.summarization.service")
        defaults.set(linkFindingService.rawValue, forKey: "ai.linkFinding.service")
        defaults.set(contentEnrichmentService.rawValue, forKey: "ai.contentEnrichment.service")

        // Feature toggles
        defaults.set(enableAutoTagging, forKey: "ai.feature.autoTagging")
        defaults.set(enableSummarization, forKey: "ai.feature.summarization")
        defaults.set(enableLinkFinding, forKey: "ai.feature.linkFinding")
        defaults.set(enableContentEnrichment, forKey: "ai.feature.contentEnrichment")

        // Advanced settings
        defaults.set(fallbackToOpenAI, forKey: "ai.fallbackToOpenAI")
        defaults.set(maxRetries, forKey: "ai.maxRetries")
        defaults.set(timeoutSeconds, forKey: "ai.timeoutSeconds")

        print("✅ AI Configuration saved")
    }

    // MARK: - Service Status

    func updateServiceStatus() async {
        // Check OpenAI
        openAIConfigured = await openAIService.isConfigured()

        // Check Apple Intelligence
        appleIntelligenceAvailable = await appleIntelligenceService.isAvailable()

        // Check Claude - use the current published value from service
        claudeAvailable = claudeService.isAvailable

        // Also try to refresh if needed
        if !claudeAvailable {
            await refreshClaudeStatus()
        }
    }

    func refreshClaudeStatus() async {
        do {
            claudeAvailable = try await claudeService.checkLoginStatus()
        } catch {
            print("❌ Error checking Claude status: \(error)")
            claudeAvailable = false
        }
    }

    // MARK: - Service Selection

    func getService(for task: AITask) -> AIServiceType {
        switch task {
        case .autoTagging:
            return autoTaggingService
        case .summarization:
            return summarizationService
        case .linkFinding:
            return linkFindingService
        case .contentEnrichment:
            return contentEnrichmentService
        }
    }

    func canExecuteTask(_ task: AITask) -> Bool {
        let preferredService = getService(for: task)

        switch preferredService {
        case .openAI:
            return openAIConfigured
        case .claude:
            return claudeAvailable || (fallbackToOpenAI && openAIConfigured)
        case .appleIntelligence:
            return appleIntelligenceAvailable || (fallbackToOpenAI && openAIConfigured)
        }
    }

    // MARK: - Summary

    var configurationSummary: String {
        var summary = "AI Services:\n"
        summary += "- OpenAI: \(openAIConfigured ? "✅" : "❌")\n"
        summary += "- Apple Intelligence: \(appleIntelligenceAvailable ? "✅" : "❌")\n"
        summary += "- Claude: \(claudeAvailable ? "✅" : "❌")\n\n"

        summary += "Task Assignment:\n"
        summary += "- Auto-Tagging: \(autoTaggingService.rawValue)\n"
        summary += "- Summarization: \(summarizationService.rawValue)\n"
        summary += "- Link Finding: \(linkFindingService.rawValue)\n"
        summary += "- Content Enrichment: \(contentEnrichmentService.rawValue)\n"

        return summary
    }
}
