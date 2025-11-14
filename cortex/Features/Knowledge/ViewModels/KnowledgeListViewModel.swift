//
//  KnowledgeListViewModel.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation
import Observation

/// ViewModel for knowledge list management
@Observable
@MainActor
final class KnowledgeListViewModel {
    // MARK: - Published State

    /// List of knowledge entries
    private(set) var entries: [KnowledgeEntry] = []

    /// Search query
    var searchText: String = "" {
        didSet {
            Task {
                await performSearch()
            }
        }
    }

    /// Selected tag filter
    var selectedTag: String? {
        didSet {
            Task {
                await loadEntries()
            }
        }
    }

    /// Loading state
    private(set) var isLoading = false

    /// Error state
    var error: CortexError?

    /// Available tags
    private(set) var availableTags: [String] = []

    /// Statistics
    private(set) var statistics: KnowledgeStatistics?

    // MARK: - Properties

    /// Knowledge service
    private let knowledgeService: any KnowledgeServiceProtocol

    /// Search task for cancellation
    private var searchTask: Task<Void, Never>?

    // MARK: - Initialization

    init(knowledgeService: (any KnowledgeServiceProtocol)? = nil) {
        // Use Mock service by default for development
        // Switch to real KnowledgeService when CloudKit is configured
        self.knowledgeService = knowledgeService ?? MockKnowledgeService()
    }

    // MARK: - Lifecycle

    /// Load initial data
    func onAppear() async {
        // Gracefully handle CloudKit not being available
        do {
            await loadEntries()
            await loadTags()
            await loadStatistics()
        } catch {
            // Already handled in individual load methods
            print("Error during initial load: \(error)")
        }
    }

    /// Refresh all data
    func refresh() async {
        await loadEntries(forceRefresh: true)
        await loadTags()
        await loadStatistics()
    }

    // MARK: - Data Loading

    /// Load knowledge entries
    private func loadEntries(forceRefresh: Bool = false) async {
        isLoading = true
        error = nil

        do {
            if let tag = selectedTag {
                entries = try await knowledgeService.fetchEntries(withTag: tag)
            } else {
                entries = try await knowledgeService.fetchAll(forceRefresh: forceRefresh)
            }
        } catch {
            self.error = handleError(error)
            // Don't crash - just show empty state with error
            entries = []
        }

        isLoading = false
    }

    /// Load available tags
    private func loadTags() async {
        do {
            availableTags = try await knowledgeService.fetchAllTags()
        } catch {
            // Silently fail for tags - not critical
            print("Failed to load tags: \(error)")
        }
    }

    /// Load statistics
    private func loadStatistics() async {
        do {
            statistics = try await knowledgeService.getStatistics()
        } catch {
            // Silently fail for statistics - not critical
            print("Failed to load statistics: \(error)")
        }
    }

    // MARK: - Search

    /// Perform search
    private func performSearch() async {
        // Cancel previous search
        searchTask?.cancel()

        // Debounce search
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))

            guard !Task.isCancelled else { return }

            isLoading = true
            error = nil

            do {
                entries = try await knowledgeService.search(query: searchText)
            } catch {
                self.error = handleError(error)
            }

            isLoading = false
        }
    }

    // MARK: - CRUD Operations

    /// Create new entry
    func createEntry(title: String, content: String, tags: [String] = [], autoTag: Bool = true) async {
        isLoading = true
        error = nil

        do {
            let newEntry = try await knowledgeService.create(
                title: title,
                content: content,
                tags: tags,
                autoTag: autoTag
            )

            // Add to local list
            entries.insert(newEntry, at: 0)

            // Reload tags if new ones were added
            await loadTags()
        } catch {
            self.error = handleError(error)
        }

        isLoading = false
    }

    /// Suggest tags for given title and content
    func suggestTags(title: String, content: String) async -> [String] {
        return await knowledgeService.suggestTags(title: title, content: content)
    }

    /// Update entry
    func updateEntry(_ entry: KnowledgeEntry) async {
        isLoading = true
        error = nil

        do {
            let updatedEntry = try await knowledgeService.update(entry)

            // Update in local list
            if let index = entries.firstIndex(where: { $0.id == updatedEntry.id }) {
                entries[index] = updatedEntry
            }

            // Reload tags if they changed
            await loadTags()
        } catch {
            self.error = handleError(error)
        }

        isLoading = false
    }

    /// Delete entry
    func deleteEntry(_ entry: KnowledgeEntry) async {
        isLoading = true
        error = nil

        do {
            try await knowledgeService.delete(entry)

            // Remove from local list
            entries.removeAll { $0.id == entry.id }

            // Reload tags and statistics
            await loadTags()
            await loadStatistics()
        } catch {
            self.error = handleError(error)
        }

        isLoading = false
    }

    /// Delete multiple entries
    func deleteEntries(_ entriesToDelete: [KnowledgeEntry]) async {
        isLoading = true
        error = nil

        do {
            try await knowledgeService.deleteAll(entriesToDelete)

            // Remove from local list
            let deletedIds = Set(entriesToDelete.map { $0.id })
            entries.removeAll { deletedIds.contains($0.id) }

            // Reload tags and statistics
            await loadTags()
            await loadStatistics()
        } catch {
            self.error = handleError(error)
        }

        isLoading = false
    }

    // MARK: - Tag Management

    /// Add tag to entry
    func addTag(_ tag: String, to entry: KnowledgeEntry) async {
        do {
            let updatedEntry = try await knowledgeService.addTag(tag, to: entry.id)

            // Update in local list
            if let index = entries.firstIndex(where: { $0.id == updatedEntry.id }) {
                entries[index] = updatedEntry
            }

            // Reload tags
            await loadTags()
        } catch {
            self.error = handleError(error)
        }
    }

    /// Remove tag from entry
    func removeTag(_ tag: String, from entry: KnowledgeEntry) async {
        do {
            let updatedEntry = try await knowledgeService.removeTag(tag, from: entry.id)

            // Update in local list
            if let index = entries.firstIndex(where: { $0.id == updatedEntry.id }) {
                entries[index] = updatedEntry
            }

            // Reload tags
            await loadTags()
        } catch {
            self.error = handleError(error)
        }
    }

    /// Clear tag filter
    func clearTagFilter() {
        selectedTag = nil
    }

    // MARK: - Error Handling

    /// Handle and format error
    private func handleError(_ error: Error) -> CortexError {
        if let cortexError = error as? CortexError {
            return cortexError
        }
        return .unknown(underlying: error)
    }

    /// Clear error
    func clearError() {
        error = nil
    }
}
