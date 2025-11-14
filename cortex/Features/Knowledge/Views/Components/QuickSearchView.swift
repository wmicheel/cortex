//
//  QuickSearchView.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI

/// Quick search overlay (Cmd+K)
struct QuickSearchView: View {
    // MARK: - Properties

    @Binding var isPresented: Bool
    @State private var viewModel = KnowledgeListViewModel()
    @State private var searchQuery = ""
    @FocusState private var isSearchFocused: Bool

    var onSelectEntry: (KnowledgeEntry) -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search knowledge...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($isSearchFocused)
                    .onChange(of: searchQuery) { oldValue, newValue in
                        Task {
                            viewModel.searchText = newValue
                        }
                    }

                if !searchQuery.isEmpty {
                    Button(action: {
                        searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Results
            if viewModel.isLoading {
                loadingView
            } else if viewModel.entries.isEmpty && !searchQuery.isEmpty {
                emptyResultsView
            } else if viewModel.entries.isEmpty {
                emptyStateView
            } else {
                resultsList
            }
        }
        .frame(width: 600, height: 500)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        .onAppear {
            isSearchFocused = true
            Task {
                await viewModel.onAppear()
            }
        }
    }

    // MARK: - Results List

    private var resultsList: some View {
        ScrollView {
            VStack(spacing: 1) {
                ForEach(viewModel.entries.prefix(10)) { entry in
                    QuickSearchResultRow(entry: entry) {
                        onSelectEntry(entry)
                        isPresented = false
                    }
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 1) {
            ForEach(0..<5, id: \.self) { _ in
                SkeletonEntryRow()
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.001))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Empty Results

    private var emptyResultsView: some View {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            message: "No entries match '\(searchQuery)'. Try a different search term or check your spelling."
        )
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "command.circle",
            title: "Quick Search",
            message: "Type to search your knowledge base by title, content, or tags. Press Escape to close."
        )
    }
}

// MARK: - Quick Search Result Row

struct QuickSearchResultRow: View {
    let entry: KnowledgeEntry
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.accentColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.headline)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(entry.content)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if !entry.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(entry.tags.prefix(3), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption2)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.001))
        .onHover { isHovered in
            if isHovered {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    QuickSearchView(isPresented: .constant(true)) { _ in }
}
