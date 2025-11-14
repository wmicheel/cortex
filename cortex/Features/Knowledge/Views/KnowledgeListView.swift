//
//  KnowledgeListView.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI

/// Main view for displaying knowledge entries list
struct KnowledgeListView: View {
    // MARK: - Properties

    @State private var viewModel = KnowledgeListViewModel()
    @State private var aiViewModel: AIProcessingViewModel?
    @State private var showingAddSheet = false
    @State private var showingAISheet = false
    @State private var selectedEntry: KnowledgeEntry?
    @State private var selectionMode = false
    @State private var selectedEntries: Set<KnowledgeEntry.ID> = []

    // MARK: - Body

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar

                // Tag Filter
                if !viewModel.availableTags.isEmpty {
                    tagFilterBar
                }

                // Content
                contentView
            }
            .navigationTitle("Knowledge Base")
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingAddSheet) {
                AddKnowledgeView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAISheet) {
                if let aiViewModel = aiViewModel {
                    AIProcessingSheet(
                        aiViewModel: aiViewModel,
                        selectedEntries: selectedEntriesArray,
                        onComplete: {
                            selectionMode = false
                            selectedEntries.removeAll()
                            Task {
                                await viewModel.refresh()
                            }
                        }
                    )
                }
            }
            .errorAlert(error: $viewModel.error, onRetry: {
                Task {
                    await viewModel.refresh()
                }
            })
        } detail: {
            detailView
        }
        .task {
            await viewModel.onAppear()
            // Initialize AI ViewModel - uses default MockKnowledgeService
            aiViewModel = AIProcessingViewModel()
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search knowledge...", text: $viewModel.searchText)
                .textFieldStyle(.plain)

            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .padding()
    }

    // MARK: - Tag Filter Bar

    private var tagFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Clear filter button
                if viewModel.selectedTag != nil {
                    Button(action: {
                        viewModel.clearTagFilter()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                            Text("All")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }

                // Tag filters
                ForEach(viewModel.availableTags, id: \.self) { tag in
                    Button(action: {
                        viewModel.selectedTag = tag
                    }) {
                        Text("#\(tag)")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                viewModel.selectedTag == tag
                                    ? Color.accentColor
                                    : Color(nsColor: .controlBackgroundColor)
                            )
                            .foregroundColor(
                                viewModel.selectedTag == tag
                                    ? .white
                                    : .primary
                            )
                            .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.entries.isEmpty {
            loadingView
        } else if viewModel.entries.isEmpty {
            emptyStateView
        } else {
            entryList
        }
    }

    // MARK: - Entry List

    private var entryList: some View {
        List(selection: $selectedEntry) {
            ForEach(viewModel.entries) { entry in
                if selectionMode {
                    // Multi-selection mode
                    HStack(spacing: 12) {
                        Button(action: {
                            toggleSelection(entry.id)
                        }) {
                            Image(systemName: selectedEntries.contains(entry.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedEntries.contains(entry.id) ? .accentColor : .secondary)
                                .font(.title3)
                        }
                        .buttonStyle(.plain)

                        KnowledgeEntryRow(entry: entry)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleSelection(entry.id)
                    }
                } else {
                    // Normal selection mode
                    KnowledgeEntryRow(entry: entry)
                        .tag(entry)
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button("Mit AI verarbeiten") {
                                selectedEntries = [entry.id]
                                showingAISheet = true
                            }

                            Divider()

                            Button("Delete", role: .destructive) {
                                Task {
                                    await viewModel.deleteEntry(entry)
                                }
                            }
                        }
                }
            }
        }
        .listStyle(.sidebar)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        List {
            ForEach(0..<5, id: \.self) { _ in
                SkeletonEntryRow()
            }
        }
        .listStyle(.sidebar)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        Group {
            if !viewModel.searchText.isEmpty {
                // No search results
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No Results Found",
                    message: "No entries match '\(viewModel.searchText)'. Try adjusting your search query.",
                    actionTitle: "Clear Search",
                    action: {
                        viewModel.searchText = ""
                    }
                )
            } else if let tag = viewModel.selectedTag {
                // No entries with selected tag
                EmptyStateView(
                    icon: "tag.slash",
                    title: "No Entries with #\(tag)",
                    message: "There are no knowledge entries tagged with '\(tag)'.",
                    actionTitle: "Clear Filter",
                    action: {
                        viewModel.clearTagFilter()
                    }
                )
            } else {
                // No entries at all
                EmptyStateView(
                    icon: "brain.head.profile",
                    title: "No Knowledge Entries",
                    message: "Start building your second brain by capturing your thoughts, ideas, and learnings.",
                    actionTitle: "Add First Entry",
                    action: {
                        showingAddSheet = true
                    }
                )
            }
        }
    }

    // MARK: - Detail View

    private var detailView: some View {
        Group {
            if let entry = selectedEntry {
                KnowledgeDetailView(entry: entry, viewModel: viewModel)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Select an entry to view details")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            if selectionMode {
                Button(action: {
                    selectionMode = false
                    selectedEntries.removeAll()
                }) {
                    Label("Cancel", systemImage: "xmark")
                }
            } else {
                Button(action: {
                    showingAddSheet = true
                }) {
                    Label("Add Entry", systemImage: "plus")
                }
            }
        }

        ToolbarItem(placement: .automatic) {
            if selectionMode {
                Button(action: {
                    showingAISheet = true
                }) {
                    Label("Mit AI verarbeiten (\(selectedEntries.count))", systemImage: "sparkles")
                }
                .disabled(selectedEntries.isEmpty)
            } else {
                Menu {
                    Button(action: {
                        selectionMode = true
                    }) {
                        Label("Batch AI-Verarbeitung", systemImage: "sparkles")
                    }

                    Divider()

                    Button(action: {
                        Task {
                            await viewModel.refresh()
                        }
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
    }

    // MARK: - Helper Methods

    private var selectedEntriesArray: [KnowledgeEntry] {
        viewModel.entries.filter { selectedEntries.contains($0.id) }
    }

    private func toggleSelection(_ id: KnowledgeEntry.ID) {
        if selectedEntries.contains(id) {
            selectedEntries.remove(id)
        } else {
            selectedEntries.insert(id)
        }
    }
}

// MARK: - Knowledge Entry Row

struct KnowledgeEntryRow: View {
    let entry: KnowledgeEntry
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Block type indicator
            ZStack {
                Circle()
                    .fill(entry.isBlockBased ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
                    .frame(width: 32, height: 32)

                Image(systemName: entry.isBlockBased ? "square.grid.2x2" : "text.alignleft")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(entry.isBlockBased ? .accentColor : .secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text(entry.title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .lineLimit(1)

                // Preview
                Text(entry.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                // Tags and metadata
                HStack(spacing: 8) {
                    if !entry.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(entry.tags.prefix(3), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .foregroundColor(.accentColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(Color.accentColor.opacity(0.1))
                                    )
                            }
                            if entry.tags.count > 3 {
                                Text("+\(entry.tags.count - 3)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()

                    // Timestamp
                    Text(entry.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color(nsColor: .controlBackgroundColor).opacity(0.5) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Preview

#Preview {
    KnowledgeListView()
}
