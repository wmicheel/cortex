//
//  LocalizationManager.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation
import Observation

/// Manages app localization based on system language settings
@MainActor
@Observable
final class LocalizationManager {
    // MARK: - Singleton

    static let shared = LocalizationManager()

    // MARK: - Properties

    private(set) var currentLanguage: Language

    // MARK: - Language Enum

    enum Language: String, CaseIterable {
        case english = "en"
        case german = "de"

        var displayName: String {
            switch self {
            case .english: return "English"
            case .german: return "Deutsch"
            }
        }

        var locale: Locale {
            Locale(identifier: rawValue)
        }
    }

    // MARK: - Initialization

    private init() {
        // Detect system language
        let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"

        if systemLanguage.starts(with: "de") {
            self.currentLanguage = .german
        } else {
            self.currentLanguage = .english
        }

        print("🌍 LocalizationManager initialized with language: \(currentLanguage.displayName)")
    }

    // MARK: - Language Management

    /// Change the app language (optional - user override)
    func setLanguage(_ language: Language) {
        currentLanguage = language
        print("🌍 Language changed to: \(language.displayName)")
    }

    /// Get localized string
    func localized(_ key: String, comment: String = "") -> String {
        NSLocalizedString(key, comment: comment)
    }
}

// MARK: - String Extension for Localization

extension String {
    /// Localized version of the string
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    /// Localized with arguments
    func localized(_ arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}

// MARK: - Localization Keys

/// Centralized localization keys for type-safe access
enum L10n {
    // MARK: - Common
    enum Common {
        static let ok = "common.ok"
        static let cancel = "common.cancel"
        static let save = "common.save"
        static let delete = "common.delete"
        static let edit = "common.edit"
        static let add = "common.add"
        static let search = "common.search"
        static let close = "common.close"
        static let done = "common.done"
        static let retry = "common.retry"
        static let error = "common.error"
        static let loading = "common.loading"
        static let success = "common.success"
    }

    // MARK: - Dashboard
    enum Dashboard {
        static let title = "dashboard.title"
        static let welcomeMessage = "dashboard.welcome_message"
        static let subtitle = "dashboard.subtitle"
        static let quickActions = "dashboard.quick_actions"
        static let recentActivity = "dashboard.recent_activity"
        static let analytics = "dashboard.analytics"
        static let recommendations = "dashboard.recommendations"
        static let totalEntries = "dashboard.total_entries"
        static let totalTags = "dashboard.total_tags"
        static let aiEnhanced = "dashboard.ai_enhanced"
    }

    // MARK: - Knowledge
    enum Knowledge {
        static let title = "knowledge.title"
        static let newEntry = "knowledge.new_entry"
        static let searchPlaceholder = "knowledge.search_placeholder"
        static let noEntries = "knowledge.no_entries"
        static let noResults = "knowledge.no_results"
        static let addFirstEntry = "knowledge.add_first_entry"
        static let tags = "knowledge.tags"
        static let allTags = "knowledge.all_tags"
        static let content = "knowledge.content"
        static let createdAt = "knowledge.created_at"
        static let modifiedAt = "knowledge.modified_at"
    }

    // MARK: - Command Palette
    enum CommandPalette {
        static let placeholder = "command_palette.placeholder"
        static let noCommands = "command_palette.no_commands"
        static let tryDifferent = "command_palette.try_different"
        static let loadingCommands = "command_palette.loading_commands"
        static let escToClose = "command_palette.esc_to_close"

        // Commands
        static let newEntry = "command_palette.command.new_entry"
        static let newEntryDesc = "command_palette.command.new_entry_desc"
        static let aiProcess = "command_palette.command.ai_process"
        static let aiProcessDesc = "command_palette.command.ai_process_desc"
        static let search = "command_palette.command.search"
        static let searchDesc = "command_palette.command.search_desc"
        static let settings = "command_palette.command.settings"
        static let settingsDesc = "command_palette.command.settings_desc"
        static let dashboard = "command_palette.command.dashboard"
        static let dashboardDesc = "command_palette.command.dashboard_desc"
        static let export = "command_palette.command.export"
        static let exportDesc = "command_palette.command.export_desc"
    }

    // MARK: - AI Processing
    enum AI {
        static let processing = "ai.processing"
        static let autoTagging = "ai.auto_tagging"
        static let summarization = "ai.summarization"
        static let linkFinding = "ai.link_finding"
        static let contentEnrichment = "ai.content_enrichment"
        static let selectTasks = "ai.select_tasks"
        static let startProcessing = "ai.start_processing"
        static let processingComplete = "ai.processing_complete"
        static let processedEntries = "ai.processed_entries"
    }

    // MARK: - Settings
    enum Settings {
        static let title = "settings.title"
        static let general = "settings.general"
        static let appearance = "settings.appearance"
        static let aiServices = "settings.ai_services"
        static let language = "settings.language"
        static let about = "settings.about"
    }

    // MARK: - Errors
    enum Errors {
        static let generic = "errors.generic"
        static let networkError = "errors.network"
        static let saveError = "errors.save"
        static let loadError = "errors.load"
        static let deleteError = "errors.delete"
    }
}
