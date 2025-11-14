//
//  DashboardView.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI

/// Main dashboard view showing overview and statistics
struct DashboardView: View {
    // MARK: - Properties

    @State private var knowledgeViewModel = KnowledgeListViewModel()
    @State private var showingAddSheet = false
    @State private var showQuickSearch = false

    var onNavigateToKnowledge: () -> Void = {}
    var onNavigateToSettings: () -> Void = {}

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection

                // Statistics Cards
                if knowledgeViewModel.isLoading && knowledgeViewModel.statistics == nil {
                    skeletonStatistics
                } else if let stats = knowledgeViewModel.statistics {
                    statisticsSection(stats: stats)
                }

                // Recent Entries
                recentEntriesSection

                // Quick Actions
                quickActionsSection
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .sheet(isPresented: $showingAddSheet) {
            AddKnowledgeView(viewModel: knowledgeViewModel)
        }
        .errorAlert(error: $knowledgeViewModel.error, onRetry: {
            Task {
                await knowledgeViewModel.refresh()
            }
        })
        .task {
            await knowledgeViewModel.onAppear()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome to Cortex")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Your Second Brain")
                .font(.title3)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Skeleton Statistics

    private var skeletonStatistics: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 16) {
                SkeletonStatCard()
                SkeletonStatCard()
                SkeletonStatCard()
            }
        }
    }

    // MARK: - Statistics Section

    private func statisticsSection(stats: KnowledgeStatistics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 16) {
                StatCard(
                    title: "Total Entries",
                    value: "\(stats.totalEntries)",
                    icon: "brain.head.profile",
                    color: .blue
                )

                StatCard(
                    title: "Tags",
                    value: "\(stats.totalTags)",
                    icon: "tag.fill",
                    color: .green
                )

                StatCard(
                    title: "Recent",
                    value: "\(stats.recentEntries.count)",
                    icon: "clock.fill",
                    color: .orange
                )
            }

            // Most Used Tags
            if !stats.mostUsedTags.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Most Used Tags")
                        .font(.headline)

                    FlowLayout(spacing: 8) {
                        ForEach(stats.mostUsedTags.prefix(10), id: \.tag) { item in
                            HStack(spacing: 4) {
                                Text("#\(item.tag)")
                                    .font(.caption)
                                Text("(\(item.count))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundColor(.accentColor)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Recent Entries Section

    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Entries")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                NavigationLink(destination: KnowledgeListView()) {
                    Text("View All")
                        .font(.subheadline)
                }
            }

            if knowledgeViewModel.entries.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 8) {
                    ForEach(knowledgeViewModel.entries.prefix(5)) { entry in
                        RecentEntryCard(entry: entry)
                    }
                }
            }
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 16) {
                QuickActionButton(
                    title: "New Entry",
                    icon: "plus.circle.fill",
                    color: .blue
                ) {
                    showingAddSheet = true
                }

                QuickActionButton(
                    title: "Search",
                    icon: "magnifyingglass.circle.fill",
                    color: .green
                ) {
                    onNavigateToKnowledge()
                }

                QuickActionButton(
                    title: "Settings",
                    icon: "gearshape.circle.fill",
                    color: .gray
                ) {
                    onNavigateToSettings()
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "brain.head.profile",
            title: "No Recent Entries",
            message: "Your recent knowledge entries will appear here once you start adding content.",
            actionTitle: "Add First Entry",
            action: {
                showingAddSheet = true
            }
        )
        .frame(height: 200)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.system(size: 32, weight: .bold))

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Recent Entry Card

struct RecentEntryCard: View {
    let entry: KnowledgeEntry

    var body: some View {
        NavigationLink(destination: KnowledgeDetailView(
            entry: entry,
            viewModel: KnowledgeListViewModel()
        )) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.headline)
                        .lineLimit(1)

                    Text(entry.content)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(entry.modifiedAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: result.positions[index], proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DashboardView()
    }
}
