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
                        Button(showMarkdownPreview ? "Edit" : "Preview") {
                            showMarkdownPreview.toggle()
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    }
                }

                Section("Tags") {
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

                    if !tags.isEmpty {
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

                    // Suggested tags
                    if !viewModel.availableTags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suggested")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(viewModel.availableTags.prefix(10), id: \.self) { tag in
                                        if !tags.contains(tag) {
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
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Knowledge Entry")
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
                tags: tags
            )

            isSaving = false
            dismiss()
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
