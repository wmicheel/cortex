//
//  AddKnowledgeView.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI

/// View for adding a new knowledge entry
struct AddKnowledgeView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    let viewModel: KnowledgeListViewModel

    @State private var title = ""
    @State private var content = ""
    @State private var tagInput = ""
    @State private var tags: [String] = []
    @State private var isSaving = false
    @State private var showMarkdownPreview = false
    @State private var isAutoTagEnabled = true
    @State private var suggestedTags: [String] = []
    @State private var suggestionTask: Task<Void, Never>?
    @State private var showVoiceInput = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Enter title", text: $title)
                        .textFieldStyle(.plain)
                }

                Section {
                    if showMarkdownPreview {
                        ScrollView {
                            MarkdownView(markdown: content.isEmpty ? "*Preview will appear here*" : content)
                                .frame(minHeight: 200, alignment: .topLeading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(minHeight: 200)
                    } else {
                        TextEditor(text: $content)
                            .frame(minHeight: 200)
                            .font(.body)
                    }
                } header: {
                    HStack {
                        Text("Content")
                        Spacer()

                        // Voice Input Button
                        Button(action: {
                            showVoiceInput = true
                        }) {
                            Label("Voice", systemImage: "mic.fill")
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)

                        Button(showMarkdownPreview ? "Edit" : "Preview") {
                            showMarkdownPreview.toggle()
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    }
                }

                Section {
                    // Auto-Tag Toggle
                    Toggle("Auto-Suggest Tags", isOn: $isAutoTagEnabled)
                        .onChange(of: isAutoTagEnabled) { _, newValue in
                            if newValue {
                                updateTagSuggestions()
                            } else {
                                suggestedTags = []
                            }
                        }

                    // Manual Tag Input
                    HStack {
                        TextField("Add tag", text: $tagInput)
                            .textFieldStyle(.plain)
                            .onSubmit {
                                addTag()
                            }

                        Button(action: addTag) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .disabled(tagInput.isEmpty)
                    }

                    // User Tags
                    if !tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Tags")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(tags, id: \.self) { tag in
                                        TagChip(tag: tag) {
                                            removeTag(tag)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // AI-Suggested Tags
                    if isAutoTagEnabled && !suggestedTags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AI Suggested (will be added automatically)")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(suggestedTags, id: \.self) { tag in
                                        if !tags.contains(tag) {
                                            Button(action: {
                                                tags.append(tag)
                                            }) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "sparkles")
                                                        .font(.caption2)
                                                    Text("#\(tag)")
                                                }
                                                .font(.caption)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 4)
                                                .background(Color.accentColor.opacity(0.1))
                                                .foregroundColor(.accentColor)
                                                .cornerRadius(12)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Existing Tags (from other entries)
                    if !viewModel.availableTags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Existing Tags")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(viewModel.availableTags.prefix(10), id: \.self) { tag in
                                        if !tags.contains(tag) && !suggestedTags.contains(tag) {
                                            Button(action: {
                                                tags.append(tag)
                                            }) {
                                                Text("#\(tag)")
                                                    .font(.caption)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 4)
                                                    .background(Color(nsColor: .controlBackgroundColor))
                                                    .cornerRadius(12)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text("Tags")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Knowledge Entry")
            .onChange(of: title) { _, _ in
                updateTagSuggestions()
            }
            .onChange(of: content) { _, _ in
                updateTagSuggestions()
            }
            .sheet(isPresented: $showVoiceInput) {
                VoiceInputView { transcript in
                    // Append transcript to content
                    if !content.isEmpty && !content.hasSuffix("\n") {
                        content += "\n\n"
                    }
                    content += transcript
                    showVoiceInput = false
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(!isValid || isSaving)
                }
            }
            .disabled(isSaving)
            .loadingOverlay(isLoading: isSaving, message: "Saving entry...")
        }
    }

    // MARK: - Computed Properties

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Actions

    private func addTag() {
        let trimmedTag = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty, !tags.contains(trimmedTag) else {
            tagInput = ""
            return
        }

        tags.append(trimmedTag)
        tagInput = ""
    }

    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    private func saveEntry() {
        isSaving = true

        Task {
            await viewModel.createEntry(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                tags: tags,
                autoTag: isAutoTagEnabled
            )

            isSaving = false
            dismiss()
        }
    }

    private func updateTagSuggestions() {
        // Cancel previous task
        suggestionTask?.cancel()

        // Only suggest if auto-tag is enabled and we have content
        guard isAutoTagEnabled else {
            suggestedTags = []
            return
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty || !trimmedContent.isEmpty else {
            suggestedTags = []
            return
        }

        // Debounce: wait 800ms before suggesting
        suggestionTask = Task {
            try? await Task.sleep(for: .milliseconds(800))

            guard !Task.isCancelled else { return }

            let suggestions = await viewModel.suggestTags(
                title: trimmedTitle,
                content: trimmedContent
            )

            guard !Task.isCancelled else { return }

            suggestedTags = suggestions
        }
    }
}

// MARK: - Tag Chip

struct TagChip: View {
    let tag: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text("#\(tag)")
                .font(.caption)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.2))
        .foregroundColor(.accentColor)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    AddKnowledgeView(viewModel: KnowledgeListViewModel())
}
