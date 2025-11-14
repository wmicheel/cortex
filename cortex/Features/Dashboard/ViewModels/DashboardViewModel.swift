//
//  DashboardViewModel.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation
import Observation

/// ViewModel for Dashboard with analytics and insights
@MainActor
@Observable
final class DashboardViewModel {
    // MARK: - Properties

    private let knowledgeService: any KnowledgeServiceProtocol

    // State
    private(set) var isLoading = false
    private(set) var statistics: KnowledgeStatistics?
    private(set) var recentEntries: [KnowledgeEntry] = []
    private(set) var activityFeed: [ActivityItem] = []
    private(set) var recommendations: [Recommendation] = []
    var error: CortexError?

    // Analytics
    private(set) var entriesPerWeek: [WeekData] = []
    private(set) var aiProcessingStats: AIStats?

    // MARK: - Initialization

    init(knowledgeService: (any KnowledgeServiceProtocol)? = nil) {
        if let service = knowledgeService {
            self.knowledgeService = service
        } else {
            do {
                self.knowledgeService = try SwiftDataKnowledgeService()
                print("✅ DashboardViewModel using SwiftDataKnowledgeService")
            } catch {
                print("⚠️ SwiftData unavailable for DashboardViewModel, using MockKnowledgeService: \(error)")
                self.knowledgeService = MockKnowledgeService()
            }
        }
    }

    // MARK: - Lifecycle

    func onAppear() async {
        await loadDashboardData()
    }

    func refresh() async {
        await loadDashboardData()
    }

    // MARK: - Data Loading

    private func loadDashboardData() async {
        isLoading = true
        error = nil

        do {
            // Load statistics
            statistics = try await knowledgeService.getStatistics()

            // Load recent entries
            let allEntries = try await knowledgeService.fetchAll(forceRefresh: false)
            recentEntries = Array(allEntries.prefix(5))

            // Calculate analytics
            calculateEntriesPerWeek(from: allEntries)
            calculateAIStats(from: allEntries)

            // Generate activity feed
            generateActivityFeed(from: allEntries)

            // Generate smart recommendations
            await generateRecommendations(from: allEntries)

        } catch let cortexError as CortexError {
            error = cortexError
        } catch {
            self.error = .invalidData
        }

        isLoading = false
    }

    // MARK: - Analytics

    private func calculateEntriesPerWeek(from entries: [KnowledgeEntry]) {
        let calendar = Calendar.current
        let now = Date()

        // Last 8 weeks
        var weekData: [WeekData] = []

        for weekOffset in (0..<8).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now),
                  let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
                continue
            }

            let count = entries.filter { entry in
                entry.createdAt >= weekStart && entry.createdAt < weekEnd
            }.count

            let weekLabel = calendar.component(.weekOfYear, from: weekStart)
            weekData.append(WeekData(week: "W\(weekLabel)", count: count))
        }

        self.entriesPerWeek = weekData
    }

    private func calculateAIStats(from entries: [KnowledgeEntry]) {
        let totalEntries = entries.count
        let aiProcessedEntries = entries.filter { $0.hasAIProcessing }.count
        let entriesWithAITags = entries.filter { $0.hasAITags }.count
        let entriesWithSummary = entries.filter { $0.hasAISummary }.count
        let entriesWithRelations = entries.filter { $0.hasAIRelations }.count

        aiProcessingStats = AIStats(
            totalProcessed: aiProcessedEntries,
            withTags: entriesWithAITags,
            withSummary: entriesWithSummary,
            withRelations: entriesWithRelations,
            percentage: totalEntries > 0 ? Double(aiProcessedEntries) / Double(totalEntries) * 100 : 0
        )
    }

    // MARK: - Activity Feed

    private func generateActivityFeed(from entries: [KnowledgeEntry]) {
        var feed: [ActivityItem] = []

        // Recent creations
        let recentCreated = entries
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(3)

        for entry in recentCreated {
            feed.append(ActivityItem(
                id: UUID().uuidString,
                type: .created,
                entryTitle: entry.title,
                entryID: entry.id,
                timestamp: entry.createdAt
            ))
        }

        // Recent modifications
        let recentModified = entries
            .filter { $0.modifiedAt != $0.createdAt }
            .sorted { $0.modifiedAt > $1.modifiedAt }
            .prefix(3)

        for entry in recentModified {
            feed.append(ActivityItem(
                id: UUID().uuidString,
                type: .modified,
                entryTitle: entry.title,
                entryID: entry.id,
                timestamp: entry.modifiedAt
            ))
        }

        // AI processed
        let aiProcessed = entries
            .filter { $0.hasAIProcessing }
            .sorted { ($0.aiLastProcessed ?? .distantPast) > ($1.aiLastProcessed ?? .distantPast) }
            .prefix(2)

        for entry in aiProcessed {
            if let processedDate = entry.aiLastProcessed {
                feed.append(ActivityItem(
                    id: UUID().uuidString,
                    type: .aiProcessed,
                    entryTitle: entry.title,
                    entryID: entry.id,
                    timestamp: processedDate
                ))
            }
        }

        // Sort by timestamp
        self.activityFeed = feed.sorted { $0.timestamp > $1.timestamp }.prefix(10).map { $0 }
    }

    // MARK: - Smart Recommendations

    private func generateRecommendations(from entries: [KnowledgeEntry]) async {
        var recs: [Recommendation] = []

        // Recommend untagged entries
        let untaggedEntries = entries.filter { $0.tags.isEmpty }
        if !untaggedEntries.isEmpty {
            recs.append(Recommendation(
                id: UUID().uuidString,
                type: .needsTags,
                title: "Add tags to \(untaggedEntries.count) entries",
                description: "Help organize your knowledge by adding tags to untagged entries",
                actionTitle: "Review",
                icon: "tag.fill",
                color: .orange
            ))
        }

        // Recommend AI processing for entries without AI data
        let unprocessedEntries = entries.filter { !$0.hasAIProcessing }
        if unprocessedEntries.count > 5 {
            recs.append(Recommendation(
                id: UUID().uuidString,
                type: .aiProcessing,
                title: "AI-process \(unprocessedEntries.count) entries",
                description: "Generate summaries, tags, and find related entries using AI",
                actionTitle: "Process",
                icon: "sparkles",
                color: .purple
            ))
        }

        // Recommend exploring related entries
        let entriesWithRelations = entries.filter { $0.hasAIRelations }
        if !entriesWithRelations.isEmpty {
            recs.append(Recommendation(
                id: UUID().uuidString,
                type: .exploreRelations,
                title: "Explore connected knowledge",
                description: "\(entriesWithRelations.count) entries have AI-discovered connections",
                actionTitle: "Explore",
                icon: "link",
                color: .blue
            ))
        }

        self.recommendations = recs
    }
}

// MARK: - Supporting Types

struct WeekData: Identifiable {
    let id = UUID()
    let week: String
    let count: Int
}

struct AIStats {
    let totalProcessed: Int
    let withTags: Int
    let withSummary: Int
    let withRelations: Int
    let percentage: Double
}

struct ActivityItem: Identifiable {
    let id: String
    let type: ActivityType
    let entryTitle: String
    let entryID: String
    let timestamp: Date

    enum ActivityType {
        case created
        case modified
        case aiProcessed
        case tagAdded

        var icon: String {
            switch self {
            case .created: return "plus.circle.fill"
            case .modified: return "pencil.circle.fill"
            case .aiProcessed: return "sparkles"
            case .tagAdded: return "tag.fill"
            }
        }

        var color: String {
            switch self {
            case .created: return "green"
            case .modified: return "blue"
            case .aiProcessed: return "purple"
            case .tagAdded: return "orange"
            }
        }

        var actionText: String {
            switch self {
            case .created: return "Created"
            case .modified: return "Modified"
            case .aiProcessed: return "AI-processed"
            case .tagAdded: return "Tagged"
            }
        }
    }
}

struct Recommendation: Identifiable {
    let id: String
    let type: RecommendationType
    let title: String
    let description: String
    let actionTitle: String
    let icon: String
    let color: Color

    enum RecommendationType {
        case needsTags
        case aiProcessing
        case exploreRelations
        case addContent
    }
}

// MARK: - Extensions

import SwiftUI

extension Color {
    static let green = Color.green
    static let blue = Color.blue
    static let orange = Color.orange
    static let purple = Color.purple
}
