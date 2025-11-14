//
//  KnowledgeDetailView.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI

/// Detail view for displaying and editing a knowledge entry
struct KnowledgeDetailView: View {
    // MARK: - Properties

    let entry: KnowledgeEntry
    let viewModel: KnowledgeListViewModel

    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedContent: String
    @State private var editedTags: [String]
    @State private var showReminderSheet = false
    @State private var reminderDueDate = Date()
    @State private var reminderPriority = 0
    @State private var isCreatingReminder = false
    @State private var showCalendarSheet = false
    @State private var eventStartDate = Date()
    @State private var eventEndDate = Date().addingTimeInterval(3600) // 1 hour later
    @State private var eventIsAllDay = false
    @State private var isCreatingEvent = false
    @State private var aiViewModel: AIProcessingViewModel?
    @State private var showingAISheet = false
    @State private var useBlockEditor = false

    // MARK: - Initialization

    init(entry: KnowledgeEntry, viewModel: KnowledgeListViewModel) {
        self.entry = entry
        self.viewModel = viewModel

        _editedTitle = State(initialValue: entry.title)
        _editedContent = State(initialValue: entry.content)
        _editedTags = State(initialValue: entry.tags)
        _useBlockEditor = State(initialValue: entry.isBlockBased)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerSection

                // Tags
                if !editedTags.isEmpty || isEditing {
                    tagsSection
                }

                // Content
                contentSection

                // AI Results
                if !isEditing && entry.hasAIProcessing {
                    aiResultsSection
                }

                // Apple Integrations
                if !isEditing {
                    appleIntegrationsSection
                }

                // Metadata
                metadataSection
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(isEditing ? "Edit Entry" : entry.title)
        .navigationSubtitle(entry.tags.isEmpty ? "" : entry.tags.map { "#\($0)" }.joined(separator: " "))
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showReminderSheet) {
            CreateReminderSheet(
                entry: entry,
                dueDate: $reminderDueDate,
                priority: $reminderPriority,
                isCreating: $isCreatingReminder,
                onSave: createReminder
            )
        }
        .sheet(isPresented: $showCalendarSheet) {
            CreateCalendarEventSheet(
                entry: entry,
                startDate: $eventStartDate,
                endDate: $eventEndDate,
                isAllDay: $eventIsAllDay,
                isCreating: $isCreatingEvent,
                onSave: createCalendarEvent
            )
        }
        .sheet(isPresented: $showingAISheet) {
            if let aiViewModel = aiViewModel {
                AIProcessingSheet(
                    aiViewModel: aiViewModel,
                    selectedEntries: [entry],
                    onComplete: {
                        Task {
                            await viewModel.refresh()
                        }
                    }
                )
            }
        }
        .task {
            // Initialize AI ViewModel - uses default MockKnowledgeService
            aiViewModel = AIProcessingViewModel()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isEditing {
                TextField("Title", text: $editedTitle)
                    .textFieldStyle(.plain)
                    .font(.title)
                    .fontWeight(.bold)
            } else {
                Text(entry.title)
                    .font(.title)
                    .fontWeight(.bold)
            }
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.caption)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(editedTags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text("#\(tag)")
                                .font(.caption)

                            if isEditing {
                                Button(action: {
                                    editedTags.removeAll { $0 == tag }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2))
                        .foregroundColor(.accentColor)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    // MARK: - AI Results Section

    private var aiResultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()

            HStack {
                Label("AI-Analyse", systemImage: "sparkles")
                    .font(.headline)

                Spacer()

                Button(action: {
                    showingAISheet = true
                }) {
                    Label("Erneut ausführen", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }

            // AI-Generated Tags
            if let aiTags = entry.aiGeneratedTags, !aiTags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("AI Tags", systemImage: "tag.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button("Tags übernehmen") {
                            mergeAITags()
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(aiTags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.purple.opacity(0.2))
                                    .foregroundColor(.purple)
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
            }

            // AI Summary
            if let aiSummary = entry.aiSummary, !aiSummary.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Zusammenfassung", systemImage: "doc.text.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(aiSummary)
                        .font(.body)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            // Related Entries
            if let relatedIDs = entry.aiRelatedEntryIDs, !relatedIDs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Ähnliche Einträge", systemImage: "link")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ForEach(relatedIDs.prefix(3), id: \.self) { relatedID in
                        if let relatedEntry = viewModel.entries.first(where: { $0.id == relatedID }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.turn.down.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(relatedEntry.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    Text(relatedEntry.content)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()
                            }
                            .padding(8)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(6)
                        }
                    }
                }
            }

            // Processing timestamp
            if let processedAt = entry.aiLastProcessed {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text("Zuletzt verarbeitet: \(processedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Content")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if isEditing {
                    Toggle(isOn: $useBlockEditor) {
                        Label(useBlockEditor ? "Block-Editor" : "Markdown",
                              systemImage: useBlockEditor ? "square.grid.2x2" : "text.alignleft")
                            .font(.caption)
                    }
                    .toggleStyle(.button)
                }
            }

            if isEditing && useBlockEditor {
                // Block-based editor
                BlockEditorView(entry: entry)
                    .frame(minHeight: 300)
            } else if isEditing {
                // Markdown editor
                TextEditor(text: $editedContent)
                    .frame(minHeight: 300)
                    .font(.body)
                    .border(Color.secondary.opacity(0.2))
            } else if entry.isBlockBased {
                // Display block-based content
                BlockEditorView(entry: entry)
                    .disabled(true)
            } else {
                // Display markdown content
                MarkdownView(markdown: entry.content)
                    .font(.body)
            }
        }
    }

    // MARK: - Apple Integrations Section

    private var appleIntegrationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            Text("Apple Integrations")
                .font(.headline)

            // Reminder Integration
            HStack {
                Label("Reminder", systemImage: "checklist")
                    .font(.body)

                Spacer()

                if entry.hasLinkedReminder {
                    Button(action: openReminder) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Open")
                        }
                    }
                    .buttonStyle(.borderless)

                    Button(role: .destructive, action: unlinkReminder) {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.borderless)
                } else {
                    Button(action: {
                        showReminderSheet = true
                    }) {
                        Label("Create", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.vertical, 4)

            // Calendar Event Integration
            HStack {
                Label("Calendar Event", systemImage: "calendar")
                    .font(.body)

                Spacer()

                if entry.hasLinkedCalendarEvent {
                    Button(action: openCalendarEvent) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Open")
                        }
                    }
                    .buttonStyle(.borderless)

                    Button(role: .destructive, action: unlinkCalendarEvent) {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.borderless)
                } else {
                    Button(action: {
                        showCalendarSheet = true
                    }) {
                        Label("Create", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            HStack {
                Label("Created", systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(entry.createdAt.formatted(date: .long, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Label("Modified", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(entry.modifiedAt.formatted(date: .long, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Label("ID", systemImage: "number")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(entry.id)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isEditing {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    cancelEditing()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(!hasChanges)
            }
        } else {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    isEditing = true
                }) {
                    Label("Edit", systemImage: "pencil")
                }
            }

            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive, action: {
                    deleteEntry()
                }) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var hasChanges: Bool {
        editedTitle != entry.title ||
        editedContent != entry.content ||
        editedTags != entry.tags
    }

    // MARK: - Actions

    private func saveChanges() {
        var updatedEntry = entry
        updatedEntry.title = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedEntry.content = editedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedEntry.tags = editedTags
        updatedEntry.isBlockBased = useBlockEditor

        Task {
            await viewModel.updateEntry(updatedEntry)
            isEditing = false
        }
    }

    private func cancelEditing() {
        editedTitle = entry.title
        editedContent = entry.content
        editedTags = entry.tags
        useBlockEditor = entry.isBlockBased
        isEditing = false
    }

    private func deleteEntry() {
        Task {
            await viewModel.deleteEntry(entry)
        }
    }

    // MARK: - Reminder Actions

    private func createReminder() {
        isCreatingReminder = true

        Task {
            await viewModel.createReminder(
                for: entry,
                dueDate: reminderDueDate,
                priority: reminderPriority
            )
            isCreatingReminder = false
            showReminderSheet = false
        }
    }

    private func openReminder() {
        guard let reminderID = entry.linkedReminderID else { return }

        Task {
            await viewModel.openReminder(id: reminderID)
        }
    }

    private func unlinkReminder() {
        Task {
            await viewModel.unlinkReminder(from: entry)
        }
    }

    // MARK: - Calendar Event Actions

    private func createCalendarEvent() {
        isCreatingEvent = true

        Task {
            await viewModel.createCalendarEvent(
                for: entry,
                startDate: eventStartDate,
                endDate: eventEndDate,
                isAllDay: eventIsAllDay
            )
            isCreatingEvent = false
            showCalendarSheet = false
        }
    }

    private func openCalendarEvent() {
        guard let eventID = entry.linkedCalendarEventID else { return }

        Task {
            await viewModel.openCalendarEvent(id: eventID)
        }
    }

    private func unlinkCalendarEvent() {
        Task {
            await viewModel.unlinkCalendarEvent(from: entry)
        }
    }

    // MARK: - AI Actions

    private func mergeAITags() {
        var updatedEntry = entry
        updatedEntry.mergeAITags()

        Task {
            await viewModel.updateEntry(updatedEntry)
        }
    }
}

// MARK: - Create Reminder Sheet

struct CreateReminderSheet: View {
    @Environment(\.dismiss) private var dismiss

    let entry: KnowledgeEntry
    @Binding var dueDate: Date
    @Binding var priority: Int
    @Binding var isCreating: Bool
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Title")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(entry.title)
                            .font(.body)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(entry.content)
                            .font(.body)
                            .lineLimit(3)
                    }
                }

                Section("Due Date") {
                    DatePicker("Date & Time", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        Text("None").tag(0)
                        Text("Low").tag(9)
                        Text("Medium").tag(5)
                        Text("High").tag(1)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Create Reminder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isCreating)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onSave()
                    }
                    .disabled(isCreating)
                }
            }
            .disabled(isCreating)
            .loadingOverlay(isLoading: isCreating, message: "Creating reminder...")
        }
        .frame(width: 500, height: 450)
    }
}

// MARK: - Create Calendar Event Sheet

struct CreateCalendarEventSheet: View {
    @Environment(\.dismiss) private var dismiss

    let entry: KnowledgeEntry
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isAllDay: Bool
    @Binding var isCreating: Bool
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Title")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(entry.title)
                            .font(.body)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(entry.content)
                            .font(.body)
                            .lineLimit(3)
                    }
                }

                Section("When") {
                    Toggle("All Day Event", isOn: $isAllDay)

                    if isAllDay {
                        DatePicker("Date", selection: $startDate, displayedComponents: [.date])
                    } else {
                        DatePicker("Starts", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                        DatePicker("Ends", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Create Calendar Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isCreating)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onSave()
                    }
                    .disabled(isCreating || (!isAllDay && endDate <= startDate))
                }
            }
            .disabled(isCreating)
            .loadingOverlay(isLoading: isCreating, message: "Creating calendar event...")
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        KnowledgeDetailView(
            entry: KnowledgeEntry(
                title: "Sample Entry",
                content: "This is a sample knowledge entry with some content.",
                tags: ["swift", "ios", "development"]
            ),
            viewModel: KnowledgeListViewModel()
        )
    }
}
