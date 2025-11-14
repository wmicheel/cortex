//
//  ContentView.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

/// Main content view with navigation
struct ContentView: View {
    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Tab = .dashboard
    @State private var showCommandPalette = false
    @State private var selectedEntry: KnowledgeEntry?
    @State private var migrationPerformed = false
    @State private var showAddEntry = false
    @State private var showAIProcessing = false

    // MARK: - Tab Enum

    enum Tab {
        case dashboard
        case knowledge
        case settings
    }

    // MARK: - Body

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.balanced)
        .overlay {
            if showCommandPalette {
                CommandPaletteView(
                    isPresented: $showCommandPalette,
                    onCommandSelected: handleCommandSelection
                )
            }
        }
        .background(
            Button("") {
                withAnimation(DesignSystem.Animations.spring) {
                    showCommandPalette.toggle()
                }
            }
            .keyboardShortcut("k", modifiers: .command)
            .hidden()
        )
        .task {
            await performMigrationIfNeeded()
        }
    }

    // MARK: - Command Palette Actions

    private func handleCommandSelection(_ command: Command) {
        switch command.type {
        case .action:
            handleAction(command.id)
        case .navigation:
            handleNavigation(command.id)
        case .entry(let entry):
            selectedEntry = entry
            selectedTab = .knowledge
        }
    }

    private func handleAction(_ actionId: String) {
        switch actionId {
        case "new-entry":
            showAddEntry = true
            selectedTab = .knowledge
        case "ai-process":
            showAIProcessing = true
            selectedTab = .knowledge
        case "search":
            selectedTab = .knowledge
        case "settings":
            selectedTab = .settings
        case "dashboard":
            selectedTab = .dashboard
        case "export":
            // TODO: Implement export functionality
            print("Export action triggered")
        default:
            break
        }
    }

    private func handleNavigation(_ navigationId: String) {
        switch navigationId {
        case "dashboard":
            selectedTab = .dashboard
        default:
            break
        }
    }

    // MARK: - Migration

    @MainActor
    private func performMigrationIfNeeded() async {
        guard !migrationPerformed else { return }
        migrationPerformed = true

        let migrationService = BlockMigrationService(modelContext: modelContext)

        // Check if migration is needed
        guard migrationService.needsMigration() else {
            print("✅ No migration needed")
            return
        }

        print("🔄 Starting automatic block-based migration...")

        do {
            try await migrationService.migrateAllEntries()
            print("✅ Migration completed successfully")
        } catch {
            print("❌ Migration failed: \(error)")
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selectedTab) {
            Section("Main") {
                Label("Dashboard", systemImage: "square.grid.2x2")
                    .tag(Tab.dashboard)

                Label("Knowledge", systemImage: "brain.head.profile")
                    .tag(Tab.knowledge)
            }

            Section("System") {
                Label("Settings", systemImage: "gearshape")
                    .tag(Tab.settings)
            }
        }
        .navigationTitle("Cortex")
        .listStyle(.sidebar)
    }

    // MARK: - Detail View

    @ViewBuilder
    private var detailView: some View {
        switch selectedTab {
        case .dashboard:
            ModernDashboardView(
                onNavigateToKnowledge: {
                    selectedTab = .knowledge
                },
                onNavigateToSettings: {
                    selectedTab = .settings
                }
            )
        case .knowledge:
            ModernKnowledgeListView()
                .sheet(isPresented: $showAddEntry) {
                    AddKnowledgeView(viewModel: KnowledgeListViewModel())
                }
                .sheet(isPresented: $showAIProcessing) {
                    AIProcessingSheet(
                        aiViewModel: AIProcessingViewModel(),
                        selectedEntries: [],
                        onComplete: {
                            showAIProcessing = false
                        }
                    )
                }
        case .settings:
            SettingsView()
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
