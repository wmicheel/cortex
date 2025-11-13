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

    // MARK: - Initialization

    init(entry: KnowledgeEntry, viewModel: KnowledgeListViewModel) {
        self.entry = entry
        self.viewModel = viewModel

        _editedTitle = State(initialValue: entry.title)
        _editedContent = State(initialValue: entry.content)
        _editedTags = State(initialValue: entry.tags)
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

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Content")
                .font(.caption)
                .foregroundColor(.secondary)

            if isEditing {
                TextEditor(text: $editedContent)
                    .frame(minHeight: 300)
                    .font(.body)
                    .border(Color.secondary.opacity(0.2))
            } else {
                Text(entry.content)
                    .font(.body)
                    .textSelection(.enabled)
            }
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

        Task {
            await viewModel.updateEntry(updatedEntry)
            isEditing = false
        }
    }

    private func cancelEditing() {
        editedTitle = entry.title
        editedContent = entry.content
        editedTags = entry.tags
        isEditing = false
    }

    private func deleteEntry() {
        Task {
            await viewModel.deleteEntry(entry)
        }
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
