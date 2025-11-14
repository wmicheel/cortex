//
//  ContentView.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI

/// Main content view with navigation
struct ContentView: View {
    // MARK: - Properties

    @State private var selectedTab: Tab = .dashboard
    @State private var showQuickSearch = false
    @State private var selectedEntry: KnowledgeEntry?

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
            if showQuickSearch {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showQuickSearch = false
                    }

                QuickSearchView(isPresented: $showQuickSearch) { entry in
                    selectedEntry = entry
                    selectedTab = .knowledge
                }
            }
        }
        .background(
            Button("") {
                showQuickSearch.toggle()
            }
            .keyboardShortcut("k", modifiers: .command)
            .hidden()
        )
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
            DashboardView(
                onNavigateToKnowledge: {
                    selectedTab = .knowledge
                },
                onNavigateToSettings: {
                    selectedTab = .settings
                }
            )
        case .knowledge:
            KnowledgeListView()
        case .settings:
            SettingsView()
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
