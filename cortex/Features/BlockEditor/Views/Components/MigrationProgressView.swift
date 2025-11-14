//
//  MigrationProgressView.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

/// View showing migration progress
struct MigrationProgressView: View {
    // MARK: - Properties

    @Bindable var migrationService: BlockMigrationService
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                    .symbolEffect(.pulse, isActive: migrationService.isMigrating)

                Text("Migriere zu Block-Editor")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Deine Einträge werden in das neue Block-Format konvertiert")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Progress
            VStack(spacing: 12) {
                ProgressView(value: migrationService.migrationProgress) {
                    HStack {
                        Text("Fortschritt")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(migrationService.migratedEntries)/\(migrationService.totalEntries)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .progressViewStyle(.linear)

                if migrationService.isMigrating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Aktuell: \(migrationService.currentEntryTitle)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)

            // Info
            if !migrationService.isMigrating && migrationService.migrationProgress >= 1.0 {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Migration abgeschlossen!")
                            .fontWeight(.medium)
                    }

                    Text("Alle Einträge wurden erfolgreich konvertiert.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)

                Button("Fertig") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            } else if !migrationService.isMigrating {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Deine Daten bleiben sicher", systemImage: "checkmark.shield")
                    Label("Originale bleiben erhalten", systemImage: "doc.on.doc")
                    Label("Migration kann jederzeit abgebrochen werden", systemImage: "arrow.uturn.backward")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .frame(width: 450)
        .padding(32)
    }
}

// MARK: - Preview

#Preview {
    MigrationProgressView(
        migrationService: BlockMigrationService(
            modelContext: ModelContext(
                try! ModelContainer(for: KnowledgeEntry.self, ContentBlock.self)
            )
        )
    )
}
