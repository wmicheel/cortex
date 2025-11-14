//
//  AIServiceType.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation

/// Represents different AI service providers
enum AIServiceType: String, Codable, CaseIterable, Identifiable {
    case openAI = "openai"
    case claude = "claude"
    case appleIntelligence = "apple_intelligence"

    var id: String { rawValue }

    /// Human-readable name
    var displayName: String {
        switch self {
        case .openAI:
            return "OpenAI"
        case .claude:
            return "Claude"
        case .appleIntelligence:
            return "Apple Intelligence"
        }
    }

    /// Description of the service
    var description: String {
        switch self {
        case .openAI:
            return "OpenAI GPT-4 via API"
        case .claude:
            return "Anthropic Claude via Web-Login"
        case .appleIntelligence:
            return "Apple Intelligence (System-Integration)"
        }
    }

    /// Whether API key is required
    var requiresAPIKey: Bool {
        switch self {
        case .openAI:
            return true
        case .claude, .appleIntelligence:
            return false
        }
    }

    /// Keychain key for storing credentials
    var keychainKey: String? {
        switch self {
        case .openAI:
            return "openAIAPIKey"
        case .claude:
            return "claudeSessionToken"
        case .appleIntelligence:
            return nil  // Uses system integration
        }
    }
}
