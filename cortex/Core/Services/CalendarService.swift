//
//  CalendarService.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation
import EventKit

/// Service for managing calendar integration
actor CalendarService {
    // MARK: - Properties

    private let eventStore = EKEventStore()

    // MARK: - Authorization

    /// Request access to calendars
    func requestAccess() async -> Bool {
        do {
            if #available(macOS 14.0, *) {
                return try await eventStore.requestFullAccessToEvents()
            } else {
                return await withCheckedContinuation { continuation in
                    eventStore.requestAccess(to: .event) { granted, _ in
                        continuation.resume(returning: granted)
                    }
                }
            }
        } catch {
            return false
        }
    }

    /// Check if we have access to calendars
    var hasAccess: Bool {
        if #available(macOS 14.0, *) {
            return EKEventStore.authorizationStatus(for: .event) == .fullAccess
        } else {
            return EKEventStore.authorizationStatus(for: .event) == .authorized
        }
    }

    // MARK: - Create Event

    /// Create a calendar event from a knowledge entry
    /// - Parameters:
    ///   - title: Event title
    ///   - notes: Event notes
    ///   - startDate: Event start date
    ///   - endDate: Event end date
    ///   - isAllDay: Whether this is an all-day event
    /// - Returns: Created event identifier
    func createEvent(
        title: String,
        notes: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false
    ) async throws -> String {
        guard hasAccess else {
            throw CalendarError.notAuthorized
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.notes = notes
        event.startDate = startDate
        event.endDate = endDate
        event.isAllDay = isAllDay
        event.calendar = eventStore.defaultCalendarForNewEvents

        // Save event
        try eventStore.save(event, span: .thisEvent, commit: true)

        // Return the calendar item identifier
        return event.calendarItemIdentifier
    }

    // MARK: - Fetch Events

    /// Fetch a specific event by ID
    /// - Parameter id: Event identifier
    /// - Returns: Event if found
    func fetchEvent(id: String) async throws -> EKEvent? {
        guard hasAccess else {
            throw CalendarError.notAuthorized
        }

        return eventStore.calendarItem(withIdentifier: id) as? EKEvent
    }

    /// Fetch events in a date range
    /// - Parameters:
    ///   - startDate: Range start date
    ///   - endDate: Range end date
    /// - Returns: Array of events
    func fetchEvents(from startDate: Date, to endDate: Date) async throws -> [EKEvent] {
        guard hasAccess else {
            throw CalendarError.notAuthorized
        }

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )

        return eventStore.events(matching: predicate)
    }

    // MARK: - Update Event

    /// Update an event's details
    /// - Parameters:
    ///   - id: Event identifier
    ///   - title: New title
    ///   - notes: New notes
    ///   - startDate: New start date
    ///   - endDate: New end date
    func updateEvent(
        id: String,
        title: String? = nil,
        notes: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) async throws {
        guard hasAccess else {
            throw CalendarError.notAuthorized
        }

        guard let event = eventStore.calendarItem(withIdentifier: id) as? EKEvent else {
            throw CalendarError.notFound
        }

        if let title = title {
            event.title = title
        }
        if let notes = notes {
            event.notes = notes
        }
        if let startDate = startDate {
            event.startDate = startDate
        }
        if let endDate = endDate {
            event.endDate = endDate
        }

        try eventStore.save(event, span: .thisEvent, commit: true)
    }

    // MARK: - Delete Event

    /// Delete a calendar event
    /// - Parameter id: Event identifier
    func deleteEvent(id: String) async throws {
        guard hasAccess else {
            throw CalendarError.notAuthorized
        }

        guard let event = eventStore.calendarItem(withIdentifier: id) as? EKEvent else {
            throw CalendarError.notFound
        }

        try eventStore.remove(event, span: .thisEvent, commit: true)
    }

    // MARK: - Open in Calendar App

    /// Get URL to open event in Calendar app
    /// - Parameter id: Event identifier
    /// - Returns: URL to open event
    func getEventURL(id: String) -> URL? {
        return URL(string: "x-apple-calevent://\(id)")
    }
}

// MARK: - Errors

enum CalendarError: LocalizedError {
    case notAuthorized
    case notFound
    case creationFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Zugriff auf Kalender nicht autorisiert."
        case .notFound:
            return "Kalenderereignis wurde nicht gefunden."
        case .creationFailed:
            return "Kalenderereignis konnte nicht erstellt werden."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notAuthorized:
            return "Bitte erlauben Sie den Zugriff in Systemeinstellungen → Datenschutz & Sicherheit → Kalender"
        case .notFound:
            return "Das Ereignis wurde möglicherweise gelöscht."
        case .creationFailed:
            return "Versuchen Sie es erneut oder überprüfen Sie Ihre Kalender-Einstellungen."
        }
    }
}
