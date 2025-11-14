//
//  AITask.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation

/// Represents different types of AI processing tasks
enum AITask: String, Codable, CaseIterable, Identifiable {
    case autoTagging = "auto_tagging"
    case summarization = "summarization"
    case linkFinding = "link_finding"
    case contentEnrichment = "content_enrichment"

    var id: String { rawValue }

    /// Human-readable name in German
    var displayName: String {
        switch self {
        case .autoTagging:
            return "Auto-Tagging"
        case .summarization:
            return "Zusammenfassung"
        case .linkFinding:
            return "Verknüpfungen finden"
        case .contentEnrichment:
            return "Content-Erweiterung"
        }
    }

    /// Description of what this task does
    var description: String {
        switch self {
        case .autoTagging:
            return "Generiert automatisch relevante Tags basierend auf dem Inhalt"
        case .summarization:
            return "Erstellt eine prägnante Zusammenfassung des Eintrags"
        case .linkFinding:
            return "Findet thematisch ähnliche Knowledge Entries"
        case .contentEnrichment:
            return "Reichert den Content mit zusätzlichen Informationen an"
        }
    }

    /// Recommended AI service for this task
    var preferredService: AIServiceType {
        switch self {
        case .autoTagging:
            return .openAI  // Fast and cheap
        case .summarization:
            return .claude  // Better quality for summaries
        case .linkFinding:
            return .openAI  // Embedding-based similarity
        case .contentEnrichment:
            return .claude  // Deeper analysis
        }
    }

    /// System icon for this task
    var iconName: String {
        switch self {
        case .autoTagging:
            return "tag.fill"
        case .summarization:
            return "doc.text.fill"
        case .linkFinding:
            return "link"
        case .contentEnrichment:
            return "sparkles"
        }
    }
}
