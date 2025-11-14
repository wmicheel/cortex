//
//  CommandPaletteViewModel.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation
import SwiftUI
import Observation

/// ViewModel for Command Palette with fuzzy search and quick actions
@MainActor
@Observable
final class CommandPaletteViewModel {
    // MARK: - Properties

    private let knowledgeService: any KnowledgeServiceProtocol

    // State
    var searchQuery: String = "" {
        didSet {
            updateFilteredCommands()
        }
    }

    private(set) var allCommands: [Command] = []
    private(set) var filteredCommands: [Command] = []
    private(set) var recentEntries: [KnowledgeEntry] = []

    var selectedIndex: Int = 0
    var isLoading = false

    // MARK: - Initialization

    init(knowledgeService: (any KnowledgeServiceProtocol)? = nil) {
        if let service = knowledgeService {
            self.knowledgeService = service
        } else {
            do {
                self.knowledgeService = try SwiftDataKnowledgeService()
                print("✅ CommandPaletteViewModel using SwiftDataKnowledgeService")
            } catch {
                print("⚠️ SwiftData unavailable for CommandPaletteViewModel, using MockKnowledgeService: \(error)")
                self.knowledgeService = MockKnowledgeService()
            }
        }
    }

    // MARK: - Lifecycle

    func onAppear() async {
        await loadCommands()
    }

    func refresh() async {
        await loadCommands()
    }

    // MARK: - Load Commands

    private func loadCommands() async {
        isLoading = true

        var commands: [Command] = []

        // Quick Actions
        commands.append(contentsOf: [
            Command(
                id: "new-entry",
                title: L10n.CommandPalette.newEntry.localized,
                description: L10n.CommandPalette.newEntryDesc.localized,
                icon: "plus.circle.fill",
                type: .action,
                keywords: ["new", "create", "add", "entry", "neu", "erstellen"],
                color: DesignSystem.Colors.primaryBlue
            ),
            Command(
                id: "ai-process",
                title: L10n.CommandPalette.aiProcess.localized,
                description: L10n.CommandPalette.aiProcessDesc.localized,
                icon: "sparkles",
                type: .action,
                keywords: ["ai", "process", "batch", "auto-tag", "summarize", "ki", "verarbeitung"],
                color: DesignSystem.Colors.primaryPurple
            ),
            Command(
                id: "search",
                title: L10n.Knowledge.title.localized,
                description: L10n.Knowledge.searchPlaceholder.localized,
                icon: "magnifyingglass",
                type: .action,
                keywords: ["search", "find", "query", "suchen", "finden"],
                color: DesignSystem.Colors.success
            ),
            Command(
                id: "settings",
                title: L10n.CommandPalette.settings.localized,
                description: L10n.CommandPalette.settingsDesc.localized,
                icon: "gearshape.fill",
                type: .action,
                keywords: ["settings", "preferences", "config", "configure", "einstellungen"],
                color: DesignSystem.Colors.textSecondary
            ),
            Command(
                id: "dashboard",
                title: L10n.Dashboard.title.localized,
                description: "View your knowledge analytics and insights",
                icon: "square.grid.2x2.fill",
                type: .navigation,
                keywords: ["dashboard", "home", "overview", "analytics"],
                color: DesignSystem.Colors.info
            ),
            Command(
                id: "export",
                title: "Export Knowledge Base",
                description: "Export your entries to Markdown or JSON",
                icon: "square.and.arrow.up.fill",
                type: .action,
                keywords: ["export", "download", "backup", "save", "exportieren"],
                color: DesignSystem.Colors.warning
            )
        ])

        // Load recent entries
        do {
            let entries = try await knowledgeService.fetchAll(forceRefresh: false)
            recentEntries = Array(entries.prefix(10))

            // Add recent entries as commands
            for entry in recentEntries {
                commands.append(Command(
                    id: "entry-\(entry.id)",
                    title: entry.title,
                    description: String(entry.content.prefix(100)),
                    icon: entry.isBlockBased ? "square.grid.3x3" : "doc.text",
                    type: .entry(entry),
                    keywords: [entry.title.lowercased()] + entry.tags.map { $0.lowercased() },
                    color: DesignSystem.Colors.primaryBlue
                ))
            }

        } catch {
            print("❌ Failed to load entries for command palette: \(error)")
        }

        allCommands = commands
        filteredCommands = commands
        isLoading = false
    }

    // MARK: - Filtering

    private func updateFilteredCommands() {
        if searchQuery.isEmpty {
            filteredCommands = allCommands
            selectedIndex = 0
            return
        }

        let query = searchQuery.lowercased()

        // Fuzzy matching with scoring
        let matches = allCommands.compactMap { command -> (command: Command, score: Int)? in
            let titleScore = fuzzyMatch(query: query, text: command.title.lowercased())
            let descriptionScore = fuzzyMatch(query: query, text: command.description.lowercased())
            let keywordScore = command.keywords.reduce(0) { max($0, fuzzyMatch(query: query, text: $1)) }

            let totalScore = titleScore * 10 + descriptionScore * 3 + keywordScore * 5

            return totalScore > 0 ? (command, totalScore) : nil
        }

        filteredCommands = matches
            .sorted { $0.score > $1.score }
            .map { $0.command }

        selectedIndex = 0
    }

    // MARK: - Fuzzy Matching

    private func fuzzyMatch(query: String, text: String) -> Int {
        // Exact match
        if text.contains(query) {
            return 100
        }

        // Prefix match
        if text.hasPrefix(query) {
            return 80
        }

        // Word boundary match
        let words = text.split(separator: " ")
        for word in words {
            if word.starts(with: query) {
                return 60
            }
        }

        // Character-by-character fuzzy match
        var queryIndex = query.startIndex
        var textIndex = text.startIndex
        var matchCount = 0

        while queryIndex < query.endIndex && textIndex < text.endIndex {
            if query[queryIndex] == text[textIndex] {
                matchCount += 1
                queryIndex = query.index(after: queryIndex)
            }
            textIndex = text.index(after: textIndex)
        }

        if matchCount == query.count {
            return 40
        }

        return 0
    }

    // MARK: - Navigation

    func selectNext() {
        if !filteredCommands.isEmpty {
            selectedIndex = (selectedIndex + 1) % filteredCommands.count
        }
    }

    func selectPrevious() {
        if !filteredCommands.isEmpty {
            selectedIndex = (selectedIndex - 1 + filteredCommands.count) % filteredCommands.count
        }
    }

    func getSelectedCommand() -> Command? {
        guard selectedIndex < filteredCommands.count else { return nil }
        return filteredCommands[selectedIndex]
    }

    // MARK: - Reset

    func reset() {
        searchQuery = ""
        selectedIndex = 0
        updateFilteredCommands()
    }
}

// MARK: - Command Model

struct Command: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let type: CommandType
    let keywords: [String]
    let color: Color

    enum CommandType: Hashable {
        case action
        case navigation
        case entry(KnowledgeEntry)

        // Hashable conformance
        func hash(into hasher: inout Hasher) {
            switch self {
            case .action:
                hasher.combine("action")
            case .navigation:
                hasher.combine("navigation")
            case .entry(let entry):
                hasher.combine("entry")
                hasher.combine(entry.id)
            }
        }

        static func == (lhs: CommandType, rhs: CommandType) -> Bool {
            switch (lhs, rhs) {
            case (.action, .action), (.navigation, .navigation):
                return true
            case (.entry(let lEntry), .entry(let rEntry)):
                return lEntry.id == rEntry.id
            default:
                return false
            }
        }
    }
}
