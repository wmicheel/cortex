//
//  RemindersService.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation
import EventKit

/// Service for managing reminders integration
actor RemindersService {
    // MARK: - Properties

    private let eventStore = EKEventStore()

    // MARK: - Authorization

    /// Request access to reminders
    func requestAccess() async -> Bool {
        do {
            if #available(macOS 14.0, *) {
                return try await eventStore.requestFullAccessToReminders()
            } else {
                return await withCheckedContinuation { continuation in
                    eventStore.requestAccess(to: .reminder) { granted, _ in
                        continuation.resume(returning: granted)
                    }
                }
            }
        } catch {
            return false
        }
    }

    /// Check if we have access to reminders
    var hasAccess: Bool {
        if #available(macOS 14.0, *) {
            return EKEventStore.authorizationStatus(for: .reminder) == .fullAccess
        } else {
            return EKEventStore.authorizationStatus(for: .reminder) == .authorized
        }
    }

    // MARK: - Create Reminder

    /// Create a reminder from a knowledge entry
    /// - Parameters:
    ///   - title: Reminder title
    ///   - notes: Reminder notes
    ///   - dueDate: Optional due date
    ///   - priority: Reminder priority (0-9, 0 = none)
    /// - Returns: Created reminder identifier
    func createReminder(
        title: String,
        notes: String,
        dueDate: Date? = nil,
        priority: Int = 0
    ) async throws -> String {
        guard hasAccess else {
            throw RemindersError.notAuthorized
        }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.notes = notes
        reminder.calendar = eventStore.defaultCalendarForNewReminders()

        // Set due date if provided
        if let dueDate = dueDate {
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: dueDate
            )
            reminder.dueDateComponents = components
        }

        // Set priority (0 = none, 1-4 = high, 5 = medium, 6-9 = low)
        reminder.priority = priority

        // Save reminder
        try eventStore.save(reminder, commit: true)

        // Return the calendar item identifier
        return reminder.calendarItemIdentifier
    }

    // MARK: - Fetch Reminders

    /// Fetch a specific reminder by ID
    /// - Parameter id: Reminder identifier
    /// - Returns: Reminder if found
    func fetchReminder(id: String) async throws -> EKReminder? {
        guard hasAccess else {
            throw RemindersError.notAuthorized
        }

        return eventStore.calendarItem(withIdentifier: id) as? EKReminder
    }

    /// Fetch all incomplete reminders
    func fetchIncompleteReminders() async throws -> [EKReminder] {
        guard hasAccess else {
            throw RemindersError.notAuthorized
        }

        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: nil
        )

        return try await withCheckedThrowingContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                if let reminders = reminders {
                    continuation.resume(returning: reminders)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    // MARK: - Update Reminder

    /// Update reminder completion status
    /// - Parameters:
    ///   - id: Reminder identifier
    ///   - isCompleted: Completion status
    func updateCompletion(id: String, isCompleted: Bool) async throws {
        guard hasAccess else {
            throw RemindersError.notAuthorized
        }

        guard let reminder = eventStore.calendarItem(withIdentifier: id) as? EKReminder else {
            throw RemindersError.notFound
        }

        reminder.isCompleted = isCompleted

        try eventStore.save(reminder, commit: true)
    }

    // MARK: - Delete Reminder

    /// Delete a reminder
    /// - Parameter id: Reminder identifier
    func deleteReminder(id: String) async throws {
        guard hasAccess else {
            throw RemindersError.notAuthorized
        }

        guard let reminder = eventStore.calendarItem(withIdentifier: id) as? EKReminder else {
            throw RemindersError.notFound
        }

        try eventStore.remove(reminder, commit: true)
    }

    // MARK: - Open in Reminders App

    /// Get URL to open reminder in Reminders app
    /// - Parameter id: Reminder identifier
    /// - Returns: URL to open reminder
    func getReminderURL(id: String) -> URL? {
        return URL(string: "x-apple-reminderkit://REMCDReminder/\(id)")
    }
}

// MARK: - Errors

enum RemindersError: LocalizedError {
    case notAuthorized
    case notFound
    case creationFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Zugriff auf Erinnerungen nicht autorisiert."
        case .notFound:
            return "Erinnerung wurde nicht gefunden."
        case .creationFailed:
            return "Erinnerung konnte nicht erstellt werden."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notAuthorized:
            return "Bitte erlauben Sie den Zugriff in Systemeinstellungen → Datenschutz & Sicherheit → Erinnerungen"
        case .notFound:
            return "Die Erinnerung wurde möglicherweise gelöscht."
        case .creationFailed:
            return "Versuchen Sie es erneut oder überprüfen Sie Ihre Erinnerungen-Einstellungen."
        }
    }
}
