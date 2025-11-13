//
//  CortexApp.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI

@main
struct CortexApp: App {
    var body: some Scene {
        WindowGroup {
            KnowledgeListView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
    }
}
