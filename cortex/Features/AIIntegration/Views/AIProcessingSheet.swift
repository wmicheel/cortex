//
//  AIProcessingSheet.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI

/// Sheet for AI processing configuration and execution
struct AIProcessingSheet: View {
    // MARK: - Properties

    @Bindable var aiViewModel: AIProcessingViewModel
    let selectedEntries: [KnowledgeEntry]
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView

                Divider()

                // Content
                if aiViewModel.isProcessing {
                    processingView
                } else if aiViewModel.processingResult != nil {
                    resultsView
                } else {
                    configurationView
                }
            }
            .navigationTitle("AI-Verarbeitung")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .disabled(aiViewModel.isProcessing)
                }

                ToolbarItem(placement: .confirmationAction) {
                    if aiViewModel.processingResult != nil {
                        Button("Fertig") {
                            onComplete()
                            dismiss()
                        }
                    } else {
                        Button("Starten") {
                            Task {
                                await startProcessing()
                            }
                        }
                        .disabled(!aiViewModel.canStartProcessing || aiViewModel.isProcessing)
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("AI-Verarbeitung")
                        .font(.headline)

                    Text("\(selectedEntries.count) \(selectedEntries.count == 1 ? "Eintrag" : "Einträge") ausgewählt")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Configuration View

    private var configurationView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Task selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Aufgaben auswählen")
                        .font(.headline)

                    VStack(spacing: 12) {
                        TaskToggle(
                            title: "Auto-Tagging",
                            description: "Automatisch relevante Tags generieren",
                            icon: "tag.fill",
                            isEnabled: $aiViewModel.isAutoTaggingEnabled
                        )

                        TaskToggle(
                            title: "Zusammenfassung",
                            description: "Prägnante Zusammenfassung erstellen",
                            icon: "doc.text.fill",
                            isEnabled: $aiViewModel.isSummarizationEnabled
                        )

                        TaskToggle(
                            title: "Verknüpfungen finden",
                            description: "Ähnliche Einträge identifizieren",
                            icon: "link",
                            isEnabled: $aiViewModel.isLinkFindingEnabled
                        )

                        TaskToggle(
                            title: "Content-Erweiterung",
                            description: "Inhalt mit Zusatzinformationen erweitern",
                            icon: "text.append",
                            isEnabled: $aiViewModel.isContentEnrichmentEnabled
                        )
                    }
                }

                Divider()

                // Quick actions
                HStack(spacing: 12) {
                    Button("Alle auswählen") {
                        aiViewModel.selectAllTasks()
                    }
                    .buttonStyle(.bordered)

                    Button("Zurücksetzen") {
                        aiViewModel.resetTasks()
                    }
                    .buttonStyle(.bordered)
                }

                // Info box
                if let errorMessage = aiViewModel.errorMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)

                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.accentColor)

                        Text("Die AI-Verarbeitung nutzt OpenAI (GPT-4o-mini) für schnelle Aufgaben und Claude für komplexe Analysen.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }

    // MARK: - Processing View

    private var processingView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Progress indicator
            VStack(spacing: 16) {
                ProgressView(value: aiViewModel.progress) {
                    HStack {
                        Text(aiViewModel.progressText)
                            .font(.headline)

                        Spacer()

                        Text("\(aiViewModel.progressPercentage)%")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    }
                }
                .progressViewStyle(.linear)

                Text("Bitte warten Sie, während die Einträge verarbeitet werden...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Results View

    private var resultsView: some View {
        VStack(spacing: 20) {
            if let result = aiViewModel.processingResult {
                // Success summary
                VStack(spacing: 16) {
                    Image(systemName: result.failedEntries == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(result.failedEntries == 0 ? .green : .orange)

                    Text("Verarbeitung abgeschlossen")
                        .font(.title2)
                        .fontWeight(.semibold)

                    VStack(spacing: 8) {
                        HStack {
                            Text("Verarbeitet:")
                            Spacer()
                            Text("\(result.totalEntries)")
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Text("Erfolgreich:")
                            Spacer()
                            Text("\(result.successfulEntries)")
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }

                        if result.failedEntries > 0 {
                            HStack {
                                Text("Fehlgeschlagen:")
                                Spacer()
                                Text("\(result.failedEntries)")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                            }
                        }

                        HStack {
                            Text("Dauer:")
                            Spacer()
                            Text(String(format: "%.1fs", result.duration))
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                }
                .padding()
            }
        }
    }

    // MARK: - Actions

    private func startProcessing() async {
        if selectedEntries.count == 1, let entry = selectedEntries.first {
            await aiViewModel.processSingleEntry(entry)
        } else {
            await aiViewModel.processBatchEntries(selectedEntries)
        }
    }
}

// MARK: - Task Toggle

struct TaskToggle: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isEnabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isEnabled ? .accentColor : .secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isEnabled ? Color.accentColor.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isEnabled ? Color.accentColor : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    AIProcessingSheet(
        aiViewModel: AIProcessingViewModel(),
        selectedEntries: [
            KnowledgeEntry(title: "Test Entry 1", content: "Content 1", tags: ["test"]),
            KnowledgeEntry(title: "Test Entry 2", content: "Content 2", tags: ["test"])
        ],
        onComplete: {}
    )
}
