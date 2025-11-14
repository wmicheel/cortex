//
//  CortexApp.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

@main
struct CortexApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    performMigrationIfNeeded()
                }
        }
        .modelContainer(for: [KnowledgeEntry.self, ContentBlock.self])
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Cortex") {
                    // Show about window
                }
            }

            CommandGroup(after: .newItem) {
                Button("New Knowledge Entry") {
                    // Handled via keyboard shortcut
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(after: .sidebar) {
                Button("Search") {
                    // Handled via keyboard shortcut
                }
                .keyboardShortcut("f", modifiers: .command)
            }
        }
    }

    // MARK: - Migration

    private func performMigrationIfNeeded() {
        // Migration will be triggered from ContentView where we have access to modelContext
    }
}
