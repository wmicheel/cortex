//
//  ModernKnowledgeListView.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI

/// Modern knowledge list view with glass-morphism and animations
struct ModernKnowledgeListView: View {
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
            ZStack {
                // Animated background
                AnimatedGradientBackground()
                    .opacity(0.3)

                VStack(spacing: DesignSystem.Spacing.md) {
                    // Modern Search Bar
                    modernSearchBar

                    // Tag Filter
                    if !viewModel.availableTags.isEmpty {
                        modernTagFilterBar
                    }

                    // Content
                    contentView
                }
                .padding(DesignSystem.Spacing.lg)
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
            aiViewModel = AIProcessingViewModel()
        }
    }

    // MARK: - Modern Search Bar

    private var modernSearchBar: some View {
        GlassCard(cornerRadius: DesignSystem.CornerRadius.xl, padding: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(DesignSystem.Typography.titleMedium)
                    .foregroundColor(DesignSystem.Colors.primaryBlue)

                TextField("Search your knowledge...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(DesignSystem.Typography.bodyMedium)

                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        withAnimation(DesignSystem.Animations.spring) {
                            viewModel.searchText = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .hoverScale()
                }
            }
        }
    }

    // MARK: - Modern Tag Filter Bar

    private var modernTagFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                // Clear filter button
                if viewModel.selectedTag != nil {
                    GlassBadge(
                        text: "All",
                        color: DesignSystem.Colors.primaryBlue,
                        icon: "xmark.circle.fill"
                    )
                    .onTapGesture {
                        withAnimation(DesignSystem.Animations.spring) {
                            viewModel.clearTagFilter()
                        }
                    }
                    .hoverScale()
                }

                // Tag filters
                ForEach(viewModel.availableTags, id: \.self) { tag in
                    GlassBadge(
                        text: tag,
                        color: viewModel.selectedTag == tag
                            ? DesignSystem.Colors.primaryBlue
                            : DesignSystem.Colors.textSecondary,
                        icon: "tag.fill"
                    )
                    .onTapGesture {
                        withAnimation(DesignSystem.Animations.spring) {
                            viewModel.selectedTag = tag
                        }
                    }
                    .hoverScale()
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        Group {
            if viewModel.isLoading && viewModel.entries.isEmpty {
                loadingView
            } else if viewModel.entries.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: DesignSystem.Spacing.md) {
                        ForEach(viewModel.entries) { entry in
                            ModernEntryCard(
                                entry: entry,
                                isSelected: selectedEntries.contains(entry.id),
                                selectionMode: selectionMode,
                                onTap: {
                                    if selectionMode {
                                        toggleSelection(entry.id)
                                    } else {
                                        selectedEntry = entry
                                    }
                                },
                                onLongPress: {
                                    withAnimation(DesignSystem.Animations.spring) {
                                        selectionMode = true
                                        toggleSelection(entry.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.xs)
                }
            }
        }
    }

    // MARK: - Detail View

    @ViewBuilder
    private var detailView: some View {
        if let entry = selectedEntry {
            KnowledgeDetailView(entry: entry, viewModel: viewModel)
        } else {
            EmptyStateView(
                icon: "brain.head.profile",
                title: "No Selection",
                message: "Select an entry from the list to view its details",
                actionTitle: nil,
                action: nil
            )
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        GlassCard {
            EmptyStateView(
                icon: "brain.head.profile",
                title: viewModel.searchText.isEmpty ? "No Entries Yet" : "No Results",
                message: viewModel.searchText.isEmpty
                    ? "Start building your knowledge base by adding your first entry"
                    : "Try a different search term or tag",
                actionTitle: viewModel.searchText.isEmpty ? "Add First Entry" : nil,
                action: viewModel.searchText.isEmpty ? {
                    showingAddSheet = true
                } : nil
            )
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading your knowledge...")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                if selectionMode {
                    // Selection Mode Actions
                    GlassButton(
                        title: "Cancel",
                        icon: nil,
                        action: {
                            withAnimation(DesignSystem.Animations.spring) {
                                selectionMode = false
                                selectedEntries.removeAll()
                            }
                        },
                        style: .secondary
                    )

                    if !selectedEntries.isEmpty {
                        GlassButton(
                            title: "AI Process (\(selectedEntries.count))",
                            icon: "sparkles",
                            action: {
                                showingAISheet = true
                            },
                            style: .primary
                        )
                    }
                } else {
                    // Normal Mode Actions
                    GlassButton(
                        title: "Add",
                        icon: "plus",
                        action: {
                            showingAddSheet = true
                        },
                        style: .primary
                    )

                    if !viewModel.entries.isEmpty {
                        GlassButton(
                            title: "Select",
                            icon: "checkmark.circle",
                            action: {
                                withAnimation(DesignSystem.Animations.spring) {
                                    selectionMode = true
                                }
                            },
                            style: .secondary
                        )
                    }
                }
            }
        }
    }

    // MARK: - Helpers

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

// MARK: - Modern Entry Card

struct ModernEntryCard: View {
    let entry: KnowledgeEntry
    let isSelected: Bool
    let selectionMode: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Selection Indicator
                if selectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(DesignSystem.Typography.titleMedium)
                        .foregroundColor(isSelected ? DesignSystem.Colors.primaryBlue : .secondary)
                        .transition(DesignSystem.Transitions.scaleAndFade)
                }

                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.primaryBlue.opacity(0.2),
                                    DesignSystem.Colors.primaryPurple.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: entry.isBlockBased ? "square.grid.3x3" : "doc.text")
                        .font(DesignSystem.Typography.titleMedium)
                        .foregroundColor(DesignSystem.Colors.primaryBlue)
                }

                // Content
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    // Title with AI indicator
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text(entry.title)
                            .font(DesignSystem.Typography.titleMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .lineLimit(1)

                        if entry.hasAIProcessing {
                            Image(systemName: "sparkles")
                                .font(DesignSystem.Typography.labelSmall)
                                .foregroundColor(DesignSystem.Colors.primaryPurple)
                        }
                    }

                    // Preview
                    Text(entry.content)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(2)

                    // Tags
                    if !entry.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignSystem.Spacing.xxs) {
                                ForEach(entry.tags.prefix(3), id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(DesignSystem.Typography.labelSmall)
                                        .foregroundColor(DesignSystem.Colors.primaryBlue)
                                        .padding(.horizontal, DesignSystem.Spacing.xs)
                                        .padding(.vertical, DesignSystem.Spacing.xxxs)
                                        .background(DesignSystem.Colors.primaryBlue.opacity(0.1))
                                        .cornerRadius(DesignSystem.CornerRadius.xs)
                                }

                                if entry.tags.count > 3 {
                                    Text("+\(entry.tags.count - 3)")
                                        .font(DesignSystem.Typography.labelSmall)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                Spacer()

                // Metadata
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xxs) {
                    Text(entry.modifiedAt, style: .relative)
                        .font(DesignSystem.Typography.labelSmall)
                        .foregroundColor(.secondary)

                    // Linked items indicators
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        if entry.hasLinkedReminder {
                            Image(systemName: "bell.fill")
                                .font(DesignSystem.Typography.labelSmall)
                                .foregroundColor(DesignSystem.Colors.warning)
                        }

                        if entry.hasLinkedCalendarEvent {
                            Image(systemName: "calendar")
                                .font(DesignSystem.Typography.labelSmall)
                                .foregroundColor(DesignSystem.Colors.info)
                        }

                        if entry.hasLinkedNote {
                            Image(systemName: "note.text")
                                .font(DesignSystem.Typography.labelSmall)
                                .foregroundColor(DesignSystem.Colors.success)
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                ZStack {
                    Color(nsColor: .controlBackgroundColor)

                    if isHovered || isSelected {
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.primaryBlue.opacity(0.05),
                                DesignSystem.Colors.primaryPurple.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .cornerRadius(DesignSystem.CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .strokeBorder(
                        isSelected
                            ? DesignSystem.Colors.primaryBlue.opacity(0.5)
                            : (isHovered ? Color.white.opacity(0.2) : Color.white.opacity(0.1)),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .designSystemShadow(isHovered ? DesignSystem.Shadows.medium : DesignSystem.Shadows.small)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(DesignSystem.Animations.spring) {
                isHovered = hovering
            }
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    onLongPress()
                }
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ModernKnowledgeListView()
    }
}
