//
//  ModernDashboardView.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI
import Charts

/// Modern dashboard with analytics, activity feed, and smart recommendations
struct ModernDashboardView: View {
    // MARK: - Properties

    @State private var viewModel = DashboardViewModel()
    @State private var showingAddSheet = false

    var onNavigateToKnowledge: () -> Void = {}
    var onNavigateToSettings: () -> Void = {}

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Hero Section
                heroSection

                if viewModel.isLoading {
                    loadingView
                } else {
                    // Analytics Section
                    analyticsSection

                    // Activity & Recommendations
                    HStack(alignment: .top, spacing: 20) {
                        // Activity Feed
                        activityFeedSection
                            .frame(maxWidth: .infinity)

                        // Smart Recommendations
                        recommendationsSection
                            .frame(maxWidth: .infinity)
                    }

                    // Quick Actions
                    quickActionsBar
                }
            }
            .padding(32)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("Dashboard")
        .sheet(isPresented: $showingAddSheet) {
            AddKnowledgeView(viewModel: KnowledgeListViewModel())
        }
        .task {
            await viewModel.onAppear()
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome to Cortex")
                        .font(.system(size: 42, weight: .bold, design: .rounded))

                    Text("Your Second Brain, Powered by AI")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Quick Stats
                if let stats = viewModel.statistics {
                    HStack(spacing: 24) {
                        HeroStatPill(
                            value: "\(stats.totalEntries)",
                            label: "Entries",
                            icon: "brain.head.profile"
                        )

                        HeroStatPill(
                            value: "\(stats.totalTags)",
                            label: "Tags",
                            icon: "tag.fill"
                        )

                        if let aiStats = viewModel.aiProcessingStats {
                            HeroStatPill(
                                value: String(format: "%.0f%%", aiStats.percentage),
                                label: "AI Enhanced",
                                icon: "sparkles"
                            )
                        }
                    }
                }
            }
            .padding(28)
            .background(
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.15),
                        Color.accentColor.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Analytics Section

    private var analyticsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Analytics")
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 20) {
                // Entries per Week Chart
                if !viewModel.entriesPerWeek.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Entries per Week", systemImage: "chart.bar.fill")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Chart(viewModel.entriesPerWeek) { item in
                            BarMark(
                                x: .value("Week", item.week),
                                y: .value("Count", item.count)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(6)
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks(values: .automatic) { value in
                                AxisValueLabel()
                                    .font(.caption2)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                    }
                    .padding(20)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
                }

                // AI Processing Stats
                if let aiStats = viewModel.aiProcessingStats {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("AI Processing", systemImage: "sparkles")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        VStack(spacing: 12) {
                            AIStatRow(
                                icon: "brain.head.profile",
                                label: "Total Processed",
                                value: "\(aiStats.totalProcessed)",
                                color: .purple
                            )

                            AIStatRow(
                                icon: "tag.fill",
                                label: "Auto-Tagged",
                                value: "\(aiStats.withTags)",
                                color: .blue
                            )

                            AIStatRow(
                                icon: "doc.text.fill",
                                label: "Summarized",
                                value: "\(aiStats.withSummary)",
                                color: .green
                            )

                            AIStatRow(
                                icon: "link",
                                label: "Linked",
                                value: "\(aiStats.withRelations)",
                                color: .orange
                            )
                        }

                        // Progress bar
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Coverage")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 8)

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.purple, Color.blue],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(
                                            width: geometry.size.width * (aiStats.percentage / 100),
                                            height: 8
                                        )
                                }
                            }
                            .frame(height: 8)

                            Text("\(Int(aiStats.percentage))% of entries enhanced with AI")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(20)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
                }
            }
        }
    }

    // MARK: - Activity Feed Section

    private var activityFeedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Recent Activity", systemImage: "clock.fill")
                .font(.headline)

            if viewModel.activityFeed.isEmpty {
                Text("No recent activity")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.activityFeed) { activity in
                        ActivityRow(activity: activity)
                        if activity.id != viewModel.activityFeed.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Smart Recommendations", systemImage: "lightbulb.fill")
                .font(.headline)

            if viewModel.recommendations.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)

                    Text("All caught up!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.recommendations) { recommendation in
                        RecommendationCard(recommendation: recommendation)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }

    // MARK: - Quick Actions Bar

    private var quickActionsBar: some View {
        HStack(spacing: 16) {
            ModernQuickActionButton(
                title: "New Entry",
                icon: "plus.circle.fill",
                gradient: [Color.blue, Color.cyan],
                action: {
                    showingAddSheet = true
                }
            )

            ModernQuickActionButton(
                title: "AI Process",
                icon: "sparkles",
                gradient: [Color.purple, Color.pink],
                action: {
                    onNavigateToKnowledge()
                }
            )

            ModernQuickActionButton(
                title: "Search",
                icon: "magnifyingglass",
                gradient: [Color.green, Color.mint],
                action: {
                    onNavigateToKnowledge()
                }
            )

            ModernQuickActionButton(
                title: "Settings",
                icon: "gearshape.fill",
                gradient: [Color.gray, Color.gray.opacity(0.7)],
                action: {
                    onNavigateToSettings()
                }
            )
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading dashboard...")
                .foregroundColor(.secondary)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Hero Stat Pill

struct HeroStatPill: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)

                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - AI Stat Row

struct AIStatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let activity: ActivityItem

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(colorForType(activity.type).opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: activity.type.icon)
                    .font(.caption)
                    .foregroundColor(colorForType(activity.type))
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.entryTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(activity.type.actionText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Timestamp
            Text(activity.timestamp, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }

    private func colorForType(_ type: ActivityItem.ActivityType) -> Color {
        switch type {
        case .created: return .green
        case .modified: return .blue
        case .aiProcessed: return .purple
        case .tagAdded: return .orange
        }
    }
}

// MARK: - Recommendation Card

struct RecommendationCard: View {
    let recommendation: Recommendation

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(recommendation.color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: recommendation.icon)
                    .font(.body)
                    .foregroundColor(recommendation.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Action button
            Button(recommendation.actionTitle) {
                // TODO: Handle action
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Modern Quick Action Button

struct ModernQuickActionButton: View {
    let title: String
    let icon: String
    let gradient: [Color]
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: gradient.first!.opacity(0.3), radius: isHovered ? 12 : 8, y: 4)

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ModernDashboardView()
    }
}
