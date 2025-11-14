//
//  NotesService.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation
import AppKit

/// Service for integrating with Apple Notes
@MainActor
final class NotesService {
    // MARK: - Singleton

    static let shared = NotesService()

    // MARK: - Initialization

    private init() {}

    // MARK: - Note Model

    struct Note: Identifiable, Equatable {
        let id: String
        let title: String
        let body: String
        let folder: String
        let createdDate: Date
        let modifiedDate: Date

        static func == (lhs: Note, rhs: Note) -> Bool {
            lhs.id == rhs.id
        }
    }

    // MARK: - Create Note

    /// Create a new note in Apple Notes
    func createNote(title: String, body: String, folder: String = "Notes") async throws -> Note {
        let escapedTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedBody = body.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedFolder = folder.replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        tell application "Notes"
            tell folder "\(escapedFolder)"
                set newNote to make new note with properties {name:"\(escapedTitle)", body:"\(escapedBody)"}
                return id of newNote
            end tell
        end tell
        """

        let noteId = try await executeAppleScript(script)

        print("✅ Created Apple Note: \(title) (ID: \(noteId))")

        return Note(
            id: noteId,
            title: title,
            body: body,
            folder: folder,
            createdDate: Date(),
            modifiedDate: Date()
        )
    }

    // MARK: - Get Note

    /// Get a note by ID
    func getNote(id: String) async throws -> Note {
        let escapedId = id.replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        tell application "Notes"
            set targetNote to note id "\(escapedId)"
            set noteTitle to name of targetNote
            set noteBody to body of targetNote
            set noteFolder to name of container of targetNote
            set noteCreated to creation date of targetNote
            set noteModified to modification date of targetNote

            return {noteTitle, noteBody, noteFolder, noteCreated as string, noteModified as string}
        end tell
        """

        let result = try await executeAppleScript(script)
        let components = result.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }

        guard components.count >= 3 else {
            throw CortexError.invalidData
        }

        let title = components[0]
        let body = components[1]
        let folder = components[2]

        // Parse dates (simplified - may need better parsing)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm:ss a"
        let createdDate = components.count > 3 ? dateFormatter.date(from: components[3]) ?? Date() : Date()
        let modifiedDate = components.count > 4 ? dateFormatter.date(from: components[4]) ?? Date() : Date()

        return Note(
            id: id,
            title: title,
            body: body,
            folder: folder,
            createdDate: createdDate,
            modifiedDate: modifiedDate
        )
    }

    // MARK: - Update Note

    /// Update an existing note
    func updateNote(id: String, title: String? = nil, body: String? = nil) async throws -> Note {
        let escapedId = id.replacingOccurrences(of: "\"", with: "\\\"")

        var updateCommands: [String] = []

        if let title = title {
            let escapedTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
            updateCommands.append("set name of targetNote to \"\(escapedTitle)\"")
        }

        if let body = body {
            let escapedBody = body.replacingOccurrences(of: "\"", with: "\\\"")
            updateCommands.append("set body of targetNote to \"\(escapedBody)\"")
        }

        let script = """
        tell application "Notes"
            set targetNote to note id "\(escapedId)"
            \(updateCommands.joined(separator: "\n            "))
        end tell
        """

        _ = try await executeAppleScript(script)

        print("✅ Updated Apple Note: \(id)")

        // Return updated note
        return try await getNote(id: id)
    }

    // MARK: - Delete Note

    /// Delete a note by ID
    func deleteNote(id: String) async throws {
        let escapedId = id.replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        tell application "Notes"
            delete note id "\(escapedId)"
        end tell
        """

        _ = try await executeAppleScript(script)

        print("✅ Deleted Apple Note: \(id)")
    }

    // MARK: - List Notes

    /// List all notes in a folder
    func listNotes(folder: String = "Notes", limit: Int = 100) async throws -> [Note] {
        let escapedFolder = folder.replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        tell application "Notes"
            tell folder "\(escapedFolder)"
                set notesList to notes
                set noteCount to count of notesList
                set maxCount to \(limit)

                if noteCount > maxCount then
                    set noteCount to maxCount
                end if

                set resultList to {}

                repeat with i from 1 to noteCount
                    set currentNote to item i of notesList
                    set noteId to id of currentNote
                    set noteTitle to name of currentNote
                    set end of resultList to {noteId, noteTitle}
                end repeat

                return resultList
            end tell
        end tell
        """

        let result = try await executeAppleScript(script)

        // Parse result (simplified)
        var notes: [Note] = []

        // This is a simplified parser - in production, use proper JSON serialization
        let components = result.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }

        for i in stride(from: 0, to: components.count - 1, by: 2) {
            let id = components[i]
            let title = components[i + 1]

            notes.append(Note(
                id: id,
                title: title,
                body: "",
                folder: folder,
                createdDate: Date(),
                modifiedDate: Date()
            ))
        }

        return notes
    }

    // MARK: - Search Notes

    /// Search notes by query
    func searchNotes(query: String) async throws -> [Note] {
        let escapedQuery = query.replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        tell application "Notes"
            set searchResults to notes whose body contains "\(escapedQuery)" or name contains "\(escapedQuery)"
            set resultList to {}

            repeat with currentNote in searchResults
                set noteId to id of currentNote
                set noteTitle to name of currentNote
                set end of resultList to {noteId, noteTitle}
            end repeat

            return resultList
        end tell
        """

        let result = try await executeAppleScript(script)

        // Parse result (simplified)
        var notes: [Note] = []

        let components = result.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }

        for i in stride(from: 0, to: components.count - 1, by: 2) {
            let id = components[i]
            let title = components[i + 1]

            notes.append(Note(
                id: id,
                title: title,
                body: "",
                folder: "Notes",
                createdDate: Date(),
                modifiedDate: Date()
            ))
        }

        return notes
    }

    // MARK: - Open Note

    /// Open a note in Apple Notes app
    func openNote(id: String) async throws {
        let escapedId = id.replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        tell application "Notes"
            activate
            show note id "\(escapedId)"
        end tell
        """

        _ = try await executeAppleScript(script)

        print("✅ Opened Apple Note: \(id)")
    }

    // MARK: - Check Permissions

    /// Check if we have permission to access Notes
    func checkPermissions() async -> Bool {
        do {
            let script = """
            tell application "Notes"
                count of notes
            end tell
            """

            _ = try await executeAppleScript(script)
            return true
        } catch {
            print("⚠️ No permission to access Apple Notes: \(error)")
            return false
        }
    }

    // MARK: - AppleScript Execution

    /// Execute AppleScript and return result
    private func executeAppleScript(_ script: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            var error: NSDictionary?

            let appleScript = NSAppleScript(source: script)
            let output = appleScript?.executeAndReturnError(&error)

            if let error = error {
                let errorMessage = error["NSAppleScriptErrorMessage"] as? String ?? "Unknown AppleScript error"
                continuation.resume(throwing: CortexError.appleScriptError(message: errorMessage))
                return
            }

            let result = output?.stringValue ?? ""
            continuation.resume(returning: result)
        }
    }
}

