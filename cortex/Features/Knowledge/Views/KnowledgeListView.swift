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
    @State private var showingAddSheet = false
    @State private var selectedEntry: KnowledgeEntry?

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
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        } detail: {
            detailView
        }
        .task {
            await viewModel.onAppear()
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
                KnowledgeEntryRow(entry: entry)
                    .tag(entry)
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            Task {
                                await viewModel.deleteEntry(entry)
                            }
                        }
                    }
            }
        }
        .listStyle(.sidebar)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading knowledge entries...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Knowledge Entries")
                .font(.title2)
                .fontWeight(.semibold)

            Text(emptyStateMessage)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: {
                showingAddSheet = true
            }) {
                Label("Add First Entry", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateMessage: String {
        if !viewModel.searchText.isEmpty {
            return "No entries match '\(viewModel.searchText)'"
        } else if viewModel.selectedTag != nil {
            return "No entries with this tag"
        } else {
            return "Start building your second brain by adding your first knowledge entry"
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
            Button(action: {
                showingAddSheet = true
            }) {
                Label("Add Entry", systemImage: "plus")
            }
        }

        ToolbarItem(placement: .automatic) {
            Button(action: {
                Task {
                    await viewModel.refresh()
                }
            }) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .disabled(viewModel.isLoading)
        }
    }
}

// MARK: - Knowledge Entry Row

struct KnowledgeEntryRow: View {
    let entry: KnowledgeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.title)
                .font(.headline)
                .lineLimit(1)

            Text(entry.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            if !entry.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(entry.tags.prefix(3), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                    if entry.tags.count > 3 {
                        Text("+\(entry.tags.count - 3)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Text(entry.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    KnowledgeListView()
}
