//
//  CortexApp.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI
import AppKit

@main
struct CortexApp: App {
    // MARK: - CloudKit State

    @State private var cloudKitReady = false
    @State private var cloudKitError: CortexError?
    @State private var isCheckingCloudKit = true

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            Group {
                if isCheckingCloudKit {
                    // Loading state while checking CloudKit
                    CloudKitLoadingView()
                } else if let error = cloudKitError {
                    // Error state if CloudKit is not available
                    CloudKitErrorView(error: error, onRetry: retryCloudKitSetup)
                } else if cloudKitReady {
                    // Main app content
                    ContentView()
                } else {
                    // Fallback (should never happen)
                    CloudKitLoadingView()
                }
            }
            .task {
                // Check CloudKit on appear
                if isCheckingCloudKit && !cloudKitReady && cloudKitError == nil {
                    await checkCloudKit()
                }
            }
        }
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

    // MARK: - CloudKit Check

    @MainActor
    private func checkCloudKit() async {
        isCheckingCloudKit = true
        cloudKitError = nil

        do {
            // Run CloudKit bootstrap
            try await CloudKitBootstrapper.bootstrap()

            // Success!
            cloudKitReady = true
            isCheckingCloudKit = false
        } catch let error as CortexError {
            cloudKitError = error
            cloudKitReady = false
            isCheckingCloudKit = false
        } catch {
            cloudKitError = .unknown(underlying: error)
            cloudKitReady = false
            isCheckingCloudKit = false
        }
    }

    @MainActor
    private func retryCloudKitSetup() {
        Task {
            await checkCloudKit()
        }
    }
}

// MARK: - CloudKit Loading View

struct CloudKitLoadingView: View {
    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .controlSize(.large)

            VStack(spacing: 8) {
                Text("Verbinde mit iCloud...")
                    .font(.headline)

                Text("CloudKit wird initialisiert")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - CloudKit Error View

struct CloudKitErrorView: View {
    let error: CortexError
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            // Icon
            Image(systemName: errorIcon)
                .font(.system(size: 64))
                .foregroundStyle(errorColor)

            // Error Message
            VStack(spacing: 12) {
                Text("CloudKit nicht verfügbar")
                    .font(.title)
                    .fontWeight(.semibold)

                if let description = error.errorDescription {
                    Text(description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }

                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                }
            }

            // Actions
            HStack(spacing: 16) {
                Button(action: onRetry) {
                    Label("Erneut versuchen", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(action: openSystemSettings) {
                    Label("Systemeinstellungen", systemImage: "gear")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(action: quitApp) {
                    Text("Beenden")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            // Debug Info (in development)
            #if DEBUG
            VStack(alignment: .leading, spacing: 4) {
                Text("Debug Info:")
                    .font(.caption2)
                    .fontWeight(.semibold)
                Text("\(String(describing: error))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            #endif
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var errorIcon: String {
        switch error {
        case .cloudKitAccountNotFound:
            return "person.crop.circle.badge.exclamationmark"
        case .cloudKitNotAvailable:
            return "icloud.slash"
        default:
            return "exclamationmark.triangle"
        }
    }

    private var errorColor: Color {
        switch error {
        case .cloudKitAccountNotFound:
            return .orange
        case .cloudKitNotAvailable:
            return .red
        default:
            return .yellow
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane") {
            NSWorkspace.shared.open(url)
        }
    }

    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
