//
//  AIProcessingViewModel.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation
import Observation

/// ViewModel for AI processing UI
@MainActor
@Observable
final class AIProcessingViewModel {
    // MARK: - Properties

    private let knowledgeService: any KnowledgeServiceProtocol

    // UI State
    var isProcessing = false
    var progress: Double = 0.0
    var currentEntryIndex = 0
    var totalEntries = 0
    var selectedTasks: Set<AITask> = []
    var processingResult: AIBatchProcessingResult?
    var errorMessage: String?

    // Task selection state
    var isAutoTaggingEnabled = true
    var isSummarizationEnabled = true
    var isLinkFindingEnabled = true
    var isContentEnrichmentEnabled = false

    // MARK: - Computed Properties

    var progressPercentage: Int {
        Int(progress * 100)
    }

    var progressText: String {
        if isProcessing {
            return "\(currentEntryIndex) von \(totalEntries) Einträgen verarbeitet"
        } else if let result = processingResult {
            return "Verarbeitung abgeschlossen: \(result.successfulEntries) erfolgreich, \(result.failedEntries) fehlgeschlagen"
        } else {
            return "Bereit zur Verarbeitung"
        }
    }

    var canStartProcessing: Bool {
        !isProcessing && !enabledTasks.isEmpty
    }

    var enabledTasks: [AITask] {
        var tasks: [AITask] = []
        if isAutoTaggingEnabled { tasks.append(.autoTagging) }
        if isSummarizationEnabled { tasks.append(.summarization) }
        if isLinkFindingEnabled { tasks.append(.linkFinding) }
        if isContentEnrichmentEnabled { tasks.append(.contentEnrichment) }
        return tasks
    }

    // MARK: - Initialization

    init(knowledgeService: (any KnowledgeServiceProtocol)? = nil) {
        if let service = knowledgeService {
            self.knowledgeService = service
        } else {
            // Try SwiftData, fallback to Mock if it fails
            do {
                self.knowledgeService = try SwiftDataKnowledgeService()
                print("✅ AIProcessingViewModel using SwiftDataKnowledgeService")
            } catch {
                print("⚠️ SwiftData unavailable for AIProcessingViewModel, using MockKnowledgeService: \(error)")
                self.knowledgeService = MockKnowledgeService()
            }
        }
    }

    // MARK: - Processing

    /// Process a single entry with AI
    func processSingleEntry(_ entry: KnowledgeEntry) async {
        guard !isProcessing else { return }

        isProcessing = true
        errorMessage = nil
        currentEntryIndex = 0
        totalEntries = 1
        progress = 0.0

        do {
            let tasks = enabledTasks
            guard !tasks.isEmpty else {
                errorMessage = "Bitte mindestens eine AI-Aufgabe auswählen"
                isProcessing = false
                return
            }

            let _ = try await knowledgeService.processWithAI(entry, tasks: tasks)

            // Complete
            currentEntryIndex = 1
            progress = 1.0

        } catch {
            errorMessage = "Fehler bei der AI-Verarbeitung: \(error.localizedDescription)"
        }

        isProcessing = false
    }

    /// Process multiple entries with AI
    func processBatchEntries(_ entries: [KnowledgeEntry]) async {
        guard !isProcessing else { return }
        guard !entries.isEmpty else { return }

        isProcessing = true
        errorMessage = nil
        currentEntryIndex = 0
        totalEntries = entries.count
        progress = 0.0
        processingResult = nil

        do {
            let tasks = enabledTasks
            guard !tasks.isEmpty else {
                errorMessage = "Bitte mindestens eine AI-Aufgabe auswählen"
                isProcessing = false
                return
            }

            let result = try await knowledgeService.processBatchWithAI(
                entries,
                tasks: tasks,
                progressCallback: { [weak self] current, total in
                    Task { @MainActor in
                        self?.currentEntryIndex = current
                        self?.totalEntries = total
                        self?.progress = Double(current) / Double(total)
                    }
                }
            )

            processingResult = result

        } catch {
            errorMessage = "Fehler bei der Batch-Verarbeitung: \(error.localizedDescription)"
        }

        isProcessing = false
    }

    // MARK: - Task Management

    func toggleTask(_ task: AITask) {
        switch task {
        case .autoTagging:
            isAutoTaggingEnabled.toggle()
        case .summarization:
            isSummarizationEnabled.toggle()
        case .linkFinding:
            isLinkFindingEnabled.toggle()
        case .contentEnrichment:
            isContentEnrichmentEnabled.toggle()
        }
    }

    func resetTasks() {
        isAutoTaggingEnabled = true
        isSummarizationEnabled = true
        isLinkFindingEnabled = true
        isContentEnrichmentEnabled = false
    }

    func selectAllTasks() {
        isAutoTaggingEnabled = true
        isSummarizationEnabled = true
        isLinkFindingEnabled = true
        isContentEnrichmentEnabled = true
    }

    // MARK: - Reset

    func reset() {
        isProcessing = false
        progress = 0.0
        currentEntryIndex = 0
        totalEntries = 0
        processingResult = nil
        errorMessage = nil
    }
}
