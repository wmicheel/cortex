//
//  KnowledgeListViewModel.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation
import AppKit
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

    /// Reminders service
    private let remindersService = RemindersService()

    /// Calendar service
    private let calendarService = CalendarService()

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

    // MARK: - Reminder Integration

    /// Create a reminder from a knowledge entry
    func createReminder(for entry: KnowledgeEntry, dueDate: Date, priority: Int) async {
        do {
            // Request access if needed
            let hasAccess = await remindersService.hasAccess
            if !hasAccess {
                let granted = await remindersService.requestAccess()
                guard granted else {
                    error = .unknown(underlying: RemindersError.notAuthorized)
                    return
                }
            }

            // Create reminder
            let reminderID = try await remindersService.createReminder(
                title: entry.title,
                notes: entry.content,
                dueDate: dueDate,
                priority: priority
            )

            // Update entry with linked reminder ID
            var updatedEntry = entry
            updatedEntry.linkReminder(reminderID)
            try await knowledgeService.update(updatedEntry)

            // Update in local list
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[index] = updatedEntry
            }
        } catch {
            self.error = handleError(error)
        }
    }

    /// Open a reminder in the Reminders app
    func openReminder(id: String) async {
        guard let url = await remindersService.getReminderURL(id: id) else {
            error = .unknown(underlying: RemindersError.notFound)
            return
        }

        await MainActor.run {
            NSWorkspace.shared.open(url)
        }
    }

    /// Unlink a reminder from an entry
    func unlinkReminder(from entry: KnowledgeEntry) async {
        guard let reminderID = entry.linkedReminderID else { return }

        do {
            // Delete the reminder from Reminders app
            try await remindersService.deleteReminder(id: reminderID)

            // Update entry to unlink
            var updatedEntry = entry
            updatedEntry.unlinkReminder()
            try await knowledgeService.update(updatedEntry)

            // Update in local list
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[index] = updatedEntry
            }
        } catch {
            // If reminder doesn't exist anymore, just unlink it
            if (error as? RemindersError) == .notFound {
                var updatedEntry = entry
                updatedEntry.unlinkReminder()
                try? await knowledgeService.update(updatedEntry)

                if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                    entries[index] = updatedEntry
                }
            } else {
                self.error = handleError(error)
            }
        }
    }

    // MARK: - Calendar Event Integration

    /// Create a calendar event from a knowledge entry
    func createCalendarEvent(for entry: KnowledgeEntry, startDate: Date, endDate: Date, isAllDay: Bool) async {
        do {
            // Request access if needed
            let hasAccess = await calendarService.hasAccess
            if !hasAccess {
                let granted = await calendarService.requestAccess()
                guard granted else {
                    error = .unknown(underlying: CalendarError.notAuthorized)
                    return
                }
            }

            // Create calendar event
            let eventID = try await calendarService.createEvent(
                title: entry.title,
                notes: entry.content,
                startDate: startDate,
                endDate: endDate,
                isAllDay: isAllDay
            )

            // Update entry with linked event ID
            var updatedEntry = entry
            updatedEntry.linkCalendarEvent(eventID)
            try await knowledgeService.update(updatedEntry)

            // Update in local list
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[index] = updatedEntry
            }
        } catch {
            self.error = handleError(error)
        }
    }

    /// Open a calendar event in the Calendar app
    func openCalendarEvent(id: String) async {
        guard let url = await calendarService.getEventURL(id: id) else {
            error = .unknown(underlying: CalendarError.notFound)
            return
        }

        await MainActor.run {
            NSWorkspace.shared.open(url)
        }
    }

    /// Unlink a calendar event from an entry
    func unlinkCalendarEvent(from entry: KnowledgeEntry) async {
        guard let eventID = entry.linkedCalendarEventID else { return }

        do {
            // Delete the event from Calendar app
            try await calendarService.deleteEvent(id: eventID)

            // Update entry to unlink
            var updatedEntry = entry
            updatedEntry.unlinkCalendarEvent()
            try await knowledgeService.update(updatedEntry)

            // Update in local list
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[index] = updatedEntry
            }
        } catch {
            // If event doesn't exist anymore, just unlink it
            if (error as? CalendarError) == .notFound {
                var updatedEntry = entry
                updatedEntry.unlinkCalendarEvent()
                try? await knowledgeService.update(updatedEntry)

                if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                    entries[index] = updatedEntry
                }
            } else {
                self.error = handleError(error)
            }
        }
    }
}
